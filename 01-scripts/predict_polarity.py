import sys
import numpy as np
import scipy.io as sio
import keras

# ----------------------------
# 0) Args
# ----------------------------
data_path  = sys.argv[1]   # input .mat file with Felix
model_path = sys.argv[2]   # .keras model file
out_path   = sys.argv[3]   # output .mat file

# ----------------------------
# 1) Load data
# ----------------------------
print("Loading data...")
mat = sio.loadmat(data_path, simplify_cells=True)
Felix = mat["Felix"]  # typically: list/np array of dict-like events

# Normalize Felix into a Python list of dicts (robust to different load shapes)
if isinstance(Felix, dict):
    Felix = [Felix]
elif isinstance(Felix, np.ndarray):
    Felix = list(Felix.ravel())

# ----------------------------
# 2) Load model
# ----------------------------
print(f"Loading model: {model_path}")
model = keras.models.load_model(model_path)
print("Model loaded.")

stations = ["AS1", "AS2", "CC1", "EC1", "EC2", "EC3", "ID1"]

def normalize(X: np.ndarray) -> np.ndarray:
    """X: (nSta, 64) — normalize each row by its max abs value"""
    norms = np.max(np.abs(X), axis=1, keepdims=True)
    norms = np.maximum(norms, 1.0)  # avoid divide by 0
    return X / norms

# ----------------------------
# 3) Loop events
# ----------------------------
nEvt = len(Felix)
print(f"Processing {nEvt} events...")

for i, ev in enumerate(Felix):

    # --- NEW: always create Po_* fields; default [0,0,0] means "no prediction" ---
    for sta in stations:
        ev[f"Po_{sta}"] = np.array([0.0, 0.0, 0.0], dtype=np.float32)

    waveforms = []
    used_sta  = []

    # Collect valid waveforms
    for sta in stations:
        wkey = f"W_{sta}"

        # missing -> keep Po_* as zeros
        if wkey not in ev:
            continue

        w = np.asarray(ev[wkey]).reshape(-1)

        # empty / wrong length / non-finite -> keep Po_* as zeros
        if w.size != 64:
            continue
        if not np.all(np.isfinite(w)):
            continue

        waveforms.append(w.astype(np.float32))
        used_sta.append(sta)

    # No usable stations for this event
    if len(waveforms) == 0:
        continue

    # ----------------------------
    # 4) Normalize + reshape + predict
    # ----------------------------
    X   = np.stack(waveforms, axis=0)          # (nSta, 64)
    Xn  = normalize(X).astype(np.float32)      # (nSta, 64)
    Xn3 = Xn[:, :, np.newaxis]                 # (nSta, 64, 1)  model input shape

    y_raw = model.predict(Xn3, verbose=0)

    # Model may return [reconstruction, polarity_probs]
    if isinstance(y_raw, (list, tuple)):
        y_prob = np.asarray(y_raw[1], dtype=np.float64)  # (nSta, 2)
    else:
        y_prob = np.asarray(y_raw, dtype=np.float64)     # (nSta, 2)

    # ----------------------------
    # 5) Polarity, confidence, entropy
    # ----------------------------
    idx  = np.argmax(y_prob, axis=1)                         # 0 or 1
    conf = np.max(y_prob, axis=1)                            # confidence
    pred = np.where(idx == 0, -1.0, 1.0)                     # 0->-1, 1->+1
    ent  = -np.sum(y_prob * np.log(y_prob + 1e-12), axis=1)  # entropy

    # ----------------------------
    # 6) Write back to Felix (overwrite defaults only where predicted)
    # ----------------------------
    for j, sta in enumerate(used_sta):
        ev[f"Po_{sta}"] = np.array([pred[j], conf[j], ent[j]], dtype=np.float32)

    if (i + 1) % 1000 == 0:
        print(f"  Processed {i+1} / {nEvt}")

# ----------------------------
# 7) Save
# ----------------------------
print(f"Saving to: {out_path}")
sio.savemat(out_path, {"Felix": np.array(Felix, dtype=object)}, do_compression=True)
print("Done.")
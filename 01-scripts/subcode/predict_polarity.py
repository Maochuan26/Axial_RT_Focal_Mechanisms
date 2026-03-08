"""
predict_polarity.py — ML polarity prediction for FM pipeline

Usage:
    python predict_polarity.py <E_NSP.mat> <model.keras> <F_DLpol.mat> [--cache <F_DLpol.mat>]

Incremental mode (--cache):
    Loads existing predictions from the cache file, identifies new event IDs,
    runs the model only on new events, and merges with cached results.
    On a typical daily run this avoids re-running inference on ~95% of events.
"""

import sys
import argparse
import numpy as np
import scipy.io as sio
import keras


def normalize(X: np.ndarray) -> np.ndarray:
    """X: (nSta, 64) — normalize each row by its max abs value."""
    norms = np.max(np.abs(X), axis=1, keepdims=True)
    norms = np.maximum(norms, 1.0)
    return X / norms


def predict_events(Felix_list, model, stations):
    """Run polarity prediction on a list of Felix event dicts. Modifies in-place."""
    n = len(Felix_list)
    for i, ev in enumerate(Felix_list):
        for sta in stations:
            ev[f"Po_{sta}"] = np.array([0.0, 0.0, 0.0], dtype=np.float32)

        waveforms = []
        used_sta  = []
        for sta in stations:
            wkey = f"W_{sta}"
            if wkey not in ev:
                continue
            w = np.asarray(ev[wkey]).reshape(-1)
            if w.size != 64 or not np.all(np.isfinite(w)):
                continue
            waveforms.append(w.astype(np.float32))
            used_sta.append(sta)

        if len(waveforms) == 0:
            continue

        X   = np.stack(waveforms, axis=0)
        Xn  = normalize(X).astype(np.float32)
        Xn3 = Xn[:, :, np.newaxis]
        y_raw = model.predict(Xn3, verbose=0)

        if isinstance(y_raw, (list, tuple)):
            y_prob = np.asarray(y_raw[1], dtype=np.float64)
        else:
            y_prob = np.asarray(y_raw, dtype=np.float64)

        idx  = np.argmax(y_prob, axis=1)
        conf = np.max(y_prob, axis=1)
        pred = np.where(idx == 0, -1.0, 1.0)
        ent  = -np.sum(y_prob * np.log(y_prob + 1e-12), axis=1)

        for j, sta in enumerate(used_sta):
            ev[f"Po_{sta}"] = np.array([pred[j], conf[j], ent[j]], dtype=np.float32)

        if (i + 1) % 100 == 0:
            print(f"  Predicted {i+1}/{n}", flush=True)


def get_id(ev):
    """Extract scalar event ID from a Felix dict (handles numpy scalar/array)."""
    v = ev.get('ID', None)
    if v is None:
        return None
    v = np.asarray(v).ravel()
    return int(v[0]) if v.size > 0 else None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('data_path',  help='Input E_NSP.mat')
    parser.add_argument('model_path', help='.keras model file')
    parser.add_argument('out_path',   help='Output F_DLpol.mat')
    parser.add_argument('--cache',    default=None,
                        help='Existing F_DLpol.mat to load cached predictions from')
    args = parser.parse_args()

    # ---- Load input data ----
    print("Loading data...", flush=True)
    mat = sio.loadmat(args.data_path, simplify_cells=True)
    Felix = mat["Felix"]
    if isinstance(Felix, dict):
        Felix = [Felix]
    elif isinstance(Felix, np.ndarray):
        Felix = list(Felix.ravel())
    print(f"Total events: {len(Felix)}", flush=True)

    # ---- Incremental: find which events already have predictions ----
    cached_by_id = {}
    if args.cache and __import__('os').path.isfile(args.cache):
        try:
            cache_mat = sio.loadmat(args.cache, simplify_cells=True)
            cache_Felix = cache_mat.get("Felix", [])
            if isinstance(cache_Felix, dict):
                cache_Felix = [cache_Felix]
            elif isinstance(cache_Felix, np.ndarray):
                cache_Felix = list(cache_Felix.ravel())
            for ev in cache_Felix:
                eid = get_id(ev)
                if eid is not None:
                    cached_by_id[eid] = ev
            print(f"Cache: {len(cached_by_id)} events already predicted.", flush=True)
        except Exception as e:
            print(f"Warning: could not load cache ({e}), running full prediction.", flush=True)

    # Split into cached vs new
    Felix_new  = []
    Felix_done = []
    for ev in Felix:
        eid = get_id(ev)
        if eid is not None and eid in cached_by_id:
            Felix_done.append(cached_by_id[eid])
        else:
            Felix_new.append(ev)

    print(f"Events to predict: {len(Felix_new)} new, {len(Felix_done)} from cache.", flush=True)

    # ---- Load model and predict only new events ----
    if Felix_new:
        print(f"Loading model: {args.model_path}", flush=True)
        model = keras.models.load_model(args.model_path)
        print("Model loaded. Running prediction...", flush=True)

        stations = ["AS1", "AS2", "CC1", "EC1", "EC2", "EC3", "ID1"]
        predict_events(Felix_new, model, stations)
        print(f"Predicted {len(Felix_new)} new events.", flush=True)
    else:
        print("No new events — skipping model inference.", flush=True)

    # ---- Merge: preserve original Felix ordering ----
    new_by_id = {get_id(ev): ev for ev in Felix_new}
    Felix_out = []
    for ev in Felix:
        eid = get_id(ev)
        if eid in new_by_id:
            Felix_out.append(new_by_id[eid])
        elif eid in cached_by_id:
            Felix_out.append(cached_by_id[eid])
        else:
            Felix_out.append(ev)  # fallback: no prediction

    # ---- Save ----
    print(f"Saving {len(Felix_out)} events to: {args.out_path}", flush=True)
    sio.savemat(args.out_path,
                {"Felix": np.array(Felix_out, dtype=object)},
                do_compression=True)
    print("Done.", flush=True)


if __name__ == '__main__':
    main()

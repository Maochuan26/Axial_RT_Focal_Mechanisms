# get_trace_CC1.py
#
# Fetch 3-component waveform for AXCC1 (HHZ, HHN, HHE) over a time window
# and save to py_trace.mat in a MATLAB-friendly format:
#   data:   (3, N) float64  [Z; N; E]
#   fs:     sampling rate (Hz)
#   t0:     ISO string of the returned trace start time
#   chan:   3x1 object array of channel names
#
# You MUST edit the "FETCH CONFIG" section (client/network/station/location)
# to match your data source (OOI/IRIS/etc.). Everything else is robust.

from __future__ import annotations

import numpy as np
from scipy.io import savemat

from obspy import UTCDateTime, Stream
from obspy.clients.fdsn import Client


# =========================
# FETCH CONFIG (EDIT THESE)
# =========================
FDSN_CLIENT = "IRIS"      # e.g., "IRIS", "USGS", or your FDSN endpoint
NETWORK     = "OO"        # <-- change if needed
STATION     = "AXCC1"
LOCATION    = ""          # often "" or "00" or "--" depending on archive
CHANNELS    = ["HHZ", "HHN", "HHE"]  # 3 components


def _to_utc(s: str) -> UTCDateTime:
    """Accept strings like '2026-02-22T00:00:00.000Z'."""
    # ObsPy can parse ISO strings; strip trailing 'Z' if present
    return UTCDateTime(s.replace("Z", ""))


def _merge_and_fill(st: Stream) -> Stream:
    """
    Merge, fill gaps, and make sure each Trace has a continuous .data vector.
    """
    st = st.copy()
    # Merge traces of same id; fill gaps with interpolation if possible
    # method=1 uses interpolation, fill_value='interpolate' is robust for small gaps.
    st.merge(method=1, fill_value="interpolate")
    return st


def _pick_trace_by_channel(st: Stream, chan: str):
    """Return the first Trace matching channel name, else None."""
    for tr in st:
        if tr.stats.channel == chan:
            return tr
    return None


def _common_fs_and_resample(traces):
    """
    Ensure all traces have the same sampling rate.
    Strategy:
      - pick the minimum sampling rate across available traces
      - decimate/resample others down to that rate (avoid upsampling noise)
    """
    fs_list = [float(tr.stats.sampling_rate) for tr in traces]
    fs0 = min(fs_list)

    out = []
    for tr in traces:
        tr2 = tr.copy()
        fs = float(tr2.stats.sampling_rate)
        if abs(fs - fs0) > 1e-6:
            # Use resample (FFT) to target fs0
            n_new = int(round(tr2.stats.npts * (fs0 / fs)))
            tr2.data = np.asarray(tr2.data, dtype=np.float64)
            tr2.resample(fs0)  # ObsPy handles npts update
        out.append(tr2)
    return fs0, out


def _align_and_stack(Z, N, E, mode="trim"):
    """
    Align start/end times and build a (3, N) array.

    mode:
      - "trim": take common time intersection (most robust)
      - "pad" : pad shorter traces with NaN to match the longest (less common)
    """
    # Get start/end times
    t0s = [tr.stats.starttime for tr in (Z, N, E)]
    t1s = [tr.stats.endtime   for tr in (Z, N, E)]

    if mode == "trim":
        t0 = max(t0s)  # latest start
        t1 = min(t1s)  # earliest end
        if t1 <= t0:
            raise ValueError(f"No common overlap among components: t0={t0}, t1={t1}")

        Zc = Z.copy().trim(t0, t1, pad=False)
        Nc = N.copy().trim(t0, t1, pad=False)
        Ec = E.copy().trim(t0, t1, pad=False)

        # After trim, lengths should match, but be defensive
        arrs = [np.asarray(tr.data, dtype=np.float64).ravel() for tr in (Zc, Nc, Ec)]
        nmin = min(a.size for a in arrs)
        arrs = [a[:nmin] for a in arrs]
        data = np.vstack(arrs)  # (3, N)
        return t0, data

    elif mode == "pad":
        t0 = min(t0s)
        t1 = max(t1s)
        Zc = Z.copy().trim(t0, t1, pad=True, fill_value=np.nan)
        Nc = N.copy().trim(t0, t1, pad=True, fill_value=np.nan)
        Ec = E.copy().trim(t0, t1, pad=True, fill_value=np.nan)
        arrs = [np.asarray(tr.data, dtype=np.float64).ravel() for tr in (Zc, Nc, Ec)]
        nmax = max(a.size for a in arrs)
        padded = []
        for a in arrs:
            if a.size < nmax:
                a2 = np.full((nmax,), np.nan, dtype=np.float64)
                a2[: a.size] = a
                padded.append(a2)
            else:
                padded.append(a[:nmax])
        data = np.vstack(padded)
        return t0, data

    else:
        raise ValueError("mode must be 'trim' or 'pad'")


def get_trace_CC1(t_start_str: str, t_final_str: str,
                 outfile: str = "py_trace.mat",
                 preprocess: bool = True,
                 bandpass: tuple[float, float] | None = None,
                 align_mode: str = "trim"):
    """
    Main entry called from MATLAB:
      gt.get_trace_CC1(t_start_str, t_final_str)

    Parameters
    ----------
    preprocess : bool
        If True: detrend, taper (and optional bandpass) each component.
    bandpass : (f1,f2) or None
        If provided, apply bandpass filter in Hz (e.g., (1.0, 20.0)).
    align_mode : "trim" or "pad"
        How to make equal-length components before saving.
    """
    t0 = _to_utc(t_start_str)
    t1 = _to_utc(t_final_str)

    client = Client(FDSN_CLIENT)

    # Fetch all channels in one request if possible
    ch_pat = ",".join(CHANNELS)

    print(f"Request: {NETWORK}.{STATION}.{LOCATION}.{ch_pat}  {t0} to {t1}")

    st = client.get_waveforms(
        network=NETWORK,
        station=STATION,
        location=LOCATION,
        channel=ch_pat,
        starttime=t0,
        endtime=t1,
        attach_response=False,
    )

    st = _merge_and_fill(st)

    # Pick Z/N/E
    trZ = _pick_trace_by_channel(st, "HHZ")
    trN = _pick_trace_by_channel(st, "HHN")
    trE = _pick_trace_by_channel(st, "HHE")

    if trZ is None or trN is None or trE is None:
        have = [tr.stats.channel for tr in st]
        raise ValueError(f"Missing components. Have channels: {have}")

    print(f"Found: {STATION} {trZ.stats.channel}, {trN.stats.channel}, {trE.stats.channel}")

    # Optional preprocessing
    if preprocess:
        for tr in (trZ, trN, trE):
            tr.detrend("linear")
            tr.detrend("demean")
            tr.taper(max_percentage=0.02, type="cosine")
        if bandpass is not None:
            f1, f2 = bandpass
            for tr in (trZ, trN, trE):
                tr.filter("bandpass", freqmin=float(f1), freqmax=float(f2),
                          corners=4, zerophase=True)

    # Enforce common fs (downsample to min fs) and align
    fs0, (trZ2, trN2, trE2) = _common_fs_and_resample([trZ, trN, trE])

    t_common0, data = _align_and_stack(trZ2, trN2, trE2, mode=align_mode)

    # Save MATLAB-friendly outputs
    chan = np.array([["HHZ"], ["HHN"], ["HHE"]], dtype=object)

    out = {
        "data": data,                 # (3, N) float64
        "fs": np.array([[fs0]]),      # 1x1
        "t0": np.array([[str(t_common0)]], dtype=object),
        "chan": chan,                 # 3x1 cell-like
    }

    savemat(outfile, out, do_compression=True)
    print(f"Saved {outfile}: data shape={data.shape}, fs={fs0}, t0={t_common0}")


if __name__ == "__main__":
    # Simple local test
    get_trace_CC1("2026-02-13T00:00:00.000Z", "2026-02-15T00:00:00.000Z")
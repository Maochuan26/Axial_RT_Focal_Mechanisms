"""
get_traces_batch.py — concurrent waveform downloader for FM pipeline

Usage:
    python get_traces_batch.py <felix_mat> <out_mat> [--workers N]

Reads a Felix .mat file, downloads all event waveforms concurrently via IRIS
FDSN bulk requests (one IRIS call per event, N events in parallel), and saves
all traces into a single output .mat as a cell array `traces` where
traces{i} has the same struct layout as the old per-event py_trace.mat.
"""

import sys
import argparse
import numpy as np
import scipy.io as sio
from concurrent.futures import ThreadPoolExecutor, as_completed
from obspy.clients.fdsn import Client
from obspy.core.utcdatetime import UTCDateTime

STA_LIST = [
    ('OO', 'AXCC1', '', 'HH?'),
    ('OO', 'AXEC1', '', 'EH?'),
    ('OO', 'AXEC2', '', 'HH?'),
    ('OO', 'AXEC3', '', 'EH?'),
    ('OO', 'AXAS1', '', 'EH?'),
    ('OO', 'AXAS2', '', 'EH?'),
    ('OO', 'AXID1', '', 'EH?'),
]

ST_OFFSET = -3   # seconds before origin
ED_OFFSET = +7   # seconds after origin

MATLAB_EPOCH_OFFSET = 719529.0  # datenum(1970,1,1)


def datenum_to_utc(dn):
    """Convert MATLAB datenum (days since Jan 0, year 0) to UTCDateTime."""
    unix_sec = (float(dn) - MATLAB_EPOCH_OFFSET) * 86400.0
    return UTCDateTime(unix_sec)


def fetch_one(task):
    """Download waveforms for one event. Returns (idx, trace_dict or None)."""
    idx, dn_on = task
    try:
        client = Client("IRIS")
        t_start = datenum_to_utc(dn_on) + ST_OFFSET
        t_final = datenum_to_utc(dn_on) + ED_OFFSET
        bulk = [(net, sta, loc, ch, t_start, t_final) for net, sta, loc, ch in STA_LIST]
        stream = client.get_waveforms_bulk(bulk, attach_response=True)
    except Exception as e:
        print(f'[{idx}] Download failed: {e}', flush=True)
        return idx, None

    stations = []; sampleRate = []; sampleCount = []; locations = []
    channels = []; stime = []; etime = []; data = []; networks = []
    sensitivityFreq = []; sensitivity = []

    for tr in stream:
        resp = tr.stats.response._get_overall_sensitivity_and_gain()
        stations.append(tr.stats.station)
        sampleRate.append(tr.stats.sampling_rate)
        sampleCount.append(tr.stats.npts)
        locations.append(tr.stats.location)
        channels.append(tr.stats.channel)
        stime.append(tr.stats.starttime.strftime("%Y-%m-%d:%H:%M:%S.%f"))
        etime.append(tr.stats.endtime.strftime("%Y-%m-%d:%H:%M:%S.%f"))
        data.append(tr.data.astype(np.float64))
        networks.append(tr.stats.network)
        sensitivityFreq.append(resp[0])
        sensitivity.append(resp[1])

    print(f'[{idx}] OK: {len(stations)} traces', flush=True)
    return idx, {
        'network': networks,
        'station': stations,
        'location': locations,
        'channel': channels,
        'sensitivity': sensitivity,
        'sensitivityFrequency': sensitivityFreq,
        'data': data,
        'sampleCount': sampleCount,
        'sampleRate': sampleRate,
        'startTime': stime,
        'endTime': etime,
    }


def main():
    parser = argparse.ArgumentParser(description='Batch concurrent IRIS waveform downloader')
    parser.add_argument('felix_mat', help='Input .mat file containing Felix struct array')
    parser.add_argument('out_mat',   help='Output .mat file for traces cell array')
    parser.add_argument('--workers', type=int, default=10,
                        help='Number of concurrent download threads (default: 10)')
    args = parser.parse_args()

    mat = sio.loadmat(args.felix_mat, simplify_cells=True)
    # Accept variable saved as 'Felix' or 'F'
    Felix = mat.get('Felix', mat.get('F', None))
    if Felix is None:
        print('ERROR: no Felix or F variable found in', args.felix_mat, flush=True)
        sys.exit(1)

    if isinstance(Felix, dict):
        Felix = [Felix]
    elif isinstance(Felix, np.ndarray):
        Felix = list(Felix.ravel())

    n = len(Felix)
    print(f'Downloading waveforms for {n} events with {args.workers} workers...', flush=True)

    tasks = [(i, float(ev['on'])) for i, ev in enumerate(Felix)]
    results = [None] * n

    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = {pool.submit(fetch_one, t): t[0] for t in tasks}
        done = 0
        for future in as_completed(futures):
            idx, trace = future.result()
            results[idx] = trace
            done += 1
            if done % 10 == 0 or done == n:
                print(f'  Progress: {done}/{n}', flush=True)

    # Save as object array so MATLAB loads it as a cell array
    traces_out = np.empty(n, dtype=object)
    for i, r in enumerate(results):
        traces_out[i] = r if r is not None else {}

    sio.savemat(args.out_mat, {'traces': traces_out}, do_compression=True)
    ok = sum(1 for r in results if r is not None)
    print(f'Done: {ok}/{n} events downloaded successfully. Saved to {args.out_mat}', flush=True)


if __name__ == '__main__':
    main()

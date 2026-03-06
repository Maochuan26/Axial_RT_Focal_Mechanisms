# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

Real-time focal mechanism matching for Axial Seamount (OOI cabled array) earthquakes. For each recent event, the pipeline finds the 6 most similar historical events with known focal mechanisms from a base catalog (`A_All.mat`), enabling FM inference by analogy.

## Running the Pipeline

Scripts are lettered A–G and must be run in order. Each produces a `.mat` file consumed by the next.

```bash
# Setup MATLAB paths first (run once per session):
# In MATLAB: run FM_buildpath6.m

# Individual stages (run in MATLAB R2023a):
matlab -batch "run('01-scripts/B_read_past1730days.m')"
matlab -batch "run('01-scripts/C_polish_ph2dt.m')"
matlab -batch "run('01-scripts/D_getwaveform.m')"
matlab -batch "run('01-scripts/E_SP_wave.m')"
matlab -batch "run('01-scripts/F_Po.m')"   # calls predict_polarity.py internally
matlab -batch "run('G_Cl.m')"

# Python polarity prediction (called by F_Po.m, but can be run directly):
/opt/miniconda3/envs/FM_RT/bin/python 01-scripts/predict_polarity.py \
    02-data/E_NSP.mat 02-data/PolarPicker_unified_TMSF_001.keras 02-data/F_DLpol.mat
```

**MATLAB version:** R2023a at `/Applications/MATLAB_R2023a.app`
**Python environment:** `/opt/miniconda3/envs/FM_RT/bin/python` (has ObsPy, Keras, scipy)

## Pipeline Data Flow

```
/Applications/MAMP/htdocs/ph2dtInputCatalog/ph2dtInputCatalog_YYYYMMDD.dat
    → B_read_past1730days.m  → 02-data/B_ph2dt_past30days_combined_until_YYYYMMDD.mat
    → C_polish_ph2dt.m       → 02-data/C_ph2dt.mat
    → D_getwaveform.m        → 02-data/D_wave.mat  (downloads via IRIS FDSN)
    → E_SP_wave.m            → 02-data/E_NSP.mat   (computes NSP ratios + W_ snippets)
    → F_Po.m + predict_polarity.py → 02-data/F_DLpol.mat  (ML polarity predictions)
    → G_Cl.m                 → 02-data/Match_Top6.mat
```

### Hardcoded paths / dates to update for each pipeline run

- **B_read_past1730days.m**: `tEnd` (line 10) is hardcoded — update to current date before running. Output filename encodes this date.
- **C_polish_ph2dt.m**: Input `load(...)` path (line 2) is hardcoded to match B's output filename — update to match.
- **E_SP_wave.m**: Loads `D_wave2.mat` (line 4), not `D_wave.mat` as shown above. Verify which file D produces before running.

### Per-stage event filters

- **D_getwaveform.m**: Drops events with `PSpair < 6` before downloading waveforms.
- **E_SP_wave.m**: Drops events with `mag < 1`.

### Inter-language handoff details

- **D_getwaveform.m** calls `get_traceFM.py` via MATLAB Python interop. The Python function writes `py_trace.mat` to the **current working directory** (not `02-data/`). Run from repo root.
- **F_Po.m** invokes `predict_polarity.py` via `system()`. The Python script saves `Felix` as a MATLAB object array; F_Po.m converts it with `[Felix{:}]` and resaves as a struct array in `F_DLpol.mat`.

### SP ratio encoding

In new query events (from E_NSP.mat), the SP feature used in G_Cl.m is `log(P_amp / noise_amp)` computed from `NSP_<STA> = [noise_amp, S_amp, P_amp]`. In the base catalog (A_All.mat), it is stored directly as `SP_<STA>`.

## Key Data Structures

### Felix struct (the central event struct, used throughout)

| Field | Description |
|-------|-------------|
| `ID` | Integer event ID |
| `on` | Origin time as MATLAB datenum |
| `lat`, `lon`, `depth`, `mag` | Hypocenter parameters |
| `DDt_<STA>` | P travel time (sec) for station STA |
| `DDSt_<STA>` | S travel time (sec) for station STA |
| `NSP_<STA>` | `[noise_amp, S_amp, P_amp]` — amplitude ratios |
| `W_<STA>` | 64-sample Z-component snippet at 100 Hz around P |
| `Po_<STA>` | `[pred, conf, entropy]` from ML model; pred = ±1 or 0 |

Stations: `AS1, AS2, CC1, EC1, EC2, EC3, ID1` (network OO, prefix AX in FDSN).

### Match_Top6.mat
- `Matches` struct array: one entry per new event with fields `QueryID`, `QueryIndex`, `MatchID` (1×6), `MatchIndex`, `Distance`, `LocDist`, `PoDist`, `SprDist`
- `Po_Clu`: struct array in the same format as `F_Cl_All_ML_polish.mat`. Each cluster `i` contains **7 events**: `Felixw(i)` (the new query event) followed by its top-6 matched base catalog events. `Cluster` field = integer cluster index, no NaN. Fields are the union of `Felixw` and `Po` fields; missing fields filled with `NaN`.

### A_All.mat
- Contains `Felix` struct array = base catalog with known focal mechanisms
- Quality-filtered in G_Cl.m: requires `PoALL > 5` and `SP_All > 5`
- **FM parameter field names must be verified** before writing export scripts (may be `strike`/`dip`/`rake` or moment tensor components)

## External Dependencies (MATLAB path)

Set up by `FM_buildpath6.m`. Requires sibling repos:
- `/Users/mczhang/Documents/GitHub/Axial-AutoLocate/` — core location/FM utilities
- `/Users/mczhang/Documents/GitHub/FM/` — FM subcode (e.g., `latlon2xy`)
- `/Users/mczhang/Documents/GitHub/AutomaticFM/`

## Website

Served by MAMP at `http://localhost:8888/` from `/Applications/MAMP/htdocs/`.
Static HTML site — no build step. Pages: `index.html`, `map1.html`, `map2.html`, `hypo71.html`, `ph2dt.html`.
Daily catalog files live under `ph2dtInputCatalog/` and `felix/` subdirectories.

## Matching Algorithm (G_Cl.m)

Composite distance: `D = 3·dLoc + 7·dSpr + 100·dPo` (all normalized 0–1).
- `dPo` = `custom_distance_Po`: fraction of polarity mismatches among non-zero pairs
- `dSpr` = `custom_distance_SPr`: normalized Euclidean on non-zero SP pairs
- Both functions live in `/Users/mczhang/Documents/GitHub/FM/01-scripts/subcode/`

Hard filters: polarity fraction = 0 (perfect match), SP misfit ≤ 0.2, loc misfit ≤ 0.2.
Falls back to top-K by D if no events pass filters.

# Axial Seamount Real-Time Focal Mechanisms

Near-real-time focal mechanism estimation for earthquakes at [Axial Seamount](https://en.wikipedia.org/wiki/Axial_Seamount) recorded by the [Ocean Observatories Initiative (OOI)](https://oceanobservatories.org/) cabled array.

**by [Maochuan Zhang](https://www.ocean.washington.edu/home/Maochuan_Zhang)**
5th-year PhD Student, School of Oceanography, University of Washington, Seattle

---

## How It Works

For each recent earthquake, the pipeline finds the **6 most similar historical events** from a base catalog with known focal mechanisms. Similarity is measured by a composite distance combining:
- Hypocenter location
- P-wave first-motion polarities (predicted by a deep learning model)
- S/P amplitude ratios across 7 OOI broadband stations

Focal mechanisms are then inferred via the [HASH algorithm](https://www.usgs.gov/software/hash-hazard-assessment-software-hashrock) using the matched events.

---

## Pipeline Mindmap

```mermaid
mindmap
  root((Axial RT FM))
    Input
      OOI Catalog
        ph2dtInputCatalog_YYYYMMDD.dat
      Base Catalog
        A_All.mat
    Pipeline
      B · Read Catalog
        past 30 days of events
      C · Build Felix
        travel times per station
      D · Get Waveforms
        IRIS FDSN download
      E · NSP Ratios
        S/P amplitude ratios
        64-sample P snippets
      F · ML Polarity
        predict_polarity.py
        PolarPicker deep learning
      G · Match Events
        composite distance
        top-6 analogs per event
      H · HASH FM
        focal mechanisms
      I · Plot & Save
        3 time windows
        03-graphics/
      J · Update Website
        Focal Mechanisms.html
    Output
      FocalMechanism1day.jpg
      FocalMechanism7day.jpg
      FocalMechanism30day.jpg
      focalmechanismsdaily archive
```

---

## Pipeline Flow

```mermaid
flowchart LR
    A[(A_All.mat\nbase catalog)] --> G
    CAT[ph2dtInputCatalog\n*.dat files] --> B

    B[B · Read Catalog] --> C[C · Build Felix]
    C --> D[D · Get Waveforms\nIRIS FDSN]
    D --> E[E · NSP Ratios\n& Snippets]
    E --> F[F · ML Polarity\nPolarPicker]
    F --> G[G · Match Top-6]
    G --> H[H · HASH FM]
    H --> I[I · Plot Figures]
    I --> J[J · Update Website]

    I --> G1[03-graphics/\nFocalMechanism*.jpg]
    J --> W[Focal Mechanisms.html\nhtdocs/]
```

---

## Requirements

### MATLAB
- **MATLAB R2023a** at `/Applications/MATLAB_R2023a.app`
- Sibling repositories on your MATLAB path (set by `FM_buildpath6.m`):
  - `Axial-AutoLocate/`
  - `FM/`
  - `AutomaticFM/`

### Python
- Environment: `/opt/miniconda3/envs/FM_RT/bin/python`
- Packages: ObsPy, Keras, scipy, numpy

### Data (not in this repo — too large)
| File | Size | Description |
|------|------|-------------|
| `02-data/A_All.mat` | ~600 MB | Base catalog with known focal mechanisms |

> Contact [Maochuan Zhang](https://www.ocean.washington.edu/home/Maochuan_Zhang) for access to `A_All.mat`.

---

## Setup

**1. Clone the repo**
```bash
git clone https://github.com/Maochuan26/Axial_RT_Focal_Mechanisms.git
cd Axial_RT_Focal_Mechanisms
```

**2. Add sibling repos to MATLAB path**

Run once per MATLAB session (or add to `startup.m`):
```matlab
run('FM_buildpath6.m')
```

**3. Place `A_All.mat`** in the `02-data/` folder.

---

## How to Run

### Full daily pipeline (recommended)
Open MATLAB R2023a, navigate to the repo root, then:
```matlab
run('Run_Pipeline_Daily.m')
```

This runs all stages **B → C → D → E → F → G → H → I → J** in sequence and saves output figures to `03-graphics/` and the MAMP website.

---

### Run individual stages

| Stage | Script | Description |
|-------|--------|-------------|
| B | `01-scripts/B_read_past1730days.m` | Read past 30 days of catalog |
| C | `01-scripts/C_polish_ph2dt.m` | Build Felix struct with travel times |
| D | `01-scripts/D_getwaveform.m` | Download waveforms via IRIS FDSN |
| E | `01-scripts/E_SP_wave.m` | Compute NSP ratios and P snippets |
| F | `01-scripts/F_Po.m` | ML polarity prediction |
| G | `01-scripts/G_Cl.m` | Match each event to top-6 analogs |
| H | `01-scripts/H_FM.m` | Compute focal mechanisms via HASH |
| I | `01-scripts/I_Plot_FM.m` | Plot beach ball maps and save figures |
| J | `01-scripts/J_UpdateFMWebsite.m` | Regenerate website archive page |

```matlab
% Example: run from stage G onward
run('FM_buildpath6.m')
run('01-scripts/G_Cl.m')
run('01-scripts/H_FM.m')
run('01-scripts/I_Plot_FM.m')   % also calls J automatically
```

### Python polarity prediction (called by F automatically)
```bash
/opt/miniconda3/envs/FM_RT/bin/python 01-scripts/predict_polarity.py \
    02-data/E_NSP.mat \
    02-data/PolarPicker_unified_TMSF_001.keras \
    02-data/F_DLpol.mat
```

---

## Output

| File | Description |
|------|-------------|
| `03-graphics/FocalMechanism1day.jpg` | Beach ball map — past 24 hours |
| `03-graphics/FocalMechanism7day.jpg` | Beach ball map — past 7 days |
| `03-graphics/FocalMechanism30day.jpg` | Beach ball map — past 30 days |
| `03-graphics/focalmechanismsdaily/FM*day_YYYYMMDD.jpg` | Dated archive per run |
| `02-data/H_FM.mat` | Focal mechanism solutions (`event1`, `event2`, `event3`) |
| `02-data/G_Cl.mat` | Match results (`Matches`, `Po_Clu`) |

Beach ball color coding: **blue** = Normal · **red** = Reverse · **green** = Strike-slip · **black** = Unclassified

---

## Stations

| FDSN ID | Short | Network |
|---------|-------|---------|
| AXAS1 | AS1 | OO |
| AXAS2 | AS2 | OO |
| AXCC1 | CC1 | OO |
| AXEC1 | EC1 | OO |
| AXEC2 | EC2 | OO |
| AXEC3 | EC3 | OO |
| AXID1 | ID1 | OO |

---

## Website

Results are served locally via MAMP at `http://localhost:8888/` from `/Applications/MAMP/htdocs/`.
The public site is at [axial.ocean.washington.edu](http://axial.ocean.washington.edu).

---

## Citation

If you use this pipeline, please cite:

> Wilcock, W. S. D., M. Tolstoy, F. Waldhauser, C. Garcia, Y. J. Tan, D. R. Bohnenstiehl, J. Caplan-Auerbach, R. P. Dziak, A. Arnulf, & M. E. Mann (2016). Seismic constraints on caldera dynamics from the 2015 Axial Seamount eruption, *Science*, 354, 1395–1399.

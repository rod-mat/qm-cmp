# API Contract

## General Information
- **Base URL**: `/api` (e.g. `http://localhost:8080/api`)
- **Format**: JSON
- **Units**:
  - Length: Angstrom (Å)
  - Reciprocal: 1/Å
  - Energy: eV
  - Wavevector k: 2π/λ

## Endpoints

### 1. Health Check
- **POST** `/api/health`
- **Response**: `{ "ok": true }`

### 2. Crystal Builder
- **POST** `/api/crystal/build`
- **Request**: `CrystalBuildRequest`
```json
{
  "lattice": {
    "kind": "sc|bcc|fcc|hex|custom",
    "a": 3.0,
    "b": 3.0, "c": 3.0, // optional
    "alpha": 90, "beta": 90, "gamma": 90 // optional
  },
  "basis": [
    { "element": "Fe", "frac": [0,0,0] }
  ],
  "supercell": [1,1,1],
  "planes": [
    { "h": 1, "k": 0, "l": 0 }
  ]
}
```
- **Response**: `CrystalBuildResponse`
```json
{
  "real": { "A": [[3,0,0],[0,3,0],[0,0,3]], "origin": [0,0,0] },
  "recip": { "B": [...], "gPoints": [[...]], "gHKL": [[1,0,0],...] },
  "atoms": { "positions": [[0,0,0]], "elements": ["Fe"] },
  "planes": [ { "hkl": [1,0,0], "mesh": { "vertices": [...], "faces": [...] } } ]
}
```

### 3. Ewald Diffraction
- **POST** `/api/diffraction/ewald`
- **Request**: `EwaldRequest`
```json
{
  "crystal": { "B": [...], "gPoints": [...], "gHKL": [...] },
  "beam": { "lambda": 1.54, "kInDir": [0,0,-1] },
  "detector": { "distance": 100, "normal": [0,0,1], "up": [0,1,0], "width": 80, "height": 80 },
  "intensity": { "model": "unit" }
}
```
- **Response**: `EwaldResponse`
```json
{
  "spots": [
     { "hkl": [1,1,0], "uv": [12.5, -5.2], "intensity": 0.8 }
  ]
}
```

### 4. Tight-Binding Bands
- **POST** `/api/tb/bands`
- **Request**: `TBRequest`
```json
{
  "model": { "lattice": "2d_honeycomb", "params": { "t": -2.7 } },
  "kpath": { "points": [{ "label":"G", "k":[0,0,0] }], "nPerSegment": 100 },
  "dos": { "enabled": true, "nE": 1000 }
}
```
- **Response**: `TBResponse`
```json
{
  "bands": [ [ -5.0, ... ], [ 5.0, ... ] ],
  "k": [ 0.0, 0.1, ... ],
  "labels": [ { "atIndex": 0, "label": "G" } ],
  "dos": { "E": [...], "g": [...] }
}
```

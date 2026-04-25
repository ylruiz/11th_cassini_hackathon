from __future__ import annotations

import os
from pathlib import Path
import zipfile

import cdsapi


def find_project_root(start: Path) -> Path:
    p = start.resolve()
    for candidate in [p] + list(p.parents):
        if (candidate / "data").exists() and (candidate / "src").exists():
            return candidate
    return p


def resolve_cdsapirc(root: Path) -> Path | None:
    candidates = [
        root / ".cdsapirc",
        Path.cwd() / ".cdsapirc",
        Path.home() / ".cdsapirc",
    ]
    for candidate in candidates:
        if candidate.exists():
            return candidate
    return None


def main() -> None:
    root = find_project_root(Path.cwd())
    data_dir = root / "data" / "cds"
    data_dir.mkdir(parents=True, exist_ok=True)

    rc_path = resolve_cdsapirc(root)
    if rc_path is None:
        raise RuntimeError("Missing .cdsapirc in project root/current dir/home")

    os.environ["CDSAPI_RC"] = str(rc_path)
    print(f"Using CDSAPI_RC={rc_path}")

    dataset = "sis-hydrology-variables-derived-seasonal-forecast"
    target = data_dir / "cds_hydrology_forecast_subset.zip"

    request = {
        "variable": ["river_discharge"],
        "hydrological_model": ["lisflood_efas"],
        "year": ["2024"],
        "month": ["01"],
        "version": ["1"],
    }

    print(f"Submitting request to {dataset}")
    print(f"Target file: {target}")

    client = cdsapi.Client()
    client.retrieve(dataset, request, str(target))

    if zipfile.is_zipfile(target):
        with zipfile.ZipFile(target) as zf:
            members = [name for name in zf.namelist() if name.endswith(".nc")]
            if not members:
                raise RuntimeError(f"Downloaded ZIP contains no NetCDF files: {target}")
            extracted = data_dir / Path(members[0]).name
            zf.extract(members[0], path=data_dir)
            nested = data_dir / members[0]
            if nested != extracted:
                nested.replace(extracted)
        print(f"Download succeeded (zip): {target}")
        print(f"Extracted NetCDF: {extracted}")
    else:
        print(f"Download succeeded (netcdf): {target}")


if __name__ == "__main__":
    main()

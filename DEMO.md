# AquaSentinel — Demo Guide

> Companion to `README.md`. The README pitches the **why**. This document
> walks through the **what** — what each tab in the app actually does
> *today*, what it will do once Copernicus data is fully piped through, and
> where the line currently sits between real evidence and curated/synthetic
> placeholders.

The demo is centered on the **Ötztal Alps preset**, the canonical AOI (area of interest) we  
have invested in. Everything below assumes that AOI is selected.

---

## TL;DR — 60-second pitch

- **One question, decades ahead.** AquaSentinel turns Copernicus Sentinel-1,
Sentinel-2, and CDS Lisflood-EFAS into a long-term flood / landslide
screening tool: *"Where will Tyrol be at risk in 10 / 20 / 50 years, and
who lives there?"*
- **An interactive AOI workflow, not a static report.** The user clicks
the **OETZTAL PRESET** (or draws their own bbox) and gets back a
five-tab analysis panel: detected problems, evidence-based drivers,
prevention actions, population exposure, and a forward simulation.
- **Honest about provenance.** Every metric carries its source — Sentinel,
EFAS, Statistik Austria — and the UI distinguishes observed history
(solid) from extrapolated projection (dashed).
- **A real what-if.** The SIMULATE tab lets the audience drag four driver
weights (snow, surface water, vegetation, hydrology) and watch the
10/20/50-year scenarios recompute server-side, on top of a 96-month
Sentinel-2 NDSI + EFAS history with a live least-squares trend extended
24 months forward.
- **Built to plug in real data.** The data layer is intentionally
swappable: a single `import_openeo_history.py` command replaces the
synthetic baseline with a real openEO Sentinel-2 export the moment our
colleague's notebook lands.

If a judge only watches **one tab**: open SIMULATE on Ötztal, drag the
*Snow / NDSI* slider, point at the dashed projection.

---

## Why Ötztal?

Ötztal is the AOI we tuned end-to-end:

- **It's a real Tyrolean catchment** with publicly-funded wild-water
prevention (€60M / yr at the Tyrol level), so the impact narrative is
concrete.
- **Sentinel-2 NDSI signal is strong** — high-altitude snow cover
declining ~−0.10 over the 2018–2025 window, matching the trend our
colleague extracted via the openEO pipeline.
- **EFAS Lisflood already shows a positive discharge anomaly** (+12% in
the cached seasonal forecast) for this catchment.
- **There are 11 villages** within or adjacent to the AOI buffer
(Sölden, Längenfeld, Umhausen, Imst, Haiming, Vent, …), so the
population-exposure card has something to bite into.

Use the **OETZTAL PRESET** button at the top of the map (or **INN VALLEY**
for a downstream comparison).

---

## How to run the demo locally

```bash
# one-time
just setup

# in two terminals
just api-dev          # FastAPI on :8000
just app-run-web      # Flutter Web on :3000 (or :8080 depending on env)
```

In the app:

1. Click **OETZTAL PRESET** in the top toolbar. The AOI polygon highlights
  the catchment.
2. The right-hand panel opens with five tabs: **PROBLEMS · CAUSES ·
  PREVENTION · IMPACT · SIMULATE**.
3. Walk through them in order — each tab below is a section in this guide.

---

## Tab-by-tab walkthrough

Each tab section has two columns:

- **Today** — what the component renders right now with the current
data plumbing (real Copernicus where wired, curated cache + synthetic
baseline elsewhere).
- **Tomorrow** — its purpose once the Copernicus / openEO / cadastral
pipes are fully connected. This is the gap we are explicit about.

### 1. PROBLEMS — "Is there a signal here?"


|                         | Today                                                                                                                                                                                        | Tomorrow                                                                                                                       |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| **Trust summary**       | Counts of evidence-backed vs unverified drivers, plus a "data sources" list. Generated server-side from the actual evidence list returned by the risk service.                               | Same logic, with each evidence row carrying a per-source confidence interval (cloud cover, revisit gap, EFAS ensemble spread). |
| **Current signal card** | Headline severity + a one-liner ("AOI shows Sentinel-2 snow proxy at X%, NDWI at Y%, EFAS anomaly at Z%"). Built from live Copernicus when credentials are present, mock fallback otherwise. | Same card but on a streaming Sentinel-1/2 feed with a "last refresh" stamp and an explicit nowcast vs evidence delta.          |


Demo line: *"PROBLEMS is the executive summary — is there a signal in this
catchment, and how trustworthy is it?"*

### 2. CAUSES — "What is driving the signal?"


|                       | Today                                                                                                                                                         | Tomorrow                                                                                                                                                |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Risk drivers list** | Up to four drivers (snow / surface water / vegetation / hydrology) each linked to the Sentinel-2 NDSI, NDWI, NDVI, or EFAS metric that produced its severity. | Add per-driver attribution: contribution to the 50-year scenario, sensitivity to weight, and a compact mini-chart of its month-over-month trend.        |
| **Evidence metrics**  | Numeric snow / water / vegetation fractions over the AOI bbox, plus EFAS discharge anomaly %. Each row carries its source label.                              | Replace the cached EFAS snippet with live ensemble medians / quantiles, and stream Sentinel-2 indices straight from openEO instead of cached fractions. |


Demo line: *"CAUSES is where we earn trust — every claim is annotated
with the satellite product it came from."*

### 3. PREVENTION — "What can be done?"


|                       | Today                                                                                                                                                                      | Tomorrow                                                                                                                                           |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Risk actions list** | A handful of recommended actions (e.g. "expand wetland buffers", "instrument upper-catchment snow stations") with feasibility / time horizon / cost-of-inaction estimates. | Tie each action to **specific exposed villages** (we now have those — see IMPACT) and to a **prevention ROI** computed from EU recovery cost data. |


Demo line: *"PREVENTION is deliberately the thinnest tab today — it's the
output we want a hydrology consultant to fill in once the screening
narrows the candidate sites."*

### 4. IMPACT — "Who and what is exposed?"


|                              | Today                                                                                                                                                                                                                                  | Tomorrow                                                                                                                                                          |
| ---------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Population exposure card** | Real number for the Ötztal preset: 11 settlements within an AOI buffer, ~25k residents (Sölden, Längenfeld, Umhausen, Imst, Haiming, Vent, …). Counted server-side from `alpine_settlements.json` — a curated Statistik Austria cache. | Replace the static JSON with the **GHSL population grid** + live cadastral lookup; per-village exposure becomes per-100m-pixel exposure with building footprints. |
| **Layer-status notice**      | Honest banner: "this tab shows which datasets are still needed to translate hazard screening into impact loss."                                                                                                                        | Add **monetary loss curves** (per village, per scenario) and an "infrastructure at risk" overlay (rail, bridges, hydropower from OSM).                            |


Demo line: *"IMPACT is where we draw the boundary between hazard and
loss. The population number is real (Statistik Austria); the loss curves
are not yet — and we say so."*

### 5. SIMULATE — "Where is this going, and how sensitive is it?"

This is the showpiece tab. Four blocks, top to bottom:

#### 5a. Driver weights knobs


| Today                                                                                                                                                                                                                                  | Tomorrow                                                                                                                                                                |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Four sliders (Snow / Surface water / Vegetation / Hydrology) in 0.0–2.0 range. Dragging any slider re-fetches the timeline server-side with the new weights and rerenders the 10/20/50-year cards. 250ms debounce + RESET to defaults. | Same UX, but with a **second sensitivity readout** showing the *marginal* effect of each weight on the 50-year scenario, computed via finite differences on the server. |


Demo line: *"Push the snow slider to 0 — the 50-year scenario degrades
because we removed snowmelt as evidence. Push it to 2 — it amplifies."*

#### 5b. 96-month history + 24-month projection


| Today                                                                                                                                                                                                                                                                                                                                                                                            | Tomorrow                                                                                                                                                                                                                                                                                                                                       |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Dual-axis line chart over an 8-year window (Jan 2018 – Dec 2025): NDSI snow fraction (left axis) + EFAS discharge anomaly (right axis). A `now` divider separates observed from projected. The dashed lines are a **least-squares regression** fitted on the observed series and extrapolated 24 months forward; the chart caption shows the per-year slope ("NDSI −0.03/yr · EFAS +1.4 pp/yr"). | Replace the synthetic 96-month series with a real **openEO** Sentinel-2 monthly export (NDSI / NDVI / NDWI / SnowFrac / WaterFrac) plus the actual EFAS series. The format is documented in `python_analysis/openeo_history_format.md` and the swap is one command: `python services/api/scripts/import_openeo_history.py openeo_history.csv`. |


Demo line: *"The trend you see is computed from 96 months of monthly
medians. The projection is a real regression — not a vibe — and tomorrow
that regression runs on the actual openEO export from our colleague's
notebook."*

#### 5c. Hydrology context


| Today                                                                                                                                                                                                                                                                                 | Tomorrow                                                                                                                                                   |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Cached snapshot of the **CDS Lisflood-EFAS seasonal forecast** for the catchment: discharge anomaly %, return-period signal, source line. Comes from `services/api/app/data/hydrology_evidence.json`, generated by `python_analysis/src/notebooks/alps_cds_hydrology_forecast.ipynb`. | Move from the cached snapshot to a live CDS API call per request, with per-issue-date refresh and ensemble percentiles instead of a single anomaly number. |


#### 5d. 10 / 20 / 50-year scenario timeline + caveats card


| Today                                                                                                                                                                                                                                                                            | Tomorrow                                                                                                                                                |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Three projection cards (10y / 20y / 50y) computed from the weighted evidence + a baseline climate trend. Severity, narrative, and indicative cost are tied back to the drivers. A separate caveats card spells out the assumptions ("not a hydrodynamic model; screening only"). | Replace the indicative trend with a **calibrated climate-projection model** (CORDEX / Copernicus C3S) and uncertainty bands instead of point estimates. |


Demo line: *"This is screening, not modelling. We make that explicit in
the caveats card so authorities can use it to **prioritise** a proper
hydrodynamic study, not replace one."*

---

## Real vs synthetic — current state of truth


| Component                                        | Source today                                          | Real / cached / synthetic                                                                                                                  |
| ------------------------------------------------ | ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| AOI selection (preset + freehand)                | User input → `AoiBounds` Pydantic model               | **Real**                                                                                                                                   |
| Sentinel-2 NDSI / NDWI / NDVI fractions over AOI | `copernicus_flood_data.fetch_optical_indices()`       | **Real** if Copernicus credentials set; deterministic mock fallback otherwise                                                              |
| Sentinel-1 SAR water mask                        | `copernicus_flood_data.fetch_sar_water_fraction()`    | **Real** with credentials; mock fallback otherwise                                                                                         |
| EFAS discharge anomaly + return-period signal    | `services/api/app/data/hydrology_evidence.json`       | **Cached real** (output of the EFAS notebook, frozen)                                                                                      |
| Settlement list + population (Ötztal & Inn)      | `services/api/app/data/alpine_settlements.json`       | **Real numbers, static cache** (Statistik Austria, 22 settlements)                                                                         |
| 96-month NDSI / EFAS history (chart)             | `services/api/app/data/aoi_history.json`              | **Synthetic baseline**, calibrated to match the openEO Sentinel-2 trend figure. Replaceable in one command (see § Roadmap).                |
| 24-month forward projection                      | Least-squares fit computed in Dart at render time     | **Real method, data-dependent** — runs on whatever the history endpoint serves, so it becomes real the moment the history JSON is replaced |
| 10 / 20 / 50-year scenario cards                 | `long_term_risk` service combining evidence + weights | **Method is real** (weighted aggregation of evidence channels), **climate trend constants are placeholders** until CORDEX is wired in      |
| Driver weights (slider knobs)                    | `RiskWeights` Pydantic model, applied server-side     | **Real** — every drag re-runs the timeline build with the new weights                                                                      |
| Long-term cost / monetary loss curves            | None                                                  | **Not implemented** — explicitly flagged in the IMPACT layer-status card                                                                   |


**Rule of thumb for the demo:** anything that is a *number on the screen*
is real or cached real, anything that is a *forward extrapolation* is a
real method running on top of a clearly-labelled (synthetic or cached)
input, and anything that is a *monetary loss* does not exist yet — and
the UI says so.

---

## Roadmap — what flips from synthetic to real next

Ordered by ROI, not chronology. None of these change the UI shape — they
swap the data feeding it.

1. **Real openEO Sentinel-2 history**
  Replace `aoi_history.json` with our colleague's openEO export. Format
   spec in `python_analysis/openeo_history_format.md`; importer in
   `services/api/scripts/import_openeo_history.py`.
   *Effort: minutes.*
2. **Live EFAS instead of the cached snapshot**
  Move from `hydrology_evidence.json` to a live CDS API call inside
   `_compute_hydrology_evidence`. Already scaffolded in the EFAS
   notebook.
   *Effort: ~half a day, mostly auth + retry hardening.*
3. **GHSL population grid for IMPACT**
  Swap the curated 22-settlement cache for the official 100m population
   grid. The exposure card UI does not change.
   *Effort: ~a day, gridded raster lookup.*
4. **NDWI water-mask raster overlay on the map**
  Add the openEO NDWI > 0.1 raster as a `TileLayer.overlay` toggle on
   `map_screen.dart`. Good for the visual story.
   *Effort: ~half a day once the raster is exported.*
5. **CORDEX / C3S climate trend behind the 10/20/50y cards**
  Replace the constant trend factor with a calibrated regional climate
   projection. This is the largest unlock — gets us out of "screening"
   and into "calibrated forecast".
   *Effort: multi-day, requires picking the right ensemble.*

When the three top items land, every number on every tab is either real
or cached-real. That is the milestone for "AquaSentinel beyond the
hackathon".
import logging

from fastapi import APIRouter, HTTPException, Query
from app.models.environmental_analysis import (
    AoiHistory,
    AoiRiskTimelineRequest,
    AreaAnalysis,
    RiskTimeline,
    RiskWeights,
)
from app.services.copernicus_flood_data import copernicus_flood_service
from app.services.long_term_risk import long_term_risk_service
from app.services.mock_satellite_data import mock_satellite_service


def _build_weights(
    snow: float | None,
    surface_water: float | None,
    vegetation: float | None,
    hydrology: float | None,
) -> RiskWeights | None:
    if all(value is None for value in (snow, surface_water, vegetation, hydrology)):
        return None
    return RiskWeights(
        snow=snow if snow is not None else 1.0,
        surface_water=surface_water if surface_water is not None else 1.0,
        vegetation=vegetation if vegetation is not None else 1.0,
        hydrology=hydrology if hydrology is not None else 1.0,
    )

router = APIRouter()
logger = logging.getLogger(__name__)

_WATER_BODY_IDS = {
    "inn-river",
    "lake-ohrid",
    "maritsa-river",
    "glomma-river",
    "tisza-river",
    "vistula-river",
    "po-river",
    "maas-river",
    "danube-delta",
    "guadalquivir-river",
}


@router.get("/analysis", response_model=AreaAnalysis)
async def get_analysis_by_location(
    lat: float = Query(..., description="Latitude of the center point"),
    lng: float = Query(..., description="Longitude of the center point"),
    radius_km: float = Query(50.0, ge=1.0, le=500.0, description="Search radius in kilometers"),
) -> AreaAnalysis:
    return mock_satellite_service.get_analysis_by_location(lat, lng, radius_km)


@router.get("/analysis/water-body/{water_body_id}", response_model=AreaAnalysis)
async def get_analysis_by_water_body(water_body_id: str) -> AreaAnalysis:
    if water_body_id not in _WATER_BODY_IDS:
        raise HTTPException(
            status_code=404,
            detail=f"Water body '{water_body_id}' not found. Available IDs: {', '.join(_WATER_BODY_IDS)}",
        )

    if water_body_id == "inn-river":
        try:
            return await copernicus_flood_service.get_inn_river_analysis()
        except Exception as exc:
            # Preserve the demo flow if credentials are missing or Copernicus is unavailable.
            logger.warning(
                "Falling back to mock Inn River analysis after %s: %r",
                type(exc).__name__,
                exc,
            )

    result = mock_satellite_service.get_analysis_by_water_body(water_body_id)
    if result is None:
        raise HTTPException(status_code=404, detail="Analysis not available for this water body")

    return result


@router.get("/analysis/water-bodies", response_model=list[str])
async def get_available_water_bodies() -> list[str]:
    return sorted(list(_WATER_BODY_IDS))


@router.get("/risk-timeline/{water_body_id}", response_model=RiskTimeline)
async def get_risk_timeline(
    water_body_id: str,
    weight_snow: float | None = Query(
        None,
        ge=0.0,
        le=2.0,
        description="Weight applied to the snow / NDSI evidence channel (default 1.0).",
    ),
    weight_surface_water: float | None = Query(
        None,
        ge=0.0,
        le=2.0,
        description="Weight applied to the SAR + NDWI surface-water channel.",
    ),
    weight_vegetation: float | None = Query(
        None,
        ge=0.0,
        le=2.0,
        description="Weight applied to the vegetation-buffering channel.",
    ),
    weight_hydrology: float | None = Query(
        None,
        ge=0.0,
        le=2.0,
        description="Weight applied to the cached EFAS / Lisflood discharge channel.",
    ),
) -> RiskTimeline:
    if water_body_id not in _WATER_BODY_IDS:
        raise HTTPException(
            status_code=404,
            detail=f"Water body '{water_body_id}' not found. Available IDs: {', '.join(_WATER_BODY_IDS)}",
        )

    weights = _build_weights(
        weight_snow,
        weight_surface_water,
        weight_vegetation,
        weight_hydrology,
    )
    timeline = await long_term_risk_service.get_risk_timeline(
        water_body_id,
        weights=weights,
    )
    if timeline is None:
        raise HTTPException(
            status_code=404,
            detail="Risk timeline is only available for Inn River in this MVP",
        )

    return timeline


@router.post("/risk-timeline/aoi", response_model=RiskTimeline)
async def get_aoi_risk_timeline(request: AoiRiskTimelineRequest) -> RiskTimeline:
    try:
        return await long_term_risk_service.get_aoi_risk_timeline(
            label=request.label,
            bbox=request.bbox,
            weights=request.weights,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.get("/risk-timeline/aoi/history", response_model=AoiHistory)
async def get_aoi_history(
    label: str = Query(
        ...,
        description=(
            "AOI label to look up. Matches the timeline `water_body_name` (e.g. "
            "'Inn Valley AOI', 'Inn River', 'Oetztal Alps AOI')."
        ),
    ),
) -> AoiHistory:
    history = long_term_risk_service.get_aoi_history(label)
    if history is None:
        raise HTTPException(
            status_code=404,
            detail=(
                f"No baked history available for '{label}'. Try 'Inn Valley AOI' or 'Oetztal Alps AOI'."
            ),
        )
    return history
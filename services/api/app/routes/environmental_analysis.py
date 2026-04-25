from fastapi import APIRouter, Query, HTTPException
from app.models.environmental_analysis import AreaAnalysis
from app.services.mock_satellite_data import mock_satellite_service

router = APIRouter()

_WATER_BODY_IDS = {
    "lake-balaton",
    "danube-delta",
    "lake-ohrid",
    "ebro-reservoir",
    "maas-river",
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

    result = mock_satellite_service.get_analysis_by_water_body(water_body_id)
    if result is None:
        raise HTTPException(status_code=404, detail="Analysis not available for this water body")

    return result


@router.get("/analysis/water-bodies", response_model=list[str])
async def get_available_water_bodies() -> list[str]:
    return sorted(list(_WATER_BODY_IDS))
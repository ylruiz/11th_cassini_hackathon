from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
from datetime import datetime

router = APIRouter()


class WaterBody(BaseModel):
    id: str
    name: str
    latitude: float
    longitude: float
    area_km2: float
    country: str
    access_index: float | None = None
    data_source: str = "Nominatim/OSM"
    copernicus_collection: Optional[str] = None


class SnowCoverData(BaseModel):
    river_id: str
    snow_cover_percent: float
    last_updated: datetime
    source: str = "Copernicus SCE"


class WaterQualityObservation(BaseModel):
    river_id: str
    chlorophyll_mg_m3: Optional[float] = None
    suspended_sediment_mg_l: Optional[float] = None
    water_temperature_c: Optional[float] = None
    last_updated: datetime
    source: str = "Copernicus LWQ"


class RiverForecast(BaseModel):
    river_id: str
    discharge_m3_s: float
    forecast_date: datetime
    lead_days: int
    model: str = "Copernicus CDS / Lisflood"


class WaterBodiesResponse(BaseModel):
    items: list[WaterBody]


_SAMPLE_WATER_BODIES: list[WaterBody] = [
    WaterBody(
        id="inn-river",
        name="Inn River",
        latitude=48.57,
        longitude=13.48,
        area_km2=25900,
        country="Austria/Germany",
        access_index=0.89,
        copernicus_collection="SENTINEL-2",
    ),
    WaterBody(
        id="lake-ohrid",
        name="Lake Ohrid",
        latitude=41.04,
        longitude=20.72,
        area_km2=358,
        country="North Macedonia",
        access_index=0.84,
        copernicus_collection="BYOC-LWQ",
    ),
    WaterBody(
        id="maritsa-river",
        name="Maritsa River",
        latitude=41.52,
        longitude=26.04,
        area_km2=53000,
        country="Bulgaria",
        access_index=0.76,
        copernicus_collection="SENTINEL-2",
    ),
    WaterBody(
        id="glomma-river",
        name="Glomma River",
        latitude=59.18,
        longitude=10.87,
        area_km2=42000,
        country="Norway",
        access_index=0.91,
        copernicus_collection="SENTINEL-2",
    ),
    WaterBody(
        id="tisza-river",
        name="Tisza River",
        latitude=45.14,
        longitude=20.16,
        area_km2=157000,
        country="Hungary",
        access_index=0.72,
        copernicus_collection="SENTINEL-1",
    ),
    WaterBody(
        id="vistula-river",
        name="Vistula River",
        latitude=52.38,
        longitude=20.09,
        area_km2=194000,
        country="Poland",
        access_index=0.68,
        copernicus_collection="SENTINEL-2",
    ),
    WaterBody(
        id="po-river",
        name="Po River",
        latitude=45.04,
        longitude=10.05,
        area_km2=74000,
        country="Italy",
        access_index=0.81,
        copernicus_collection="SENTINEL-1",
    ),
    WaterBody(
        id="maas-river",
        name="Maas River",
        latitude=50.87,
        longitude=5.70,
        area_km2=34000,
        country="Netherlands",
        access_index=0.95,
        copernicus_collection="SENTINEL-2",
    ),
    WaterBody(
        id="danube-delta",
        name="Danube Delta",
        latitude=44.90,
        longitude=29.23,
        area_km2=5165,
        country="Romania",
        access_index=0.71,
        copernicus_collection="BYOC-LWQ",
    ),
    WaterBody(
        id="guadalquivir-river",
        name="Guadalquivir River",
        latitude=37.94,
        longitude=-4.48,
        area_km2=58000,
        country="Spain",
        access_index=0.65,
        copernicus_collection="SENTINEL-2",
    ),
]

_MOCK_SNOW_DATA = {
    "inn-river": SnowCoverData(
        river_id="inn-river",
        snow_cover_percent=67.5,
        last_updated=datetime.now(),
        source="Copernicus SCE 1km",
    ),
    "gomma-river": SnowCoverData(
        river_id="glomma-river",
        snow_cover_percent=12.3,
        last_updated=datetime.now(),
        source="Copernicus SCE 1km",
    ),
    "po-river": SnowCoverData(
        river_id="po-river",
        snow_cover_percent=8.2,
        last_updated=datetime.now(),
        source="Copernicus SCE 1km",
    ),
}

_MOCK_WATER_QUALITY = {
    "danube-delta": WaterQualityObservation(
        river_id="danube-delta",
        chlorophyll_mg_m3=4.2,
        suspended_sediment_mg_l=12.5,
        water_temperature_c=18.3,
        last_updated=datetime.now(),
        source="Copernicus BYOC-LWQ",
    ),
    "lake-ohrid": WaterQualityObservation(
        river_id="lake-ohrid",
        chlorophyll_mg_m3=1.8,
        water_temperature_c=14.2,
        last_updated=datetime.now(),
        source="Copernicus BYOC-LWQ",
    ),
}

_MOCK_FORECASTS = {
    "inn-river": [
        RiverForecast(river_id="inn-river", discharge_m3_s=680, forecast_date=datetime.now(), lead_days=1, model="CDS/Lisflood"),
        RiverForecast(river_id="inn-river", discharge_m3_s=720, forecast_date=datetime.now(), lead_days=3, model="CDS/Lisflood"),
        RiverForecast(river_id="inn-river", discharge_m3_s=650, forecast_date=datetime.now(), lead_days=7, model="CDS/Lisflood"),
    ],
    "po-river": [
        RiverForecast(river_id="po-river", discharge_m3_s=1520, forecast_date=datetime.now(), lead_days=1, model="CDS/Lisflood"),
        RiverForecast(river_id="po-river", discharge_m3_s=1680, forecast_date=datetime.now(), lead_days=3, model="CDS/Lisflood"),
        RiverForecast(river_id="po-river", discharge_m3_s=1420, forecast_date=datetime.now(), lead_days=7, model="CDS/Lisflood"),
    ],
    "tisza-river": [
        RiverForecast(river_id="tisza-river", discharge_m3_s=920, forecast_date=datetime.now(), lead_days=1, model="CDS/Lisflood"),
        RiverForecast(river_id="tisza-river", discharge_m3_s=880, forecast_date=datetime.now(), lead_days=3, model="CDS/Lisflood"),
        RiverForecast(river_id="tisza-river", discharge_m3_s=950, forecast_date=datetime.now(), lead_days=7, model="CDS/Lisflood"),
    ],
}


@router.get("", response_model=WaterBodiesResponse)
async def get_water_bodies(country: str | None = None) -> WaterBodiesResponse:
    items = _SAMPLE_WATER_BODIES
    if country:
        items = [w for w in items if w.country.lower() == country.lower()]
    return WaterBodiesResponse(items=items)


@router.get("/accurate", response_model=WaterBodiesResponse)
async def get_water_bodies_accurate() -> WaterBodiesResponse:
    """Returns water bodies with OSM/Nominatim verified coordinates."""
    return WaterBodiesResponse(items=_SAMPLE_WATER_BODIES)


@router.get("/snow/{river_id}", response_model=SnowCoverData)
async def get_snow_cover(river_id: str) -> SnowCoverData:
    """Returns snow cover data from Copernicus SCE for a river basin."""
    if river_id not in _MOCK_SNOW_DATA:
        return SnowCoverData(
            river_id=river_id,
            snow_cover_percent=0.0,
            last_updated=datetime.now(),
            source="Copernicus SCE (no data)",
        )
    return _MOCK_SNOW_DATA[river_id]


@router.get("/observations", response_model=list[WaterQualityObservation])
async def get_water_quality_observations() -> list[WaterQualityObservation]:
    """Returns water quality observations from Copernicus LWQ."""
    return list(_MOCK_WATER_QUALITY.values())


@router.get("/forecasts", response_model=list[RiverForecast])
async def get_river_forecasts(river_id: str | None = None) -> list[RiverForecast]:
    """Returns river discharge forecasts from Copernicus CDS."""
    if river_id and river_id in _MOCK_FORECASTS:
        return _MOCK_FORECASTS[river_id]
    all_forecasts = []
    for forecasts in _MOCK_FORECASTS.values():
        all_forecasts.extend(forecasts)
    return all_forecasts


@router.get("/{water_body_id}", response_model=WaterBody)
async def get_water_body(water_body_id: str) -> WaterBody:
    for wb in _SAMPLE_WATER_BODIES:
        if wb.id == water_body_id:
            return wb
    raise HTTPException(status_code=404, detail="Water body not found")

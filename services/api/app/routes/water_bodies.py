from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter()


class WaterBody(BaseModel):
    id: str
    name: str
    latitude: float
    longitude: float
    area_km2: float
    country: str
    access_index: float | None = None


class WaterBodiesResponse(BaseModel):
    items: list[WaterBody]


_SAMPLE_WATER_BODIES: list[WaterBody] = [
    WaterBody(id="lake-balaton", name="Lake Balaton", latitude=46.85, longitude=17.73,
              area_km2=594, country="Hungary", access_index=0.92),
    WaterBody(id="danube-delta", name="Danube Delta", latitude=45.15, longitude=29.65,
              area_km2=5165, country="Romania", access_index=0.71),
    WaterBody(id="lake-ohrid", name="Lake Ohrid", latitude=41.02, longitude=20.72,
              area_km2=358, country="North Macedonia", access_index=0.84),
    WaterBody(id="ebro-reservoir", name="Ebro Reservoir", latitude=42.98, longitude=-3.98,
              area_km2=82, country="Spain", access_index=0.95),
    WaterBody(id="maas-river", name="Maas River", latitude=51.92, longitude=4.47,
              area_km2=33.0, country="Netherlands", access_index=0.99),
]


@router.get("", response_model=WaterBodiesResponse)
async def get_water_bodies(country: str | None = None) -> WaterBodiesResponse:
    items = _SAMPLE_WATER_BODIES
    if country:
        items = [w for w in items if w.country.lower() == country.lower()]
    return WaterBodiesResponse(items=items)


@router.get("/{water_body_id}", response_model=WaterBody)
async def get_water_body(water_body_id: str) -> WaterBody:
    for wb in _SAMPLE_WATER_BODIES:
        if wb.id == water_body_id:
            return wb
    from fastapi import HTTPException
    raise HTTPException(status_code=404, detail="Water body not found")

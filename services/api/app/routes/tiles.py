from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from datetime import datetime, timedelta
import os
import httpx
from typing import Optional

router = APIRouter()

SENTINEL_HUB_AUTH_URL = "https://identity.dataspace.copernicus.eu/auth/realms/cdse/protocol/openid-connect/token"
SENTINEL_HUB_WMS_URL = "https://sh.dataspace.copernicus.eu/ogc/wms"


class WmsToken(BaseModel):
    access_token: str
    expires_at: datetime
    token_type: str = "Bearer"


class WmsLayerRequest(BaseModel):
    layer: str = "TRUE_COLOR"
    time: Optional[str] = None


class WmsLayerResponse(BaseModel):
    url: str
    layer: str
    time: Optional[str]
    source: str = "Copernicus Sentinel Hub"


_AVAILABLE_LAYERS = {
    "TRUE_COLOR": "TRUE_COLOR",
    "FALSE_COLOR": "FALSE_COLOR",
    "NDWI": "NDWI",
    "CLOUD_MASK": "CLOUD_MASK",
    "ARABEL": "ARABEL",
    "BANDS": "BANDS",
    "SNOW_COVER": "SNOW",
}


_TOKEN_CACHE: Optional[WmsToken] = None


async def get_sentinel_hub_token(client_id: str, client_secret: str) -> WmsToken:
    global _TOKEN_CACHE
    
    if _TOKEN_CACHE and _TOKEN_CACHE.expires_at > datetime.now():
        return _TOKEN_CACHE
    
    async with httpx.AsyncClient() as client:
        response = await client.post(
            SENTINEL_HUB_AUTH_URL,
            data={
                "grant_type": "client_credentials",
                "client_id": client_id,
                "client_secret": client_secret,
            },
            headers={"Content-Type": "application/x-www-form-urlencoded"},
        )
    
    if response.status_code != 200:
        raise HTTPException(
            status_code=401,
            detail=f"Failed to get Sentinel Hub token: {response.text}"
        )
    
    data = response.json()
    _TOKEN_CACHE = WmsToken(
        access_token=data["access_token"],
        expires_at=datetime.now() + timedelta(seconds=data.get("expires_in", 3600)),
        token_type=data.get("token_type", "Bearer"),
    )
    return _TOKEN_CACHE


@router.get("/auth")
async def get_wms_token() -> WmsToken:
    """Get or refresh OAuth token from Sentinel Hub."""
    client_id = os.getenv("COPERNICUS_CLIENT_ID")
    client_secret = os.getenv("COPERNICUS_CLIENT_SECRET")
    
    if not client_id or not client_secret:
        raise HTTPException(
            status_code=500,
            detail="COPERNICUS_CLIENT_ID or COPERNICUS_CLIENT_SECRET not configured"
        )
    
    return await get_sentinel_hub_token(client_id, client_secret)


@router.get("/wms", response_model=WmsLayerResponse)
async def get_wms_url(
    layer: str = "TRUE_COLOR",
    time: Optional[str] = None,
    bbox: Optional[str] = None,
    width: int = 256,
    height: int = 256,
) -> WmsLayerResponse:
    """Get WMS tile URL for a given layer."""
    from app.config import settings
    
    client_id = settings.copernicus_client_id
    client_secret = settings.copernicus_client_secret
    
    if not client_id or not client_secret:
        raise HTTPException(
            status_code=500,
            detail="Copernicus credentials not configured"
        )
    
    if layer not in _AVAILABLE_LAYERS:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid layer. Available: {list(_AVAILABLE_LAYERS.keys())}"
        )
    
    token = await get_sentinel_hub_token(client_id, client_secret)
    
    params = {
        "SERVICE": "WMS",
        "VERSION": "1.3.0",
        "REQUEST": "GetMap",
        "LAYERS": _AVAILABLE_LAYERS[layer],
        "STYLES": "",
        "FORMAT": "image/png",
        "TRANSPARENT": "true",
        "WIDTH": width,
        "HEIGHT": height,
        "CRS": "EPSG:3857",
    }
    
    if time:
        params["TIME"] = time
    
    if bbox:
        params["BBOX"] = bbox
    else:
        params["BBOX"] = "-180,-90,180,90"
    
    query_string = "&".join([f"{k}={v}" for k, v in params.items()])
    
    url = f"{SENTINEL_HUB_WMS_URL}?{query_string}&access_token={token.access_token}"
    
    return WmsLayerResponse(
        url=url,
        layer=layer,
        time=time,
        source="Copernicus Sentinel Hub",
    )


@router.get("/layers")
async def get_available_layers():
    """Get list of available Sentinel Hub layers."""
    return {"layers": list(_AVAILABLE_LAYERS.keys())}


@router.get("/demo/wms", response_model=WmsLayerResponse)
async def get_demo_wms_url(layer: str = "TRUE_COLOR") -> WmsLayerResponse:
    """
    Get a demo WMS URL without authentication.
    Uses public Sentinel Hub demo instance.
    """
    demo_base_url = "https://demo.sentinel-hub.com/ogc/wms"
    
    params = {
        "SERVICE": "WMS",
        "VERSION": "1.3.0",
        "REQUEST": "GetMap",
        "LAYERS": _AVAILABLE_LAYERS.get(layer, "TRUE_COLOR"),
        "STYLES": "",
        "FORMAT": "image/png",
        "TRANSPARENT": "true",
        "WIDTH": 256,
        "HEIGHT": 256,
        "CRS": "EPSG:3857",
        "BBOX": "-180,-90,180,90",
    }
    
    query_string = "&".join([f"{k}={v}" for k, v in params.items()])
    
    return WmsLayerResponse(
        url=f"{demo_base_url}?{query_string}",
        layer=layer,
        time=None,
        source="Copernicus Sentinel Hub (Demo)",
    )
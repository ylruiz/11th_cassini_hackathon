from __future__ import annotations

import asyncio
from datetime import UTC, datetime, timedelta
from math import cos, radians
from typing import Any

import httpx

from app.config import settings
from app.models.environmental_analysis import (
    AreaAnalysis,
    EcosystemImpact,
    EnvironmentalProblem,
    PreventionMeasure,
    ProblemCause,
    ProblemLocation,
    ProblemType,
    Severity,
)


CDSE_AUTH_URL = (
    "https://identity.dataspace.copernicus.eu/auth/realms/cdse/protocol/"
    "openid-connect/token"
)
SENTINEL_HUB_STATISTICS_URL = "https://sh.dataspace.copernicus.eu/api/v1/statistics"
ANALYSIS_CACHE_TTL = timedelta(minutes=15)


class CopernicusFloodService:
    def __init__(self) -> None:
        self._access_token: str | None = None
        self._expires_at: datetime | None = None
        self._analysis_cache: AreaAnalysis | None = None
        self._analysis_cached_at: datetime | None = None
        self._analysis_lock = asyncio.Lock()

    async def get_inn_river_analysis(self) -> AreaAnalysis:
        cached = self._get_cached_analysis()
        if cached:
            return cached

        async with self._analysis_lock:
            cached = self._get_cached_analysis()
            if cached:
                return cached

            return await self._fetch_inn_river_analysis()

    async def _fetch_inn_river_analysis(self) -> AreaAnalysis:
        latitude = 48.57
        longitude = 13.48
        radius_km = 15
        bbox = self._bbox_from_center(
            latitude=latitude,
            longitude=longitude,
            radius_km=radius_km,
        )
        analysis = await self.get_analysis_for_bbox(
            bbox=bbox,
            label="Inn River",
            water_body_id="inn-river",
            latitude=latitude,
            longitude=longitude,
            radius_km=float(radius_km),
        )
        self._analysis_cache = analysis
        self._analysis_cached_at = datetime.now(UTC)
        return analysis

    async def get_analysis_for_bbox(
        self,
        *,
        bbox: list[float],
        label: str,
        water_body_id: str,
        latitude: float | None = None,
        longitude: float | None = None,
        radius_km: float | None = None,
    ) -> AreaAnalysis:
        center_lat = latitude if latitude is not None else (bbox[1] + bbox[3]) / 2
        center_lon = longitude if longitude is not None else (bbox[0] + bbox[2]) / 2
        radius = radius_km if radius_km is not None else self._bbox_radius_km(bbox)
        to_date = datetime.now(UTC)
        from_date = to_date - timedelta(days=30)

        intervals = await self._fetch_sentinel1_water_series(
            bbox=bbox,
            from_date=from_date,
            to_date=to_date,
        )
        latest = intervals[-1] if intervals else None
        water_fraction = latest["water_fraction"] if latest else 0.0
        observed_area_km2 = self._bbox_area_km2(bbox)
        flooded_area_km2 = observed_area_km2 * water_fraction
        severity = self._severity_for_water_fraction(water_fraction)
        detected_at = (latest["to"] if latest else to_date).isoformat().replace("+00:00", "Z")
        trend = self._trend_description(intervals)

        problem_id = f"copernicus-{water_body_id}-flood-001"
        aoi_label = label if label.lower().endswith("aoi") else f"{label} AOI"
        description = (
            f"Sentinel-1 SAR flood screening over a {radius:.0f} km {aoi_label} estimates "
            f"{flooded_area_km2:.1f} km² of water-like backscatter "
            f"({water_fraction * 100:.1f}% of the sampled area). {trend}"
        )

        analysis = AreaAnalysis(
            water_body_id=water_body_id,
            water_body_name=label,
            latitude=center_lat,
            longitude=center_lon,
            problems=[
                EnvironmentalProblem(
                    id=problem_id,
                    type=ProblemType.flood,
                    severity=severity,
                    location=ProblemLocation(
                        latitude=center_lat,
                        longitude=center_lon,
                        radius_km=radius,
                    ),
                    detected_at=detected_at,
                    source="Copernicus Sentinel-1 GRD",
                    description=description,
                )
            ],
            causes=[
                ProblemCause(
                    problem_id=problem_id,
                    primary_cause="Recent surface-water expansion detected by Sentinel-1 SAR time series",
                    contributing_factors=[
                        "Low radar backscatter consistent with open water or saturated floodplain surfaces",
                        "Weekly observations across the last 30 days provide short-term trend context",
                        "Local rainfall, snowmelt, and gauge data should be added for attribution",
                    ],
                    source_details=(
                        "Computed from Copernicus Data Space Sentinel Hub Statistical API "
                        "using Sentinel-1 GRD VV/VH water-threshold screening."
                    ),
                )
            ],
            prevention_measures=[
                PreventionMeasure(
                    problem_id=problem_id,
                    action="Verify high-water areas with local gauge readings and emergency field reports",
                    feasibility="high",
                    estimated_cost="Operational monitoring",
                    timeline="Same day",
                    cost_if_nothing_done="Delayed response to possible floodplain inundation",
                ),
                PreventionMeasure(
                    problem_id=problem_id,
                    action="Add river-gauge and rainfall feeds to calibrate SAR flood thresholds",
                    feasibility="medium",
                    estimated_cost="Low to medium",
                    timeline="1-2 weeks",
                    cost_if_nothing_done="Higher false-positive risk during wet-soil or low-backscatter conditions",
                ),
            ],
            ecosystem_impacts=[
                EcosystemImpact(
                    problem_id=problem_id,
                    affected_species=[
                        "Riparian vegetation",
                        "Fish spawning habitats",
                        "Aquatic invertebrates",
                        "Wetland birds",
                    ],
                    habitat_impact=(
                        "Possible floodplain inundation can disturb bankside habitats while also "
                        "reconnecting side channels and wetlands."
                    ),
                    duration="Short-term unless elevated water persists",
                    recovery_potential="High if flood pulse remains within natural seasonal range",
                )
            ],
        )
        return analysis

    def _get_cached_analysis(self) -> AreaAnalysis | None:
        if not self._analysis_cache or not self._analysis_cached_at:
            return None

        if datetime.now(UTC) - self._analysis_cached_at > ANALYSIS_CACHE_TTL:
            return None

        return self._analysis_cache

    async def _fetch_sentinel1_water_series(
        self,
        *,
        bbox: list[float],
        from_date: datetime,
        to_date: datetime,
    ) -> list[dict[str, Any]]:
        token = await self._get_access_token()
        evalscript = """
//VERSION=3
function setup() {
  return {
    input: ["VV", "VH", "dataMask"],
    output: [
      { id: "default", bands: 1, sampleType: "FLOAT32" },
      { id: "dataMask", bands: 1 }
    ]
  };
}

function evaluatePixel(sample) {
  // Conservative open-water screening for Sentinel-1 linear backscatter.
  var isWater = sample.VV < 0.05 && sample.VH < 0.02 ? 1 : 0;
  return {
    default: [isWater],
    dataMask: [sample.dataMask]
  };
}
"""
        payload = {
            "input": {
                "bounds": {
                    "bbox": bbox,
                    "properties": {"crs": "http://www.opengis.net/def/crs/EPSG/0/4326"},
                },
                "data": [
                    {
                        "type": "sentinel-1-grd",
                        "dataFilter": {
                            "timeRange": {
                                "from": from_date.isoformat().replace("+00:00", "Z"),
                                "to": to_date.isoformat().replace("+00:00", "Z"),
                            },
                            "acquisitionMode": "IW",
                        },
                        "processing": {
                            "orthorectify": True,
                            "backCoeff": "SIGMA0_ELLIPSOID",
                        },
                    }
                ],
            },
            "aggregation": {
                "timeRange": {
                    "from": from_date.isoformat().replace("+00:00", "Z"),
                    "to": to_date.isoformat().replace("+00:00", "Z"),
                },
                "aggregationInterval": {"of": "P7D"},
                "evalscript": evalscript,
                "resx": 0.001,
                "resy": 0.001,
            },
        }

        async with httpx.AsyncClient(timeout=45.0) as client:
            response = await client.post(
                SENTINEL_HUB_STATISTICS_URL,
                json=payload,
                headers={"Authorization": f"Bearer {token}"},
            )
            response.raise_for_status()

        return self._parse_statistics_intervals(response.json())

    async def get_sentinel2_evidence_for_bbox(
        self,
        *,
        bbox: list[float],
    ) -> dict[str, float | str]:
        to_date = datetime.now(UTC)
        from_date = to_date - timedelta(days=30)
        intervals = await self._fetch_sentinel2_indicator_series(
            bbox=bbox,
            from_date=from_date,
            to_date=to_date,
        )
        latest = intervals[-1] if intervals else None
        if latest is None:
            return {
                "ndwi_water_fraction": 0.0,
                "low_vegetation_fraction": 0.0,
                "snow_fraction": 0.0,
                "mean_ndvi": 0.0,
                "valid_pixel_fraction": 0.0,
                "source": "Copernicus Sentinel-2 L2A",
            }

        latest["source"] = "Copernicus Sentinel-2 L2A"
        return latest

    async def _fetch_sentinel2_indicator_series(
        self,
        *,
        bbox: list[float],
        from_date: datetime,
        to_date: datetime,
    ) -> list[dict[str, float]]:
        token = await self._get_access_token()
        evalscript = """
//VERSION=3
function setup() {
  return {
    input: ["B03", "B04", "B08", "B11", "SCL", "dataMask"],
    output: [
      { id: "default", bands: 4, sampleType: "FLOAT32" },
      { id: "dataMask", bands: 1 }
    ]
  };
}

function isCloudOrInvalid(scl) {
  return scl == 0 || scl == 1 || scl == 3 || scl == 8 || scl == 9 || scl == 10;
}

function safeIndex(a, b) {
  var denom = a + b;
  return denom == 0 ? 0 : (a - b) / denom;
}

function evaluatePixel(sample) {
  var valid = sample.dataMask == 1 && !isCloudOrInvalid(sample.SCL);
  var ndwi = safeIndex(sample.B03, sample.B08);
  var ndvi = safeIndex(sample.B08, sample.B04);
  var ndsi = safeIndex(sample.B03, sample.B11);

  var water = valid && ndwi > 0.2 && ndvi < 0.3 ? 1 : 0;
  var lowVegetation = valid && ndvi < 0.35 ? 1 : 0;
  var snow = valid && ndsi > 0.4 ? 1 : 0;

  return {
    default: [water, lowVegetation, snow, valid ? ndvi : 0],
    dataMask: [valid ? 1 : 0]
  };
}
"""
        payload = {
            "input": {
                "bounds": {
                    "bbox": bbox,
                    "properties": {"crs": "http://www.opengis.net/def/crs/EPSG/0/4326"},
                },
                "data": [
                    {
                        "type": "sentinel-2-l2a",
                        "dataFilter": {
                            "timeRange": {
                                "from": from_date.isoformat().replace("+00:00", "Z"),
                                "to": to_date.isoformat().replace("+00:00", "Z"),
                            },
                            "maxCloudCoverage": 70,
                            "mosaickingOrder": "leastCC",
                        },
                    }
                ],
            },
            "aggregation": {
                "timeRange": {
                    "from": from_date.isoformat().replace("+00:00", "Z"),
                    "to": to_date.isoformat().replace("+00:00", "Z"),
                },
                "aggregationInterval": {"of": "P30D"},
                "evalscript": evalscript,
                "resx": 0.001,
                "resy": 0.001,
            },
        }

        async with httpx.AsyncClient(timeout=45.0) as client:
            response = await client.post(
                SENTINEL_HUB_STATISTICS_URL,
                json=payload,
                headers={"Authorization": f"Bearer {token}"},
            )
            response.raise_for_status()

        return self._parse_sentinel2_intervals(response.json())

    async def _get_access_token(self) -> str:
        if (
            self._access_token
            and self._expires_at
            and self._expires_at > datetime.now(UTC) + timedelta(seconds=30)
        ):
            return self._access_token

        if not settings.copernicus_client_id or not settings.copernicus_client_secret:
            raise RuntimeError("Copernicus credentials are not configured")

        async with httpx.AsyncClient(timeout=20.0) as client:
            response = await client.post(
                CDSE_AUTH_URL,
                data={
                    "grant_type": "client_credentials",
                    "client_id": settings.copernicus_client_id,
                    "client_secret": settings.copernicus_client_secret,
                },
                headers={"Content-Type": "application/x-www-form-urlencoded"},
            )
            response.raise_for_status()

        token_payload = response.json()
        self._access_token = token_payload["access_token"]
        self._expires_at = datetime.now(UTC) + timedelta(
            seconds=token_payload.get("expires_in", 3600)
        )
        return self._access_token

    def _parse_statistics_intervals(self, payload: dict[str, Any]) -> list[dict[str, Any]]:
        intervals = []
        for item in payload.get("data", []):
            band_stats = (
                item.get("outputs", {})
                .get("default", {})
                .get("bands", {})
                .get("B0", {})
                .get("stats", {})
            )
            sample_count = band_stats.get("sampleCount") or 0
            no_data_count = band_stats.get("noDataCount") or 0
            valid_count = max(sample_count - no_data_count, 0)
            if valid_count == 0:
                continue

            intervals.append(
                {
                    "from": datetime.fromisoformat(
                        item["interval"]["from"].replace("Z", "+00:00")
                    ),
                    "to": datetime.fromisoformat(
                        item["interval"]["to"].replace("Z", "+00:00")
                    ),
                    "water_fraction": float(band_stats.get("mean") or 0.0),
                    "valid_count": valid_count,
                }
            )
        return intervals

    def _parse_sentinel2_intervals(self, payload: dict[str, Any]) -> list[dict[str, float]]:
        intervals = []
        for item in payload.get("data", []):
            bands = item.get("outputs", {}).get("default", {}).get("bands", {})
            water_stats = bands.get("B0", {}).get("stats", {})
            vegetation_stats = bands.get("B1", {}).get("stats", {})
            snow_stats = bands.get("B2", {}).get("stats", {})
            ndvi_stats = bands.get("B3", {}).get("stats", {})

            sample_count = water_stats.get("sampleCount") or 0
            no_data_count = water_stats.get("noDataCount") or 0
            valid_count = max(sample_count - no_data_count, 0)
            if sample_count == 0 or valid_count == 0:
                continue

            intervals.append(
                {
                    "ndwi_water_fraction": float(water_stats.get("mean") or 0.0),
                    "low_vegetation_fraction": float(vegetation_stats.get("mean") or 0.0),
                    "snow_fraction": float(snow_stats.get("mean") or 0.0),
                    "mean_ndvi": float(ndvi_stats.get("mean") or 0.0),
                    "valid_pixel_fraction": valid_count / sample_count,
                }
            )
        return intervals

    def _bbox_from_center(
        self,
        *,
        latitude: float,
        longitude: float,
        radius_km: float,
    ) -> list[float]:
        lat_delta = radius_km / 111.32
        lon_delta = radius_km / (111.32 * cos(radians(latitude)))
        return [
            longitude - lon_delta,
            latitude - lat_delta,
            longitude + lon_delta,
            latitude + lat_delta,
        ]

    def _bbox_area_km2(self, bbox: list[float]) -> float:
        min_lon, min_lat, max_lon, max_lat = bbox
        lat_km = (max_lat - min_lat) * 111.32
        center_lat = (min_lat + max_lat) / 2
        lon_km = (max_lon - min_lon) * 111.32 * cos(radians(center_lat))
        return abs(lat_km * lon_km)

    def _bbox_radius_km(self, bbox: list[float]) -> float:
        return (self._bbox_area_km2(bbox) ** 0.5) / 2

    def _severity_for_water_fraction(self, water_fraction: float) -> Severity:
        if water_fraction >= 0.25:
            return Severity.critical
        if water_fraction >= 0.15:
            return Severity.high
        if water_fraction >= 0.08:
            return Severity.medium
        return Severity.low

    def _trend_description(self, intervals: list[dict[str, Any]]) -> str:
        if len(intervals) < 2:
            return "Only one valid interval was available, so no trend could be computed."

        first = intervals[0]["water_fraction"]
        latest = intervals[-1]["water_fraction"]
        delta = latest - first
        if abs(delta) < 0.02:
            return "The 30-day series is broadly stable."
        if delta > 0:
            return f"The 30-day series is increasing by {delta * 100:.1f} percentage points."
        return f"The 30-day series is decreasing by {abs(delta) * 100:.1f} percentage points."


copernicus_flood_service = CopernicusFloodService()

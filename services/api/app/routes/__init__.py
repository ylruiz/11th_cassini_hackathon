from fastapi import APIRouter

from .water_bodies import router as water_bodies_router
from .water_quality import router as water_quality_router
from .floods import router as floods_router
from .environmental_analysis import router as environmental_analysis_router

router = APIRouter()
router.include_router(water_bodies_router, prefix="/water-bodies", tags=["water-bodies"])
router.include_router(water_quality_router, prefix="/water-quality", tags=["water-quality"])
router.include_router(floods_router, prefix="/floods", tags=["floods"])
router.include_router(environmental_analysis_router, prefix="/environmental", tags=["environmental"])

"""
FinePrint Backend - Main FastAPI Application

This is the main entry point for the FinePrint backend API.
It provides endpoints for analyzing promotional offers and fine print.
"""

from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
import uvicorn
import logging

from config import settings
from database import init_db, get_db, check_scan_limit, increment_scan_count, User
from models import AnalyzeRequest, AnalyzeResponse, ErrorResponse, AnalysisResult
from services.scraper_service import scrape_page_async, clean_and_deduplicate_text, ScraperMode
from services.openai_service import analyze_fine_print

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="FinePrint API",
    description="Backend service for analyzing promotional offers and fine print",
    version="1.0.0",
    debug=settings.debug
)

# Configure CORS
# In production, this will be restricted to the Railway domain
# In development, allows all origins for testing
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list if not settings.debug else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Initialize database on startup
@app.on_event("startup")
async def startup_event():
    """Initialize database tables on startup."""
    logger.info("Initializing database...")
    init_db()
    logger.info("Database initialized successfully")


@app.get("/")
async def root():
    """Root endpoint - API information."""
    return {
        "name": "FinePrint API",
        "version": "1.0.0",
        "status": "running",
        "endpoints": {
            "health": "/health",
            "analyze": "/analyze (POST)"
        }
    }


@app.get("/health")
async def health_check():
    """Health check endpoint for monitoring."""
    return {
        "status": "healthy",
        "service": "fineprint-backend",
        "openai_configured": bool(settings.openai_api_key),
        "model": settings.openai_model
    }


@app.post("/debug/reset-user-scans")
async def reset_user_scans(user_id: str, db: Session = Depends(get_db)):
    """
    DEBUG ONLY: Reset a user's scan count.
    Use this during development to test scan limits.
    """
    user = db.query(User).filter(User.user_id == user_id).first()

    if user:
        user.daily_scan_count = 0
        user.last_scan_date = None
        db.commit()
        return {"message": f"Reset scan count for user {user_id}", "success": True}
    else:
        return {"message": f"User {user_id} not found", "success": False}


@app.post("/analyze/url", response_model=AnalyzeResponse)
async def analyze_url(
    request: AnalyzeRequest,
    db: Session = Depends(get_db)
):
    """
    Analyze a promotional offer from a URL.

    This endpoint:
    1. Checks user's scan limit (free vs paid)
    2. Scrapes the provided URL for fine print
    3. Uses OpenAI to analyze and summarize the terms
    4. Returns structured analysis with risk scores
    """
    try:
        logger.info(f"Analyzing URL for user {request.user_id}: {request.url}")

        # Check scan limit
        can_scan, limit_message = check_scan_limit(db, request.user_id)
        if not can_scan:
            logger.warning(f"Scan limit reached for user {request.user_id}")
            raise HTTPException(
                status_code=429,
                detail={
                    "error": "FREE_LIMIT_REACHED",
                    "message": limit_message
                }
            )

        # Scrape the URL (uses AUTO mode: tries static first, falls back to dynamic if needed)
        logger.info(f"Scraping URL: {request.url}")
        scrape_result = await scrape_page_async(request.url, mode=ScraperMode.AUTO)

        if not scrape_result.success:
            logger.error(f"Scraping failed: {scrape_result.error}")
            raise HTTPException(
                status_code=422,
                detail={
                    "error": "SCRAPING_FAILED",
                    "message": f"Failed to scrape website: {scrape_result.error}"
                }
            )

        # Clean and prepare text
        cleaned_text = clean_and_deduplicate_text(scrape_result.content)

        # Check if we got enough content (even after auto-fallback to dynamic scraping)
        if len(cleaned_text) < settings.static_content_threshold:
            logger.warning(
                f"Scraped content too short ({len(cleaned_text)} chars) even after attempting dynamic scraping. "
                f"This page may be heavily protected or empty."
            )
            raise HTTPException(
                status_code=422,
                detail={
                    "error": "INSUFFICIENT_CONTENT",
                    "message": "Could not extract enough content from this page, even with JavaScript rendering. "
                               "The page may be protected against scraping or may not contain promotional terms. "
                               "Try taking a screenshot instead."
                }
            )

        # Analyze with OpenAI
        logger.info("Sending to OpenAI for analysis...")
        analysis_dict = analyze_fine_print(cleaned_text)

        # Convert to Pydantic model
        analysis_result = AnalysisResult(**analysis_dict)

        # Increment scan count
        increment_scan_count(db, request.user_id)

        logger.info(f"Analysis complete for user {request.user_id}")

        return AnalyzeResponse(
            success=True,
            analysis=analysis_result,
            message="Analysis completed successfully"
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Analysis failed: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail={
                "error": "ANALYSIS_FAILED",
                "message": f"Failed to analyze offer: {str(e)}"
            }
        )


# Image analysis endpoint has been removed - URL analysis only


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug
    )

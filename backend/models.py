"""
Pydantic models for request/response validation.
"""

from pydantic import BaseModel, Field
from typing import List, Optional
from enum import Enum


class CancellationDifficulty(str, Enum):
    """Difficulty level for cancellation."""
    EASY = "Easy"
    MEDIUM = "Medium"
    HARD = "Hard"


class AnalyzeRequest(BaseModel):
    """Request model for /analyze/url endpoint (URL-only analysis)."""
    url: str = Field(..., description="URL of the promotional offer to analyze")
    user_id: str = Field(..., description="User identifier for tracking limits")

    class Config:
        json_schema_extra = {
            "example": {
                "url": "https://example.com/promo",
                "user_id": "user123"
            }
        }


class AnalysisResult(BaseModel):
    """Structured analysis result from OpenAI."""
    offer_summary: str = Field(..., alias="offerSummary")
    plain_english_summary: str = Field(..., alias="plainEnglishSummary")
    hidden_requirements: List[str] = Field(..., alias="hiddenRequirements")
    red_flags: List[str] = Field(..., alias="redFlags")
    risk_score: int = Field(..., ge=0, le=100, alias="riskScore")
    clarity_score: int = Field(..., ge=0, le=100, alias="clarityScore")
    cancellation_difficulty: CancellationDifficulty = Field(..., alias="cancellationDifficulty")
    risk_score_explanation: Optional[str] = Field(None, alias="riskScoreExplanation")
    clarity_score_explanation: Optional[str] = Field(None, alias="clarityScoreExplanation")

    class Config:
        populate_by_name = True
        json_schema_extra = {
            "example": {
                "offerSummary": "Get 50% off your first 3 months of streaming service",
                "plainEnglishSummary": "This offer gives you half off for 3 months, but after that you'll pay full price unless you cancel. You have to sign up with a credit card and it will auto-renew.",
                "hiddenRequirements": [
                    "Must provide credit card to start trial",
                    "Auto-renews at $14.99/month after 3 months",
                    "Must cancel at least 2 days before renewal to avoid charges"
                ],
                "redFlags": [
                    "No reminder before auto-renewal kicks in",
                    "Cancellation requires calling customer service"
                ],
                "riskScore": 45,
                "clarityScore": 60,
                "cancellationDifficulty": "Medium"
            }
        }


class AnalyzeResponse(BaseModel):
    """Response model for /analyze endpoint."""
    success: bool
    analysis: Optional[AnalysisResult] = None
    message: Optional[str] = None
    scans_remaining_today: Optional[int] = None


class ErrorResponse(BaseModel):
    """Error response model."""
    success: bool = False
    error: str
    message: str
    error_code: Optional[str] = None

    class Config:
        json_schema_extra = {
            "example": {
                "success": False,
                "error": "FREE_LIMIT_REACHED",
                "message": "You have used your 1 free scan for today. Upgrade to get unlimited scans.",
                "error_code": "FREE_LIMIT_REACHED"
            }
        }

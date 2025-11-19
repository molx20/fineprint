"""
OpenAI Service for analyzing fine print using GPT-4o.
Provides structured analysis with risk scoring and red flag detection.
"""

from openai import OpenAI
from typing import Dict, List
import json
import logging

from config import settings

logger = logging.getLogger(__name__)

# Initialize OpenAI client
client = OpenAI(api_key=settings.openai_api_key)


ANALYSIS_PROMPT = """You are a consumer protection expert analyzing promotional offers and their fine print. Your job is to help regular people understand what they're really signing up for.

You will be given text scraped from a promotional website including:
1. Main promotional content
2. Fine print and terms of service
3. Any additional context from related pages

Your task is to analyze this information and provide a structured breakdown that helps consumers make informed decisions.

INPUT:
{input_text}

Please provide your analysis in the following JSON format:

{{
  "offerSummary": "A 2-3 sentence summary of what the promotion is offering",
  "plainEnglishSummary": "Explain the fine print in language a 5th grader could understand. Be conversational and clear.",
  "hiddenRequirements": [
    "List each hidden requirement, minimum spend, or condition not prominently displayed",
    "Include things like auto-renewal, minimum purchase amounts, eligibility restrictions"
  ],
  "redFlags": [
    "List serious concerns like cancellation difficulty, unexpected fees, misleading claims",
    "Focus on things that could harm or surprise the consumer"
  ],
  "riskScore": <number 0-100>,
  "clarityScore": <number 0-100>,
  "cancellationDifficulty": "<Easy|Medium|Hard>",
  "riskScoreExplanation": "Brief explanation of why this risk score was assigned",
  "clarityScoreExplanation": "Brief explanation of why this clarity score was assigned"
}}

SCORING GUIDELINES:
- **Risk Score (0-100)**: How risky is this offer for the average consumer?
  - 0-30: Low risk, straightforward offer
  - 31-60: Moderate risk, some concerning terms
  - 61-100: High risk, significant potential for harm or regret

- **Clarity Score (0-100)**: How clearly is the offer explained?
  - 0-30: Very unclear, deceptive, or confusing
  - 31-60: Moderately clear with some ambiguity
  - 61-100: Very clear and transparent

- **Cancellation Difficulty**:
  - Easy: Can cancel online/app anytime, no hoops to jump through
  - Medium: Requires calling or some effort but reasonable
  - Hard: Must call, long wait times, retention tactics, or unclear process

Be honest and direct. If something seems designed to trick people, say so. Consumers are trusting you to protect them.

Respond ONLY with valid JSON, no additional text.
"""


def analyze_fine_print(combined_text: str) -> Dict:
    """
    Analyze fine print using GPT-4o.

    Args:
        combined_text: Combined text from image OCR and web scraping

    Returns:
        Structured analysis dictionary
    """
    try:
        logger.info(f"Sending {len(combined_text)} characters to OpenAI for analysis...")

        # Truncate if too long to fit within organization's token limit
        # Organization limit: 30,000 tokens per minute (TPM)
        # Rough estimate: 1 token ≈ 4 characters
        # Account for prompt overhead (~2000 tokens) and response (~2000 tokens)
        # Safe limit for input text to stay under 30k tokens: (30000 - 4000) * 4 = 104,000 chars
        # Using 60,000 chars to be extra safe and avoid rate limits
        max_chars = 60000
        if len(combined_text) > max_chars:
            logger.warning(f"Text too long ({len(combined_text)} chars), truncating to {max_chars}")
            combined_text = combined_text[:max_chars] + "\n\n[... content truncated due to length ...]"

        # Create the prompt
        prompt = ANALYSIS_PROMPT.format(input_text=combined_text)

        # Call OpenAI API
        response = client.chat.completions.create(
            model=settings.openai_model,
            messages=[
                {
                    "role": "system",
                    "content": "You are a consumer protection expert. You analyze promotional offers and fine print to help people make informed decisions. Always respond with valid JSON."
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            temperature=0.3,  # Lower temperature for more consistent, factual analysis
            response_format={"type": "json_object"}  # Force JSON response
        )

        # Parse response
        result_text = response.choices[0].message.content
        logger.info(f"Received response from OpenAI: {len(result_text)} characters")

        # Parse JSON
        analysis = json.loads(result_text)

        # Validate required fields
        required_fields = [
            'offerSummary', 'plainEnglishSummary', 'hiddenRequirements',
            'redFlags', 'riskScore', 'clarityScore', 'cancellationDifficulty'
        ]

        for field in required_fields:
            if field not in analysis:
                logger.error(f"Missing required field: {field}")
                raise ValueError(f"OpenAI response missing required field: {field}")

        # Validate score ranges
        if not (0 <= analysis['riskScore'] <= 100):
            analysis['riskScore'] = max(0, min(100, analysis['riskScore']))

        if not (0 <= analysis['clarityScore'] <= 100):
            analysis['clarityScore'] = max(0, min(100, analysis['clarityScore']))

        # Validate cancellation difficulty
        valid_difficulties = ['Easy', 'Medium', 'Hard']
        if analysis['cancellationDifficulty'] not in valid_difficulties:
            logger.warning(f"Invalid cancellation difficulty: {analysis['cancellationDifficulty']}, defaulting to Medium")
            analysis['cancellationDifficulty'] = 'Medium'

        logger.info(f"Analysis complete: Risk={analysis['riskScore']}, Clarity={analysis['clarityScore']}")
        return analysis

    except json.JSONDecodeError as e:
        logger.error(f"Failed to parse OpenAI response as JSON: {str(e)}")
        raise Exception("OpenAI returned invalid JSON response")

    except Exception as e:
        logger.error(f"OpenAI analysis failed: {str(e)}")
        raise Exception(f"Failed to analyze fine print: {str(e)}")


def get_analysis_summary(analysis: Dict) -> str:
    """
    Generate a brief text summary of the analysis for logging/debugging.

    Args:
        analysis: Analysis dictionary from analyze_fine_print

    Returns:
        Human-readable summary string
    """
    return f"""
Analysis Summary:
- Offer: {analysis['offerSummary'][:100]}...
- Risk Score: {analysis['riskScore']}/100
- Clarity Score: {analysis['clarityScore']}/100
- Cancellation: {analysis['cancellationDifficulty']}
- Hidden Requirements: {len(analysis['hiddenRequirements'])}
- Red Flags: {len(analysis['redFlags'])}
""".strip()

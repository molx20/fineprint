"""
Web Scraping Service for extracting fine print and terms from websites.
Supports both static HTML scraping and dynamic JavaScript rendering.
"""

import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin, urlparse
from typing import List, Set, Tuple, Optional
from dataclasses import dataclass
from enum import Enum
import logging
import re
import asyncio

from playwright.async_api import async_playwright, TimeoutError as PlaywrightTimeout
from config import settings

logger = logging.getLogger(__name__)


class ScraperMode(Enum):
    """Scraping mode selection."""
    STATIC = "static"      # Fast, static HTML only
    DYNAMIC = "dynamic"    # Slower, executes JavaScript
    AUTO = "auto"          # Try static first, fallback to dynamic if needed


@dataclass
class ScrapeResult:
    """Result of a scraping operation."""
    url: str
    final_url: str  # After redirects
    content: str
    char_count: int
    mode_used: ScraperMode
    success: bool
    error: Optional[str] = None

    @property
    def is_likely_incomplete(self) -> bool:
        """Check if result appears to be from a JS-heavy page."""
        return self.char_count < settings.static_content_threshold

# Common terms and conditions link patterns
TERMS_PATTERNS = [
    r'terms',
    r't&c',
    r't-c',
    r'conditions',
    r'legal',
    r'disclaimer',
    r'eligibility',
    r'requirements',
    r'privacy',
    r'policy',
    r'agreement'
]


def fetch_page(url: str, timeout: int = 10) -> Tuple[str, str]:
    """
    Fetch a web page and return its content.

    Args:
        url: URL to fetch
        timeout: Request timeout in seconds

    Returns:
        Tuple of (html_content, final_url) - final_url accounts for redirects
    """
    try:
        # Add https:// if no protocol
        if not url.startswith(('http://', 'https://')):
            url = f'https://{url}'

        logger.info(f"Fetching URL: {url}")

        headers = {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
        }

        response = requests.get(url, headers=headers, timeout=timeout, allow_redirects=True)
        response.raise_for_status()

        logger.info(f"Successfully fetched {len(response.text)} characters from {url}")
        return response.text, response.url

    except requests.exceptions.RequestException as e:
        logger.error(f"Failed to fetch {url}: {str(e)}")
        raise Exception(f"Failed to fetch webpage: {str(e)}")


def extract_fine_print_sections(soup: BeautifulSoup) -> str:
    """
    Extract fine print sections from a BeautifulSoup object.

    Looks for:
    - Footer content
    - Elements with classes/ids containing 'disclaimer', 'terms', 'fine-print', etc.
    - Small text (often used for disclaimers)
    - Asterisks and dagger symbols (common in fine print)
    """
    fine_print_text = []

    # 1. Footer content
    footers = soup.find_all(['footer', 'div'], class_=re.compile(r'footer', re.I))
    for footer in footers:
        text = footer.get_text(separator=' ', strip=True)
        if text:
            fine_print_text.append(text)

    # 2. Disclaimer sections
    disclaimers = soup.find_all(['div', 'section', 'p', 'span'],
                                class_=re.compile(r'disclaimer|fine-?print|legal|terms', re.I))
    for disclaimer in disclaimers:
        text = disclaimer.get_text(separator=' ', strip=True)
        if text:
            fine_print_text.append(text)

    disclaimers_by_id = soup.find_all(['div', 'section', 'p'],
                                      id=re.compile(r'disclaimer|fine-?print|legal|terms', re.I))
    for disclaimer in disclaimers_by_id:
        text = disclaimer.get_text(separator=' ', strip=True)
        if text:
            fine_print_text.append(text)

    # 3. Small text (often disclaimers)
    small_texts = soup.find_all('small')
    for small in small_texts:
        text = small.get_text(separator=' ', strip=True)
        if text:
            fine_print_text.append(text)

    # 4. Text with asterisks or daggers (common fine print markers)
    all_text = soup.get_text(separator='\n')
    asterisk_lines = [line.strip() for line in all_text.split('\n')
                      if '*' in line or '†' in line or '‡' in line]
    fine_print_text.extend(asterisk_lines)

    return '\n'.join(fine_print_text)


def find_terms_links(soup: BeautifulSoup, base_url: str) -> List[str]:
    """
    Find links to terms & conditions, privacy policy, and related pages.

    Args:
        soup: BeautifulSoup object of the page
        base_url: Base URL for resolving relative links

    Returns:
        List of absolute URLs to terms pages
    """
    links = []
    found_urls: Set[str] = set()

    # Find all links
    for link in soup.find_all('a', href=True):
        href = link['href']
        link_text = link.get_text(strip=True).lower()

        # Check if link text or href matches terms patterns
        is_terms_link = any(
            re.search(pattern, link_text, re.I) or re.search(pattern, href, re.I)
            for pattern in TERMS_PATTERNS
        )

        if is_terms_link:
            # Convert to absolute URL
            absolute_url = urljoin(base_url, href)

            # Avoid duplicates and non-HTTP links
            if absolute_url not in found_urls and absolute_url.startswith('http'):
                found_urls.add(absolute_url)
                links.append(absolute_url)

    logger.info(f"Found {len(links)} terms-related links")
    return links


def _scrape_static(url: str, max_related_pages: int = 5) -> ScrapeResult:
    """
    Scrape using static HTML fetching (fast, no JavaScript).

    Args:
        url: Main URL to scrape
        max_related_pages: Maximum number of related pages to follow

    Returns:
        ScrapeResult with scraped content
    """
    all_text = []

    try:
        # Fetch main page
        html, final_url = fetch_page(url)
        soup = BeautifulSoup(html, 'lxml')

        # Extract main page content
        main_text = extract_fine_print_sections(soup)
        if main_text:
            all_text.append(f"=== MAIN PAGE ({final_url}) ===\n{main_text}")

        # Also get full page text for context
        full_text = soup.get_text(separator=' ', strip=True)
        all_text.append(f"\n=== FULL PAGE CONTENT ===\n{full_text}")

        # Find and scrape related terms pages
        terms_links = find_terms_links(soup, final_url)

        for i, terms_url in enumerate(terms_links[:max_related_pages]):
            try:
                logger.info(f"Scraping related page {i+1}/{len(terms_links)}: {terms_url}")
                terms_html, _ = fetch_page(terms_url)
                terms_soup = BeautifulSoup(terms_html, 'lxml')

                # Get full text from terms page
                terms_text = terms_soup.get_text(separator=' ', strip=True)
                all_text.append(f"\n=== TERMS PAGE ({terms_url}) ===\n{terms_text}")

            except Exception as e:
                logger.warning(f"Failed to scrape {terms_url}: {str(e)}")
                continue

        combined_text = '\n\n'.join(all_text)
        char_count = len(combined_text)
        logger.info(f"Static scraping complete: {char_count} characters from {final_url}")

        return ScrapeResult(
            url=url,
            final_url=final_url,
            content=combined_text,
            char_count=char_count,
            mode_used=ScraperMode.STATIC,
            success=True
        )

    except Exception as e:
        logger.error(f"Static scraping failed for {url}: {str(e)}")
        return ScrapeResult(
            url=url,
            final_url=url,
            content="",
            char_count=0,
            mode_used=ScraperMode.STATIC,
            success=False,
            error=str(e)
        )


async def _scrape_dynamic(url: str) -> ScrapeResult:
    """
    Scrape using headless browser (slow, executes JavaScript).

    Args:
        url: URL to scrape

    Returns:
        ScrapeResult with rendered content
    """
    try:
        logger.info(f"Starting dynamic scraping with Playwright for {url}")

        async with async_playwright() as p:
            # Launch headless Chromium
            browser = await p.chromium.launch(headless=True)
            context = await browser.new_context(
                user_agent='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
            )
            page = await context.new_page()

            try:
                # Navigate and wait for network to be idle
                await page.goto(url, timeout=settings.dynamic_scraping_timeout * 1000, wait_until='networkidle')

                # Get final URL after redirects
                final_url = page.url

                # Extract rendered HTML
                html_content = await page.content()

                # Parse with BeautifulSoup
                soup = BeautifulSoup(html_content, 'lxml')

                # Extract text content
                text_content = soup.get_text(separator=' ', strip=True)
                char_count = len(text_content)

                logger.info(f"Dynamic scraping complete: {char_count} characters from {final_url}")

                result = ScrapeResult(
                    url=url,
                    final_url=final_url,
                    content=f"=== DYNAMIC PAGE ({final_url}) ===\n{text_content}",
                    char_count=char_count,
                    mode_used=ScraperMode.DYNAMIC,
                    success=True
                )

            except PlaywrightTimeout:
                logger.error(f"Dynamic scraping timeout after {settings.dynamic_scraping_timeout}s for {url}")
                result = ScrapeResult(
                    url=url,
                    final_url=url,
                    content="",
                    char_count=0,
                    mode_used=ScraperMode.DYNAMIC,
                    success=False,
                    error=f"Timeout after {settings.dynamic_scraping_timeout} seconds"
                )
            finally:
                await browser.close()

        return result

    except Exception as e:
        logger.error(f"Dynamic scraping failed for {url}: {str(e)}")
        return ScrapeResult(
            url=url,
            final_url=url,
            content="",
            char_count=0,
            mode_used=ScraperMode.DYNAMIC,
            success=False,
            error=str(e)
        )


async def scrape_page_async(url: str, mode: ScraperMode = ScraperMode.AUTO, max_related_pages: int = 5) -> ScrapeResult:
    """
    Async version of main scraping orchestrator.

    Args:
        url: URL to scrape
        mode: Scraping mode (STATIC, DYNAMIC, or AUTO)
        max_related_pages: Max related pages to scrape (static mode only)

    Returns:
        ScrapeResult with scraped content
    """
    logger.info(f"Starting scrape_page for {url} with mode={mode.value}")

    if mode == ScraperMode.STATIC:
        return _scrape_static(url, max_related_pages)

    elif mode == ScraperMode.DYNAMIC:
        if not settings.enable_dynamic_scraping:
            logger.warning("Dynamic scraping is disabled in settings, falling back to static")
            return _scrape_static(url, max_related_pages)
        return await _scrape_dynamic(url)

    elif mode == ScraperMode.AUTO:
        # Try static first
        result = _scrape_static(url, max_related_pages)

        # Check if result appears incomplete
        if result.success and result.is_likely_incomplete:
            logger.warning(
                f"Static scrape returned only {result.char_count} chars (threshold: {settings.static_content_threshold}). "
                f"Falling back to dynamic scraping..."
            )

            if settings.enable_dynamic_scraping:
                dynamic_result = await _scrape_dynamic(url)
                if dynamic_result.success and not dynamic_result.is_likely_incomplete:
                    logger.info(f"Dynamic scraping successful with {dynamic_result.char_count} chars")
                    return dynamic_result
                else:
                    logger.warning("Dynamic scraping also failed or returned insufficient content, using static result")

        return result

    else:
        raise ValueError(f"Invalid scraping mode: {mode}")


def scrape_page(url: str, mode: ScraperMode = ScraperMode.AUTO, max_related_pages: int = 5) -> ScrapeResult:
    """
    Sync wrapper for scrape_page_async. Creates a new event loop if needed.

    Args:
        url: URL to scrape
        mode: Scraping mode (STATIC, DYNAMIC, or AUTO)
        max_related_pages: Max related pages to scrape (static mode only)

    Returns:
        ScrapeResult with scraped content
    """
    try:
        # Try to get the running event loop
        loop = asyncio.get_running_loop()
        # If we're already in an event loop, we can't use asyncio.run()
        # This shouldn't happen in normal usage, but just in case
        raise RuntimeError("scrape_page cannot be called from an async context. Use scrape_page_async instead.")
    except RuntimeError:
        # No running loop, safe to use asyncio.run()
        return asyncio.run(scrape_page_async(url, mode, max_related_pages))


def scrape_url(url: str, max_related_pages: int = 5) -> str:
    """
    Scrape a URL and related terms pages for fine print.

    This is a backwards-compatible wrapper around scrape_page() that uses AUTO mode.
    For new code, use scrape_page() directly for more control.

    Args:
        url: Main URL to scrape
        max_related_pages: Maximum number of related pages to follow

    Returns:
        Combined text from main page and related terms pages

    Raises:
        Exception: If scraping fails
    """
    result = scrape_page(url, mode=ScraperMode.AUTO, max_related_pages=max_related_pages)

    if not result.success:
        raise Exception(f"Failed to scrape website: {result.error}")

    return result.content


def clean_and_deduplicate_text(text: str, max_length: int = 100000) -> str:
    """
    Clean and deduplicate scraped text.

    Args:
        text: Raw scraped text
        max_length: Maximum length of returned text (default 100k chars)

    Returns:
        Cleaned text, truncated if necessary
    """
    # Remove excessive whitespace
    text = re.sub(r'\s+', ' ', text)

    # Remove duplicate sentences (simple approach)
    sentences = text.split('.')
    seen = set()
    unique_sentences = []

    for sentence in sentences:
        sentence = sentence.strip()
        if sentence and sentence not in seen and len(sentence) > 10:
            seen.add(sentence)
            unique_sentences.append(sentence)

    cleaned = '. '.join(unique_sentences)

    # Truncate if too long
    if len(cleaned) > max_length:
        logger.warning(f"Cleaned text too long ({len(cleaned)} chars), truncating to {max_length}")
        cleaned = cleaned[:max_length] + "... [content truncated]"

    return cleaned

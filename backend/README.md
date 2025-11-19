# FinePrint Backend

Backend service for the FinePrint mobile app. Analyzes promotional offers and fine print using OCR, web scraping, and OpenAI GPT-4o.

## Features

- 📸 **Image Analysis**: Extract text from screenshots using OCR
- 🌐 **Web Scraping**: Automatically scrape terms and conditions from websites
- 🤖 **AI Analysis**: Use GPT-4o to analyze and summarize fine print
- 📊 **Risk Scoring**: Calculate risk and clarity scores
- 🔒 **Usage Limits**: Enforce free tier (1 scan/day) vs paid tier (unlimited)

## Setup

### Prerequisites

- Python 3.9 or higher
- pip (Python package manager)

### Installation

1. **Create a virtual environment** (recommended):
   ```bash
   cd backend
   python3 -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

2. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Configure environment variables**:
   - Copy `.env.example` to `.env`
   - The `.env` file is already configured with your OpenAI API key
   - You can modify settings like `OPENAI_MODEL` if needed

### Running the Server

```bash
# Make sure you're in the backend directory and venv is activated
python main.py
```

The server will start on `http://localhost:8000`

### Testing the Server

Once running, you can test the endpoints:

**Health check**:
```bash
curl http://localhost:8000/health
```

**Root endpoint**:
```bash
curl http://localhost:8000/
```

## API Documentation

Once the server is running, visit:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## Project Structure

```
backend/
├── main.py              # FastAPI application entry point
├── config.py            # Configuration and settings
├── requirements.txt     # Python dependencies
├── .env                 # Environment variables (not in git)
├── .env.example         # Environment template
├── .gitignore          # Git ignore rules
└── README.md           # This file
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `OPENAI_API_KEY` | Your OpenAI API key | *required* |
| `OPENAI_MODEL` | OpenAI model to use | `gpt-4o` |
| `PORT` | Server port | `8000` |
| `HOST` | Server host | `0.0.0.0` |
| `DEBUG` | Debug mode | `true` |
| `DATABASE_URL` | SQLite database path | `sqlite:///./fineprint.db` |
| `CORS_ORIGINS` | Allowed CORS origins | `http://localhost:*,http://127.0.0.1:*` |

## Next Steps

Phase 2 will add:
- `/analyze` endpoint for image and URL analysis
- OCR service using EasyOCR
- Web scraping service with BeautifulSoup
- OpenAI integration for fine print analysis
- User limit enforcement (free vs paid tiers)

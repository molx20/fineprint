# FinePrint - Reveal the Fine Print

**FinePrint** is a mobile app that uses AI to analyze promotional offers and reveal hidden fine print, helping consumers make informed decisions.

## 🎯 What It Does

Upload a screenshot of an ad or paste a promotional URL, and FinePrint will:
- 📸 Extract text using OCR
- 🌐 Scrape the website for terms & conditions
- 🤖 Analyze everything with GPT-4o
- ⚠️ Highlight hidden requirements and red flags
- 📊 Provide risk and clarity scores

## 🏗️ Architecture

### Backend (Python + FastAPI)
- **Location**: `/backend`
- **OCR**: EasyOCR for text extraction
- **Scraping**: BeautifulSoup4 for web scraping
- **AI**: OpenAI GPT-4o for analysis
- **Database**: SQLite for user limits
- **Endpoints**:
  - `POST /analyze/url` - Analyze from URL
  - `POST /analyze/image` - Analyze from image upload

### iOS App (Swift + SwiftUI)
- **Location**: `/FinePrint`
- **Architecture**: SwiftUI with MVVM-lite patterns
- **Networking**: Native URLSession with async/await
- **State**: ObservableObject pattern with ScanManager
- **Theme**: Yellow (#FBBF24) primary, Purple (#6B46C1) secondary

## 🚀 Quick Start

### Prerequisites

- **Backend**:
  - Python 3.9+
  - pip
  - OpenAI API key

- **iOS App**:
  - macOS with Xcode 15+
  - iOS 18.2+ deployment target
  - iOS Simulator or physical device

### 1. Backend Setup

```bash
# Navigate to backend
cd backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Start the server
python main.py
```

The backend will start on **http://localhost:8001**

**Environment Variables** (already configured in `.env`):
- `OPENAI_API_KEY` - Your OpenAI API key
- `OPENAI_MODEL` - GPT model (default: `gpt-4o`)
- `PORT` - Server port (default: `8001`)

### 2. iOS App Setup

```bash
# Open Xcode project
open FinePrint.xcodeproj

# Build and run (Cmd+R)
# Select iPhone Simulator as target
```

**Note**: The app is configured to connect to `http://localhost:8001`. If running on a physical device, update the `baseURL` in `finePrintAPI.swift`.

## 📱 Features

### Free Tier
- ✅ 1 scan per day
- ✅ Full analysis results
- ✅ In-memory scan history (last 10)

### Pro Tier (Placeholder)
- ✅ Unlimited scans
- ✅ No daily limits
- 🔜 Priority processing
- 🔜 Persistent scan history
- 🔜 Smart alerts

## 🎨 App Screens

1. **HomeView** - Main dashboard with scan options and usage counter
2. **ScanInputView** - Upload image or enter URL
3. **BreakdownView** - Displays analysis with scores and red flags
4. **UpgradeView** - Free vs Pro comparison

## 🔧 Configuration

### Backend

Edit `backend/.env` to customize:
- OpenAI model selection
- Server port
- Database location
- CORS settings

### iOS

Edit these files to customize:
- **API Endpoint**: `finePrintAPI.swift` → `baseURL`
- **Colors**: Assets.xcassets color sets
- **Scan Limits**: `scanManager.swift` → `maxFreeScanPerDay`

## 📊 Testing

### Test Backend Endpoints

**Health Check**:
```bash
curl http://localhost:8001/health
```

**Analyze URL**:
```bash
curl -X POST http://localhost:8001/analyze/url \
  -H "Content-Type: application/json" \
  -d '{
    "type": "url",
    "url": "https://example.com/promo",
    "user_id": "test_user"
  }'
```

**Analyze Image**:
```bash
curl -X POST http://localhost:8001/analyze/image \
  -F "user_id=test_user" \
  -F "image=@/path/to/screenshot.jpg"
```

### iOS Debug Features

The app includes debug tools (visible in debug builds):

**Settings Menu** → **Debug Options**:
- Toggle Paid Status
- Simulate Used Scan
- Reset Scan Count

## 📝 API Response Format

```json
{
  "success": true,
  "analysis": {
    "offerSummary": "Brief offer description",
    "plainEnglishSummary": "5th grade level explanation",
    "hiddenRequirements": ["requirement 1", "requirement 2"],
    "redFlags": ["red flag 1", "red flag 2"],
    "riskScore": 65,
    "clarityScore": 45,
    "cancellationDifficulty": "Hard",
    "riskScoreExplanation": "Why this risk score",
    "clarityScoreExplanation": "Why this clarity score"
  },
  "message": "Analysis completed successfully"
}
```

## 🛠️ Tech Stack

### Backend
- **FastAPI** - Modern async web framework
- **EasyOCR** - OCR for image text extraction
- **BeautifulSoup4** - HTML parsing and scraping
- **OpenAI** - GPT-4o for AI analysis
- **SQLAlchemy** - Database ORM
- **uvicorn** - ASGI server

### iOS
- **SwiftUI** - Declarative UI framework
- **PhotosUI** - Image selection
- **Combine** - Reactive programming
- **URLSession** - Network requests

## 📂 Project Structure

```
.
├── backend/                    # Python FastAPI backend
│   ├── main.py                # FastAPI app entry point
│   ├── config.py              # Environment configuration
│   ├── database.py            # SQLAlchemy models
│   ├── models.py              # Pydantic request/response models
│   ├── services/              # Business logic
│   │   ├── ocr_service.py    # Image OCR
│   │   ├── scraper_service.py # Web scraping
│   │   └── openai_service.py # AI analysis
│   └── README.md              # Backend documentation
│
└── FinePrint/                 # iOS SwiftUI app
    ├── Views/
    │   ├── Main/
    │   │   ├── homeView.swift         # Main dashboard
    │   │   ├── scanInputView.swift    # Image/URL input
    │   │   ├── breakdownView.swift    # Analysis results
    │   │   └── upgradeView.swift      # Pricing/upgrade
    │   └── ...
    ├── Utils/
    │   ├── finePrintModels.swift      # Data models
    │   ├── finePrintAPI.swift         # API service
    │   └── scanManager.swift          # State management
    └── Assets.xcassets/               # Colors & images
```

## 🔐 Security Notes

- OpenAI API key is stored in `.env` (git-ignored)
- Backend uses HTTPS-only (except localhost for development)
- No sensitive user data is stored
- User IDs are randomly generated UUIDs

## 🚧 Roadmap

- [ ] Real payment integration (StoreKit/Stripe)
- [ ] Persistent scan history with SwiftData
- [ ] Share analysis to social media
- [ ] Browser extension for desktop
- [ ] Multi-language support
- [ ] Offline OCR capability
- [ ] Compare multiple offers side-by-side

## 🐛 Troubleshooting

**Backend won't start**:
- Check Python version: `python3 --version` (need 3.9+)
- Verify virtual environment is activated
- Check port 8001 is not in use: `lsof -ti:8001`

**iOS app can't connect**:
- Ensure backend is running on port 8001
- Check `baseURL` in `finePrintAPI.swift`
- For physical device, use your Mac's IP instead of `localhost`

**OCR/scraping fails**:
- Verify internet connection
- Check image is clear and readable
- Ensure URL is publicly accessible

## 📄 License

This project is a prototype/MVP. Contact the developer for licensing information.

## 🙋 Support

For questions or issues:
- Check backend logs in terminal
- Enable debug mode in iOS app
- Review API documentation at http://localhost:8001/docs

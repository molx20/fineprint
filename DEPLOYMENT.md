# FinePrint Deployment Guide

This guide walks you through deploying the FinePrint backend to Railway and configuring the iOS app to use it.

## Overview

After completing this guide, your iOS app will connect to a live backend hosted on Railway, accessible from anywhere with an internet connection.

**What you'll do:**
1. Deploy the FastAPI backend to Railway
2. Set up PostgreSQL database on Railway
3. Configure environment variables
4. Update iOS app with the production URL
5. Test the deployment

---

## Prerequisites

- [ ] Railway account (sign up at https://railway.app)
- [ ] GitHub account (optional, but recommended for auto-deploys)
- [ ] OpenAI API key with GPT-4o access
- [ ] Xcode installed for iOS app development

---

## Part 1: Deploy Backend to Railway

### Option A: Deploy from GitHub (Recommended)

1. **Push your code to GitHub** (if not already done):
   ```bash
   cd /path/to/fineprint-app
   git init  # if not already a git repo
   git add .
   git commit -m "Prepare for Railway deployment"
   git remote add origin YOUR_GITHUB_REPO_URL
   git push -u origin main
   ```

2. **Create a new project on Railway**:
   - Go to https://railway.app/new
   - Click "Deploy from GitHub repo"
   - Select your FinePrint repository
   - Railway will auto-detect the Dockerfile in `/backend`

3. **Configure the service**:
   - Railway should automatically detect the Dockerfile
   - Set the root directory to `/backend` if it's not auto-detected
   - Railway will start building immediately

### Option B: Deploy from CLI

1. **Install Railway CLI**:
   ```bash
   npm i -g @railway/cli
   # or
   brew install railway
   ```

2. **Login and initialize**:
   ```bash
   cd backend
   railway login
   railway init
   ```

3. **Deploy**:
   ```bash
   railway up
   ```

---

## Part 2: Add PostgreSQL Database

1. **In your Railway project**:
   - Click "New" → "Database" → "Add PostgreSQL"
   - Railway will automatically create the database and add the `DATABASE_URL` environment variable
   - The backend will automatically detect and use PostgreSQL instead of SQLite

2. **Verify database connection**:
   - The `DATABASE_URL` variable is automatically set by Railway
   - Your backend code already handles this (see `backend/database.py:16-17`)

---

## Part 3: Configure Environment Variables

1. **Go to your Railway service** → "Variables" tab

2. **Add the following environment variables**:

   | Variable | Value | Notes |
   |----------|-------|-------|
   | `OPENAI_API_KEY` | `sk-your-api-key` | Required - Your OpenAI API key |
   | `OPENAI_MODEL` | `gpt-4o` | Optional - defaults to gpt-4o |
   | `DEBUG` | `false` | Important for production |
   | `DISABLE_SCAN_LIMITS` | `false` | Enable scan limits in production |
   | `CORS_ORIGINS` | `https://your-domain.up.railway.app` | Update after getting Railway URL |

3. **Railway automatically sets these** (don't add them):
   - `PORT` - Railway manages this
   - `DATABASE_URL` - Set when you add PostgreSQL
   - `HOST` - Always `0.0.0.0` in containers

4. **Save and redeploy**:
   - Railway will automatically redeploy when you save variables

---

## Part 4: Get Your Production URL

1. **Find your Railway URL**:
   - In your Railway service, go to "Settings" → "Networking"
   - You'll see a URL like: `https://fineprint-backend-production.up.railway.app`
   - Copy this URL - you'll need it for the iOS app

2. **Test the backend**:
   ```bash
   # Test health endpoint
   curl https://YOUR-RAILWAY-URL.up.railway.app/health

   # Expected response:
   # {"status":"ok","service":"FinePrint API","openai_configured":true}
   ```

3. **Update CORS configuration**:
   - Go back to Railway → "Variables"
   - Update `CORS_ORIGINS` to your Railway URL
   - Format: `https://your-actual-url.up.railway.app`
   - Save and wait for redeploy

---

## Part 5: Configure iOS App

1. **Open the iOS project in Xcode**:
   ```bash
   cd /path/to/fineprint-app
   open FinePrint.xcodeproj
   ```

2. **Update production URL**:
   - Open `FinePrint/Utils/APIConfig.swift`
   - Find line with `productionURL` (around line 48)
   - Replace `"REPLACE_WITH_RAILWAY_URL"` with your Railway URL
   - Example:
     ```swift
     private static let productionURL: String = "https://fineprint-backend-production.up.railway.app"
     ```

3. **Verify environment is set to production**:
   - In `APIConfig.swift`, check line 18:
     ```swift
     static let current: AppEnvironment = .production
     ```
   - Make sure it's set to `.production`, not `.development`

4. **Build and run**:
   - Build the app in Xcode (⌘+B)
   - Run on your device or simulator (⌘+R)
   - The console should print:
     ```
     FinePrint API initialized
     Environment: production
     Base URL: https://your-railway-url.up.railway.app
     ```

---

## Part 6: Test the Deployment

### Test 1: Health Check
```bash
curl https://YOUR-RAILWAY-URL/health
```
Expected: `{"status":"ok",...}`

### Test 2: Analyze Endpoint
```bash
curl -X POST https://YOUR-RAILWAY-URL/analyze/url \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://example.com/promo",
    "user_id": "test-user-123"
  }'
```
Expected: JSON response with analysis results

### Test 3: iOS App - Local Network
1. Make sure your device/simulator has WiFi/cellular
2. Open the FinePrint app
3. Try analyzing a URL
4. Should work successfully

### Test 4: iOS App - Away from Home
1. Turn OFF WiFi on your device (use cellular only)
2. Open the FinePrint app
3. Try analyzing a URL
4. Should still work - this confirms the deployment is successful!

---

## Troubleshooting

### Issue: "Could not connect to server"

**Possible causes:**
1. Railway service is not running
   - Check Railway dashboard → your service should show "Active"
2. Wrong URL in APIConfig.swift
   - Verify the URL matches your Railway URL exactly (include `https://`)
3. CORS not configured properly
   - Check Railway variables → `CORS_ORIGINS` should match your domain
4. Environment variable missing
   - Check Railway variables → ensure `OPENAI_API_KEY` is set

### Issue: "OpenAI API error"

**Possible causes:**
1. Invalid API key
   - Verify `OPENAI_API_KEY` in Railway variables
2. Insufficient credits
   - Check your OpenAI account balance
3. Wrong model specified
   - Ensure `OPENAI_MODEL` is set to `gpt-4o` and you have access

### Issue: Database errors

**Possible causes:**
1. PostgreSQL not added
   - Add PostgreSQL database in Railway dashboard
2. DATABASE_URL not set
   - Should be auto-set by Railway when you add PostgreSQL
3. Tables not created
   - The app auto-creates tables on first run
   - Check Railway logs for any migration errors

### Issue: "Rate limit reached"

**This is expected behavior for free users:**
- Free users: 1 scan per day
- Paid users: Unlimited scans
- For testing: Set `DISABLE_SCAN_LIMITS=true` in Railway variables
- For production: Keep it `false` and implement payment system

---

## Monitoring and Logs

### View Railway Logs
1. Go to Railway dashboard → your service
2. Click "Deployments" tab
3. Click on the latest deployment
4. View real-time logs

### Common log patterns to watch for:
- ✅ `INFO:     Application startup complete.` - Service started successfully
- ✅ `Initializing database...` - Database connection working
- ❌ `ERROR: Could not connect to database` - Database issue
- ❌ `OpenAI API key not configured` - Missing environment variable

---

## Switching Between Development and Production

### For Local Development:
1. Open `FinePrint/Utils/APIConfig.swift`
2. Change line 18 to:
   ```swift
   static let current: AppEnvironment = .development
   ```
3. Run backend locally: `cd backend && python main.py`
4. Run iOS app in Xcode

### For Production Testing:
1. Open `FinePrint/Utils/APIConfig.swift`
2. Change line 18 to:
   ```swift
   static let current: AppEnvironment = .production
   ```
3. Run iOS app in Xcode (backend on Railway)

---

## Cost Estimates

### Railway Costs (as of 2025):
- **Hobby Plan**: $5/month
  - Includes PostgreSQL
  - Sufficient for development and small-scale production
- **Pro Plan**: $20/month
  - More resources
  - Better for production with many users

### OpenAI Costs:
- **GPT-4o**: ~$0.0025 per scan (varies by content length)
- **Estimated**: $2.50 per 1,000 scans

**Total estimated monthly cost for 1,000 scans**: ~$7.50

---

## Next Steps

Now that your backend is deployed:

1. **Test thoroughly** with different URLs and edge cases
2. **Monitor costs** on Railway and OpenAI dashboards
3. **Set up custom domain** (optional):
   - Go to Railway → Settings → Networking
   - Add your custom domain (e.g., `api.fineprint.com`)
   - Update `APIConfig.swift` with new domain
4. **Implement analytics** to track usage
5. **Set up error monitoring** (e.g., Sentry)
6. **Configure CI/CD** for automatic deployments on git push

---

## Support

- **Railway Docs**: https://docs.railway.app
- **FastAPI Docs**: https://fastapi.tiangolo.com
- **FinePrint Issues**: [Your GitHub Issues URL]

---

## Quick Reference

### Important Files Modified:
- `backend/config.py` - Port changed to 8001, PostgreSQL support added
- `backend/database.py` - SQLite/PostgreSQL auto-detection
- `backend/requirements.txt` - Added psycopg2-binary
- `backend/Dockerfile` - New file for containerization
- `backend/.dockerignore` - New file to exclude unnecessary files
- `backend/railway.toml` - New file for Railway configuration
- `FinePrint/Utils/APIConfig.swift` - New file for environment management
- `FinePrint/Utils/finePrintAPI.swift` - Updated to use APIConfig

### Environment Variables Checklist:
- [x] `OPENAI_API_KEY` (required)
- [x] `DEBUG=false` (important)
- [x] `DISABLE_SCAN_LIMITS=false` (for production)
- [x] `CORS_ORIGINS` (your Railway URL)
- [x] PostgreSQL database added
- [x] Railway URL copied to `APIConfig.swift`

### Testing Checklist:
- [ ] Health endpoint responds
- [ ] Analyze endpoint works via curl
- [ ] iOS app connects on WiFi
- [ ] iOS app connects on cellular
- [ ] Error messages are user-friendly
- [ ] Rate limiting works correctly

---

**Deployment complete!** Your FinePrint app is now accessible from anywhere. 🚀

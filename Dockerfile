# Simplified Dockerfile using Playwright's official base image
# This avoids manual dependency installation issues

FROM mcr.microsoft.com/playwright/python:v1.48.0-jammy

WORKDIR /app

# Copy backend requirements and install Python dependencies
COPY backend/requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy backend application code
COPY backend/ .

# Expose port (Railway will override this with $PORT)
EXPOSE 8001

# Run the application
# Railway sets PORT env var, so we use ${PORT:-8001} as fallback
CMD uvicorn main:app --host 0.0.0.0 --port ${PORT:-8001} --workers 1

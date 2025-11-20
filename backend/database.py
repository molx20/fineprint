"""
Database models and session management for FinePrint backend.
Manages user scan limits and usage tracking.
"""

from sqlalchemy import create_engine, Column, String, Boolean, Integer, Date
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import date

from config import settings

# Create database engine with conditional connect_args
# SQLite needs check_same_thread=False, but PostgreSQL doesn't support it
connect_args = {}
if settings.database_url.startswith("sqlite"):
    connect_args = {"check_same_thread": False}

engine = create_engine(
    settings.database_url,
    connect_args=connect_args
)

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base class for models
Base = declarative_base()


class User(Base):
    """User model for tracking scan limits and usage."""

    __tablename__ = "users"

    user_id = Column(String, primary_key=True, index=True)
    is_paid = Column(Boolean, default=False)
    last_scan_date = Column(Date, nullable=True)
    daily_scan_count = Column(Integer, default=0)

    def __repr__(self):
        return f"<User(user_id={self.user_id}, is_paid={self.is_paid}, scans_today={self.daily_scan_count})>"


def init_db():
    """Initialize database tables."""
    Base.metadata.create_all(bind=engine)


def get_db():
    """Get database session for dependency injection."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_or_create_user(db, user_id: str) -> User:
    """Get existing user or create new one."""
    user = db.query(User).filter(User.user_id == user_id).first()

    if not user:
        user = User(
            user_id=user_id,
            is_paid=False,
            last_scan_date=None,
            daily_scan_count=0
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    return user


def check_scan_limit(db, user_id: str) -> tuple[bool, str]:
    """
    Check if user can perform a scan.

    Returns:
        (can_scan: bool, message: str)
    """
    # Check if scan limits are disabled for testing
    if settings.disable_scan_limits:
        return True, "Scan limits disabled for testing"

    user = get_or_create_user(db, user_id)

    # Developer/admin user always has unlimited scans
    # You can add your device's user_id here for unlimited access
    if user_id.startswith("admin_") or user_id.startswith("dev_"):
        return True, "Developer unlimited scans"

    # Paid users have unlimited scans
    if user.is_paid:
        return True, "Unlimited scans available"

    # Free users: 1 scan per day
    today = date.today()

    # Reset counter if it's a new day
    if user.last_scan_date != today:
        user.last_scan_date = today
        user.daily_scan_count = 0
        db.commit()

    # Check if limit reached
    if user.daily_scan_count >= 1:
        return False, "You have used your 1 free scan for today. Upgrade to get unlimited scans."

    return True, f"Free scan available ({1 - user.daily_scan_count} remaining today)"


def increment_scan_count(db, user_id: str):
    """Increment user's scan count for today."""
    user = get_or_create_user(db, user_id)
    today = date.today()

    if user.last_scan_date != today:
        user.last_scan_date = today
        user.daily_scan_count = 1
    else:
        user.daily_scan_count += 1

    db.commit()

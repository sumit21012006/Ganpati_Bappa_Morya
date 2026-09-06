import os
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

# Read database URL from environment or default to local SQLite
DATABASE_URL = os.environ.get("DATABASE_URL", "sqlite:///./legal_metrology.db")

# If URL is postgres:// (common in Heroku/older providers), convert to postgresql://
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

# Configure engine arguments
connect_args = {}
if DATABASE_URL.startswith("sqlite"):
    connect_args = {"check_same_thread": False}

try:
    engine = create_engine(DATABASE_URL, connect_args=connect_args)
    # Test connection
    with engine.connect() as conn:
        pass
except Exception as e:
    # Fallback to local SQLite if PostgreSQL connection fails
    print(f"[WARN] Database connection to {DATABASE_URL} failed ({e}). Falling back to SQLite.")
    DATABASE_URL = "sqlite:///./legal_metrology.db"
    engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    """FastAPI Dependency for database sessions."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def init_db():
    """Initializes tables and seeds initial business & test records."""
    from . import models
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        models.seed_initial_data(db)
    finally:
        db.close()

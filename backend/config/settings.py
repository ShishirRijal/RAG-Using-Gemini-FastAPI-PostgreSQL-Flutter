import os
from dotenv import load_dotenv
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()


# Environment variables
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
PDF_STORAGE_DIR = os.getenv("PDF_STORAGE_DIR", "pdf_storage")
POSTGRES_DB = os.getenv("POSTGRES_DB")
POSTGRES_USER = os.getenv("POSTGRES_USER")
DB_PASSWORD = os.getenv("POSTGRES_PASSWORD")
POSTGRES_HOST = os.getenv("POSTGRES_HOST")
POSTGRES_PORT = os.getenv("POSTGRES_PORT")
BASE_URL = os.getenv("BASE_URL", "http://localhost:8000")

# Ensure required environment variables are set
if not GOOGLE_API_KEY:
    logger.error("GOOGLE_API_KEY is not set")
    raise ValueError("GOOGLE_API_KEY is required")
if not POSTGRES_DB:
    logger.error("POSTGRES_DB is not set")
    raise ValueError("POSTGRES_DB is required")
if not POSTGRES_USER:
    logger.error("POSTGRES_USER is not set")
    raise ValueError("POSTGRES_USER is required")
# if not DB_PASSWORD:    
#     logger.error("POSTGRES_PASSWORD is not set")
#     raise ValueError("POSTGRES_PASSWORD is required")
if not POSTGRES_HOST:
    logger.error("POSTGRES_HOST is not set")
    raise ValueError("POSTGRES_HOST is required")
if not POSTGRES_PORT:
    logger.error("POSTGRES_PORT is not set")
    raise ValueError("POSTGRES_PORT is required")

"""
Developer Configuration for Smart Handwritten Data Recognition
Contains settings for development and testing modes
"""
from core.config import *

# Developer mode settings
DEVELOPER_MODE = True

# Lightweight mode settings (for edge devices)
EDGE_MODE = False

# Model loading settings
LAZY_LOADING = True  # Load models on demand
PRELOAD_MODELS = False  # Preload all models at startup (for performance testing)

# Debug settings
DEBUG_LOGGING = True
VERBOSE_OUTPUT = True

# Performance settings
MAX_WORKERS = 2  # Reduce number of worker threads for development
CACHE_ENABLED = True
CACHE_SIZE = 100  # Number of items to cache

# Mock settings (for testing without hardware)
MOCK_CAMERA = False  # Use mock camera instead of real camera
MOCK_OCR = False     # Use mock OCR instead of real OCR

# Test data settings
SAMPLE_DATA_DIR = PROJECT_ROOT / "data" / "demo"

# Development features
ENABLE_EXPERIMENTAL_FEATURES = False
ENABLE_PROFILING = False

# Model paths for development
DEV_MODEL_PATHS = {
    "ocr": MODELS_DIR / "ocr" / "dev_model.pth",
    "math_ocr": MODELS_DIR / "math_ocr" / "dev_model.pth",
    "sketch": MODELS_DIR / "sketch" / "dev_model.pth"
}

# Override production settings for development
if DEVELOPER_MODE:
    LOG_LEVEL = "DEBUG"
    MAX_VERSIONS = 3  # Reduce number of versions for development
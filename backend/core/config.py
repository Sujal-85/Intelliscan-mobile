"""
Configuration settings for the Smart Handwritten Data Recognition application
"""
import os
from pathlib import Path

# Project paths
PROJECT_ROOT = Path(__file__).parent.parent.absolute()
OUTPUTS_DIR = PROJECT_ROOT / "outputs"
MODELS_DIR = PROJECT_ROOT / "models"
ASSETS_DIR = PROJECT_ROOT / "assets"

# Create directories if they don't exist
OUTPUTS_DIR.mkdir(exist_ok=True)
MODELS_DIR.mkdir(exist_ok=True)
ASSETS_DIR.mkdir(exist_ok=True)

# Model settings
OCR_MODEL_NAME = "easyocr"  # Could be "tesseract" or "custom"
MATH_OCR_MODEL_NAME = "pix2tex"
SKETCH_MODEL_NAME = "custom"

# Language settings
SUPPORTED_LANGUAGES = ["en", "hi", "mr"]  # English, Hindi, Marathi

# Camera settings
CAMERA_WIDTH = 640
CAMERA_HEIGHT = 480

# File management settings
MAX_VERSIONS = 10
LOG_LEVEL = "INFO"
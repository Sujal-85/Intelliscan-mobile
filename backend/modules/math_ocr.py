"""
Math OCR Module for Smart Handwritten Data Recognition
Handles recognition of mathematical expressions and conversion to LaTeX
"""
import cv2
import numpy as np
from PIL import Image
import logging
from typing import Union, Optional

# Try to import pix2tex if available
try:
    from pix2tex.cli import LatexOCR
    HAS_PIX2TEX = True
    IMPORT_ERROR = None
except ImportError as e:
    HAS_PIX2TEX = False
    IMPORT_ERROR = str(e)
    logging.warning(f"pix2tex not found: {e}")
except Exception as e:
    HAS_PIX2TEX = False
    IMPORT_ERROR = str(e)
    logging.error(f"pix2tex import failed: {e}")

class MathOCRModule:
    """Handles Math OCR operations"""
    
    def __init__(self):
        self._model = None
        self.init_error = None
        
    @property
    def model(self):
        """Lazy loading of LatexOCR model"""
        if self._model is None and HAS_PIX2TEX and self.init_error is None:
            try:
                logging.info("Loading LatexOCR model for the first time...")
                self._model = LatexOCR()
                logging.info("LatexOCR model loaded successfully.")
            except Exception as e:
                logging.error(f"Failed to initialize LatexOCR: {str(e)}")
                self.init_error = str(e)
                self._model = None
        return self._model
    
    def perform_math_ocr(self, image: Union[Image.Image, np.ndarray]) -> str:
        """
        Convert image containing math formula to LaTeX
        
        Args:
            image: PIL Image or numpy array
            
        Returns:
            LaTeX string
        """
        if isinstance(image, np.ndarray):
            image = Image.fromarray(image)
            
        if self.model:
            try:
                latex = self.model(image)
                
                # AI Enhancement: Solve the problem
                try:
                    from modules.gemini_client import GeminiClient
                    gemini = GeminiClient()
                    if gemini.is_ready:
                         solution = gemini.solve_math_problem(latex)
                         return f"{latex}\n\n--- AI Solution ---\n{solution}"
                except ImportError:
                    pass
                
                return latex
            except Exception as e:
                logging.error(f"Math OCR failed: {str(e)}")
                return r"\text{Error during recognition}"
        else:
            # Check for AI solution even if local OCR fails (maybe user wants to solve text?)
            # But here we need the LaTeX/Text from image.
            if IMPORT_ERROR:
                return f"\\text{{Import Error: {IMPORT_ERROR}}}"
            elif self.init_error:
                return f"\\text{{Init Error: {self.init_error}}}"
            else:
                return r"\text{Math OCR model not installed. Run: pip install pix2tex[gui]}"

    def render_latex(self, latex_code: str):
        """
        Helper to render latex in Streamlit
        """
        import streamlit as st
        st.latex(latex_code)
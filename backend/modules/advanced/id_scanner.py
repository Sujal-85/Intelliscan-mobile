import pytesseract
import cv2
import numpy as np
import re

class IDScanner:
    """
    Module for scanning ID cards (MRZ extraction).
    """

    @staticmethod
    def extract_id_info(image_file: bytes) -> dict:
        """
        Extracts info from ID card.
        """
        nparr = np.frombuffer(image_file, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        # MRZ zone usually at bottom
        # Preprocessing
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        
        # OCR
        text = pytesseract.image_to_string(gray)
        
        # Basic MRZ regex (line 1: P<USA..., line 2: digits...)
        # This is a simplified checker
        lines = text.split('\n')
        mrz_lines = [line for line in lines if '<' in line and len(line) > 20]
        
        return {
            "raw_text": text,
            "mrz_candidates": mrz_lines,
            "document_type": "Passport/ID" if mrz_lines else "Unknown"
        }

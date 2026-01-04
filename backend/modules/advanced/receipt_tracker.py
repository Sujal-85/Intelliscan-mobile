import numpy as np
import re
from PIL import Image
import io

class ReceiptTracker:
    """
    Module for extracting structured data from receipts.
    """

    @staticmethod
    def extract_expense(image_file: bytes) -> dict:
        """
        Extracts total, date, and merchant.
        """
        # Lazy imports
        try:
            import cv2
            import pytesseract
        except ImportError:
            return {"error": "OCR dependencies missing"}

        nparr = np.frombuffer(image_file, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        text = pytesseract.image_to_string(img)
        
        # Regex extraction
        # Total
        price_pattern = r'[\$£€](\d+\.\d{2})|(\d+\.\d{2})'
        prices = re.findall(price_pattern, text)
        
        # Date
        date_pattern = r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}'
        dates = re.findall(date_pattern, text)
        
        # Naive: Max price is likely total
        total = "0.00"
        if prices:
            # Flatten and filter empty
            flat_prices = [p for sub in prices for p in sub if p]
            try:
                float_prices = [float(p) for p in flat_prices]
                total = str(max(float_prices))
            except:
                pass
                
        date = dates[0] if dates else "Unknown"
        
        # Merchant: Usually first line or top text
        lines = [l.strip() for l in text.split('\n') if l.strip()]
        merchant = lines[0] if lines else "Unknown"
        
        return {
            "merchant": merchant,
            "date": date,
            "total": total,
            "currency": "$", # Default
            "category": "General"
        }

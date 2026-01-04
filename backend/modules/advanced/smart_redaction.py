import cv2
import numpy as np
import re
from PIL import Image
import pytesseract
from io import BytesIO

class SmartRedaction:
    """
    Module for redacting PII (Personal Identifiable Information) from images.
    """

    @staticmethod
    def redact_pii(image_file: bytes, redact_types: list = ['email', 'phone', 'credit_card']) -> bytes:
        """
        Redacts specified PII types from the image.
        """
        # Convert bytes to numpy array
        nparr = np.frombuffer(image_file, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        # Perform OCR to get text and bounding boxes
        # We need the boxes to know where to blur
        d = pytesseract.image_to_data(img, output_type=pytesseract.Output.DICT)
        n_boxes = len(d['text'])
        
        # Regex patterns
        patterns = {
            'email': r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
            'phone': r'\b(?:\+?\d{1,3}[-. ]?)?\(?\d{3}\)?[-. ]?\d{3}[-. ]?\d{4}\b',
            'credit_card': r'\b(?:\d{4}[- ]?){3}\d{4}\b',
            # Add more as needed
        }

        for i in range(n_boxes):
            text = d['text'][i]
            if not text.strip():
                continue
                
            conf = int(d['conf'][i])
            if conf < 60:
                continue

            should_redact = False
            
            # Simple check: if the word matches part of a pattern (naive for now, better to reconstruct lines)
            # For better accuracy, we should reconstruct lines, but token-level check works for simple cases.
            # A full implementation would group words by line numbers.
            
            for p_type in redact_types:
                if p_type in patterns:
                    # Note: Regex on single words is weak for things like phone numbers with spaces.
                    # Ideally we join text by block/line. For this v1, we check if the word looks like sensitive info.
                    if re.search(patterns[p_type], text):
                        should_redact = True
                        break
            
            # Additional heuristic: specific keywords
            if text.lower() in ['password', 'secret', 'confidential']:
                should_redact = True

            if should_redact:
                (x, y, w, h) = (d['left'][i], d['top'][i], d['width'][i], d['height'][i])
                # Gaussian blur ROI
                roi = img[y:y+h, x:x+w]
                roi = cv2.GaussianBlur(roi, (23, 23), 30)
                img[y:y+h, x:x+w] = roi

        # Encode back to bytes
        is_success, buffer = cv2.imencode(".png", img)
        if not is_success:
            raise Exception("Could not encode image")
            
        return buffer.tobytes()

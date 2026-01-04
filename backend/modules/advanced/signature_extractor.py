import cv2
import numpy as np
from PIL import Image
from io import BytesIO

class SignatureExtractor:
    """
    Module for extracting signatures from documents.
    """

    @staticmethod
    def extract_signature(image_file: bytes) -> bytes:
        """
        Extracts signature (creates a transparent background PNG of the specific dark strokes).
        """
        # Convert bytes to numpy array
        nparr = np.frombuffer(image_file, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        # 1. Convert to grayscale
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        
        # 2. Thresholding to create a binary mask (assuming signature is dark on light paper)
        # using Otsu's binarization or adaptive
        # Gaussian blur first to remove noise
        blur = cv2.GaussianBlur(gray, (5, 5), 0)
        ret, thresh = cv2.threshold(blur, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
        
        # 3. Find contours to remove small noise dots
        contours, hierarchy = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        mask = np.zeros_like(thresh)
        
        for cnt in contours:
            area = cv2.contourArea(cnt)
            # Filter very small dots
            if area > 50: 
                cv2.drawContours(mask, [cnt], -1, 255, -1)
                
        # 4. Create RGBA image
        # Expand mask to 3 channels to use as alpha? No, we need 4 channels.
        
        # Create an all-black image for the stroke color (or original color)
        # Let's use the original color of the strokes
        result = cv2.cvtColor(img, cv2.COLOR_BGR2BGRA)
        
        # The alpha channel should be the mask
        # Where mask is 255 (strokes), alpha is 255. Where mask is 0 (background), alpha is 0.
        result[:, :, 3] = mask
        
        # Optional: Crop to the bounding box of the signature
        points = cv2.findNonZero(mask)
        if points is not None:
            x, y, w, h = cv2.boundingRect(points)
            # Add a small padding
            pad = 10
            x = max(0, x - pad)
            y = max(0, y - pad)
            w = min(img.shape[1] - x, w + 2*pad)
            h = min(img.shape[0] - y, h + 2*pad)
            
            result = result[y:y+h, x:x+w]
        
        # Encode back to PNG to preserve transparency
        is_success, buffer = cv2.imencode(".png", result)
        if not is_success:
            raise Exception("Could not encode image")
            
        return buffer.tobytes()

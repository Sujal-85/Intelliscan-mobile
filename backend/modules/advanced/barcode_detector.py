from PIL import Image
import io
import numpy as np
import cv2
from pyzbar import pyzbar
from typing import List, Dict

class BarcodeDetector:
    def __init__(self):
        pass
    
    def detect(self, image: Image.Image, barcode_types: str = "all") -> List[Dict]:
        """
        Detect and decode barcodes and QR codes in images
        """
        try:
            # Convert PIL image to numpy array
            img_array = np.array(image)
            
            # If image is in RGBA format, convert to RGB
            if len(img_array.shape) == 3 and img_array.shape[2] == 4:
                img_array = cv2.cvtColor(img_array, cv2.COLOR_RGBA2RGB)
            elif len(img_array.shape) == 2 or (len(img_array.shape) == 3 and img_array.shape[2] == 1):
                # Grayscale image, convert to BGR for consistency
                img_array = cv2.cvtColor(img_array, cv2.COLOR_GRAY2BGR)
            
            # Decode barcodes using pyzbar
            barcodes = pyzbar.decode(img_array)
            
            results = []
            for barcode in barcodes:
                # Extract barcode data
                barcode_data = barcode.data.decode("utf-8")
                barcode_type = barcode.type
                
                # Only include if it matches requested types
                if barcode_types == "all" or barcode_type.lower() in barcode_types.lower():
                    # Get the bounding box
                    (x, y, w, h) = barcode.rect
                    
                    # Create result dictionary
                    result = {
                        "data": barcode_data,
                        "type": barcode_type,
                        "rect": {
                            "x": x,
                            "y": y,
                            "width": w,
                            "height": h
                        },
                        "polygon": [
                            {"x": point.x, "y": point.y} for point in barcode.polygon
                        ]
                    }
                    
                    results.append(result)
            
            return results
        except Exception as e:
            return [{"error": str(e), "data": "", "type": "", "rect": {}, "polygon": []}]

# Example usage
if __name__ == "__main__":
    detector = BarcodeDetector()
    # Example would go here
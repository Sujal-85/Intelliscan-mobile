"""
OCR Module for Smart Handwritten Data Recognition
Provides text recognition capabilities for both printed and handwritten text
"""
import cv2
import numpy as np
from PIL import Image
import io
from typing import Union, List
import logging

# Lazy loading of models
_ocr_reader = None

def get_ocr_reader():
    """Lazy loading of OCR reader"""
    global _ocr_reader
    if _ocr_reader is None:
        import easyocr # Lazy import
        # Initialize EasyOCR with support for English and Hindi
        # Note: For production, you might want to make this configurable
        _ocr_reader = easyocr.Reader(['en', 'hi', 'mr'], verbose=False)  # Added 'mr' for Marathi
    return _ocr_reader

# Lazy loading for TrOCR
_trocr_processor = None
_trocr_model = None

def get_trocr_model():
    """Lazy loading of TrOCR model"""
    global _trocr_processor, _trocr_model
    if _trocr_processor is None:
        try:
            logging.info("Loading TrOCR model...")
            from transformers import TrOCRProcessor, VisionEncoderDecoderModel # Lazy import
            import torch # Lazy import
            
            # Use a smaller model for reasonable local performance, or 'microsoft/trocr-base-handwritten' for best accuracy
            _trocr_processor = TrOCRProcessor.from_pretrained('microsoft/trocr-base-handwritten')
            _trocr_model = VisionEncoderDecoderModel.from_pretrained('microsoft/trocr-base-handwritten')
        except Exception as e:
            logging.error(f"Failed to load TrOCR: {e}")
            return None, None
            
    return _trocr_processor, _trocr_model

class OCRModule:
    """Handles OCR operations for printed and handwritten text"""
    
    def __init__(self):
        # Lazy initialization; don't load models at import time
        pass
    
    def preprocess_image(self, image: Union[Image.Image, np.ndarray]) -> np.ndarray:
        """
        Preprocess image for better OCR results
        
        Args:
            image: PIL Image or numpy array
            
        Returns:
            Preprocessed numpy array
        """
        # Convert PIL Image to numpy array if needed
        if isinstance(image, Image.Image):
            # Convert to RGB if RGBA or other mode
            if image.mode != 'RGB':
                image = image.convert('RGB')
            img_array = np.array(image)
        else:
            img_array = image.copy()
        
        # Convert to grayscale
        if len(img_array.shape) == 3:
            gray = cv2.cvtColor(img_array, cv2.COLOR_RGB2GRAY)
        else:
            gray = img_array
        
        # Apply Gaussian blur to reduce noise
        blurred = cv2.GaussianBlur(gray, (5, 5), 0)
        
        # Apply threshold to get binary image
        _, binary = cv2.threshold(blurred, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        
        return binary
    
    def reconstruct_layout(self, results: List[tuple]) -> str:
        """
        Reconstruct text layout from OCR results using bounding boxes.
        
        Args:
            results: List of (bbox, text, prob) tuples
            
        Returns:
            Formatted text string
        """
        if not results:
            return ""
            
        # Helper to get centroid y
        def get_cy(bbox):
            return sum([p[1] for p in bbox]) / 4
            
        def get_cx(bbox):
            return sum([p[0] for p in bbox]) / 4
            
        # Sort by vertical position first
        # results are (bbox, text, prob)
        # bbox is [[x1,y1], [x2,y2], [x3,y3], [x4,y4]]
        sorted_results = sorted(results, key=lambda x: get_cy(x[0]))
        
        lines = []
        current_line = []
        current_y = get_cy(sorted_results[0][0])
        
        # Heuristic for line height: average height of boxes
        heights = [abs(r[0][2][1] - r[0][0][1]) for r in sorted_results]
        avg_height = sum(heights) / len(heights) if heights else 20
        line_threshold = avg_height * 0.5
        
        for res in sorted_results:
            cy = get_cy(res[0])
            if abs(cy - current_y) > line_threshold:
                # Start new line
                lines.append(sorted(current_line, key=lambda x: get_cx(x[0])))
                current_line = [res]
                current_y = cy
            else:
                current_line.append(res)
                # Update current_y to moving average to handle slightly slanted lines
                n = len(current_line)
                current_y = (current_y * (n-1) + cy) / n
        
        if current_line:
            lines.append(sorted(current_line, key=lambda x: get_cx(x[0])))
            
        # Build text
        final_text = []
        for line in lines:
            if not line:
                continue
            
            line_text = ""
            last_x = line[0][0][0][0] # x1 of first box
            
            for res in line:
                bbox, text, _ = res
                x1 = bbox[0][0]
                
                # Add spaces based on distance
                # Simple heuristic: one space per char width approx? 
                # Or just space if dist > threshold.
                # Let's just use standard space joining for now, 
                # but we could calculate indentation here.
                dist = x1 - last_x
                if dist > avg_height: # Significant gap
                    line_text += " \t " 
                elif dist > 10 and line_text: # Small gap
                    line_text += " "
                    
                line_text += text
                last_x = bbox[1][0] # x2 of current box
            
            final_text.append(line_text)
            
        return "\n".join(final_text)

    def perform_ocr(self, image: Union[Image.Image, np.ndarray]) -> str:
        """
        Perform OCR on the given image with layout preservation
        
        Args:
            image: PIL Image or numpy array
            
        Returns:
            Recognized text as string
        """
        try:
            # Preprocess image
            processed_img = self.preprocess_image(image)
            
            # Perform OCR (get details for layout)
            # detail=1 returns (bbox, text, prob)
            reader = get_ocr_reader()
            results = reader.readtext(processed_img, detail=1, paragraph=False)
            
            # Reconstruct layout
            recognized_text = self.reconstruct_layout(results)
            
            # AI Enhancement
            try:
                from modules.gemini_client import GeminiClient
                gemini = GeminiClient()
                if gemini.is_ready:
                    return gemini.correct_ocr_text(recognized_text)
            except ImportError:
                pass
            
            return recognized_text
        except Exception as e:
            logging.error(f"OCR failed: {str(e)}")
            raise e

    def perform_high_accuracy_ocr(self, image: Union[Image.Image, np.ndarray]) -> str:
        """
        Perform OCR using TrOCR for high accuracy on handwriting
        
        Args:
            image: PIL Image or numpy array
        """
        processor, model = get_trocr_model()
        if not processor or not model:
            return "TrOCR model could not be loaded. Please check internet connection or cached models."
            
        try:
            # Prepare image
            if isinstance(image, np.ndarray):
                image = Image.fromarray(image)
            if image.mode != "RGB":
                image = image.convert("RGB")
                
            # TrOCR works best on line crops. 
            # For a full page, we strictly need segmentation first.
            # For now, we will use EasyOCR for detection/segmentation, and TrOCR for recognition of chunks.
            
            # 1. Use EasyOCR for detection (getting bounding boxes) 
            processed_img = self.preprocess_image(image)
            reader = get_ocr_reader()
            boxes = reader.readtext(processed_img, detail=1, paragraph=False) 
            
            # Check for GPU
            import torch
            device = "cuda" if torch.cuda.is_available() else "cpu"
            model.to(device)
            
            final_results = []
            
            for box in boxes:
                bbox = box[0]
                # Crop the text region
                try:
                    x_min = max(0, int(min([p[0] for p in bbox])))
                    x_max = int(max([p[0] for p in bbox]))
                    y_min = max(0, int(min([p[1] for p in bbox])))
                    y_max = int(max([p[1] for p in bbox]))
                    
                    if x_max - x_min < 5 or y_max - y_min < 5:
                        # Skip tiny boxes
                        continue
                        
                    cropped_img = image.crop((x_min, y_min, x_max, y_max))
                    
                    # Recognition with TrOCR
                    pixel_values = processor(images=cropped_img, return_tensors="pt").pixel_values.to(device)
                    generated_ids = model.generate(pixel_values)
                    generated_text = processor.batch_decode(generated_ids, skip_special_tokens=True)[0]
                    
                    # Keep the bbox but replace text
                    final_results.append((bbox, generated_text, 1.0))
                except Exception as text_err:
                    logging.warning(f"Failed to recognize box: {text_err}")
                    # Fallback to EasyOCR text
                    final_results.append(box)
                
            # Reconstruct layout with new high-acc text
            text = self.reconstruct_layout(final_results)
            
            # AI Enhancement
            try:
                from modules.gemini_client import GeminiClient
                gemini = GeminiClient()
                if gemini.is_ready:
                    return gemini.correct_ocr_text(text)
            except ImportError:
                pass
                
            return text
            
        except Exception as e:
            logging.error(f"High accuracy OCR failed processing: {str(e)}")
            return f"Error: {str(e)}"
    
    def perform_math_ocr(self, image: Union[Image.Image, np.ndarray]) -> str:
        """
        Perform mathematical expression OCR (stub implementation)
        
        Args:
            image: PIL Image or numpy array
            
        Returns:
            LaTeX representation of mathematical expression
        """
        # TODO: Implement math OCR using pix2tex or similar
        # For now, return placeholder
        return "\\int_{0}^{\\infty} e^{-x^2} dx = \\frac{\\sqrt{\\pi}}{2}"

def preload_models():
    """Explicitly lazy-load models into memory"""
    logging.info("Preloading OCR models...")
    get_ocr_reader()
    # Optional: Preload TrOCR too if we want it warm (consumes RAM)
    # get_trocr_model()
    logging.info("OCR models preloaded.")

if __name__ == "__main__":
    # This would be used for testing the module independently
    pass
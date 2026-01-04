"""
Unit tests for OCR module
"""
import unittest
import numpy as np
from PIL import Image
import sys
from pathlib import Path

# Add the project root to the path
sys.path.append(str(Path(__file__).parent.parent))

try:
    from modules.ocr import OCRModule
    MODULE_AVAILABLE = True
except ImportError:
    MODULE_AVAILABLE = False

class TestOCRModule(unittest.TestCase):
    
    @unittest.skipIf(not MODULE_AVAILABLE, "OCR module not available")
    def setUp(self):
        """Set up test fixtures"""
        self.ocr_module = OCRModule()
    
    @unittest.skipIf(not MODULE_AVAILABLE, "OCR module not available")
    def test_preprocess_image_with_pil(self):
        """Test image preprocessing with PIL Image"""
        # Create a simple test image
        img = Image.new('RGB', (100, 100), color='white')
        
        # Preprocess the image
        processed = self.ocr_module.preprocess_image(img)
        
        # Check that output is a numpy array
        self.assertIsInstance(processed, np.ndarray)
        
        # Check dimensions
        self.assertEqual(len(processed.shape), 2)  # Should be grayscale
        
        # Check data type
        self.assertEqual(processed.dtype, np.uint8)
    
    @unittest.skipIf(not MODULE_AVAILABLE, "OCR module not available")
    def test_preprocess_image_with_numpy(self):
        """Test image preprocessing with numpy array"""
        # Create a simple test image as numpy array
        img_array = np.ones((100, 100, 3), dtype=np.uint8) * 255  # White image
        
        # Preprocess the image
        processed = self.ocr_module.preprocess_image(img_array)
        
        # Check that output is a numpy array
        self.assertIsInstance(processed, np.ndarray)
        
        # Check dimensions
        self.assertEqual(len(processed.shape), 2)  # Should be grayscale
        
        # Check data type
        self.assertEqual(processed.dtype, np.uint8)

if __name__ == '__main__':
    unittest.main()
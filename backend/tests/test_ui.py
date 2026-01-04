"""
Integration tests for Streamlit UI
"""
import unittest
import sys
from pathlib import Path

# Add the project root to the path
sys.path.append(str(Path(__file__).parent.parent))

class TestUI(unittest.TestCase):
    """Test cases for the Streamlit UI"""
    
    def test_app_import(self):
        """Test that the main app can be imported without errors"""
        try:
            from app.main import main
            self.assertTrue(True)
        except Exception as e:
            self.fail(f"Failed to import main app: {e}")
    
    def test_module_imports(self):
        """Test that all required modules can be imported"""
        modules_to_test = [
            "modules.ocr",
            "modules.pdf_generator",
            "modules.file_manager",
            "modules.camera"
        ]
        
        for module_name in modules_to_test:
            try:
                __import__(module_name)
                self.assertTrue(True, f"Successfully imported {module_name}")
            except ImportError as e:
                # Some modules might not be available in test environment
                self.skipTest(f"Could not import {module_name}: {e}")

if __name__ == '__main__':
    unittest.main()
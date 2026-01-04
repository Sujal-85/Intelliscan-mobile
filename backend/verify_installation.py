"""
Verification script to check if all required dependencies are installed
"""
import sys

def verify_dependencies():
    """Verify that all required dependencies are installed"""
    dependencies = [
        ("streamlit", "Streamlit web framework"),
        ("cv2", "OpenCV computer vision"),
        ("torch", "PyTorch deep learning"),
        ("PIL", "Pillow image processing"),
        ("numpy", "NumPy numerical computing"),
        ("easyocr", "EasyOCR text recognition"),
        ("reportlab", "ReportLab PDF generation"),
    ]
    
    missing_deps = []
    
    print("Verifying dependencies...")
    print("-" * 40)
    
    for module_name, description in dependencies:
        try:
            if module_name == "cv2":
                import cv2
                print(f"✓ {description} (cv2) - Version: {cv2.__version__}")
            elif module_name == "PIL":
                from PIL import Image
                print(f"✓ {description} (PIL) - Version: {Image.__version__ if hasattr(Image, '__version__') else 'Unknown'}")
            else:
                __import__(module_name)
                module = sys.modules[module_name]
                version = getattr(module, '__version__', 'Unknown')
                print(f"✓ {description} ({module_name}) - Version: {version}")
        except ImportError as e:
            print(f"✗ {description} ({module_name}) - MISSING")
            missing_deps.append(module_name)
        except Exception as e:
            print(f"✗ {description} ({module_name}) - ERROR: {e}")
            missing_deps.append(module_name)
    
    print("-" * 40)
    
    if missing_deps:
        print(f"\nMissing dependencies: {', '.join(missing_deps)}")
        print("\nInstall missing dependencies with:")
        print("pip install -r requirements.txt")
        return False
    else:
        print("\nAll dependencies verified successfully!")
        return True

def verify_optional_dependencies():
    """Verify optional dependencies"""
    optional_deps = [
        ("pytesseract", "Tesseract OCR engine"),
        ("fitz", "PyMuPDF PDF processing"),
        ("pikepdf", "PDF manipulation"),
        ("vosk", "Speech recognition"),
        ("pyttsx3", "Text-to-speech"),
        ("transformers", "Hugging Face Transformers"),
        ("cryptography", "Cryptographic utilities"),
    ]
    
    print("\nChecking optional dependencies...")
    print("-" * 40)
    
    for module_name, description in optional_deps:
        try:
            if module_name == "fitz":
                import fitz
                print(f"✓ {description} (fitz) - Version: {fitz.__version__}")
            else:
                __import__(module_name)
                module = sys.modules[module_name]
                version = getattr(module, '__version__', 'Unknown')
                print(f"✓ {description} ({module_name}) - Version: {version}")
        except ImportError:
            print(f"○ {description} ({module_name}) - Not installed (optional)")
        except Exception as e:
            print(f"✗ {description} ({module_name}) - ERROR: {e}")

if __name__ == "__main__":
    print("Smart Handwritten Data Recognition - Dependency Verification")
    print("=" * 60)
    
    core_success = verify_dependencies()
    verify_optional_dependencies()
    
    if core_success:
        print("\n🎉 Your environment is ready to run the application!")
        print("Start the application with: streamlit run app/main.py")
    else:
        print("\n❌ Please install the missing dependencies before running the application.")

print("Testing individual imports...")

try:
    print("Importing numpy...")
    import numpy as np
    print("Imported numpy")
except Exception as e:
    print(f"Failed numpy: {e}")

try:
    print("Importing cv2...")
    import cv2
    print("Imported cv2")
except Exception as e:
    print(f"Failed cv2: {e}")

try:
    print("Importing PIL...")
    from PIL import Image
    print("Imported PIL")
except Exception as e:
    print(f"Failed PIL: {e}")

try:
    print("Importing GeminiClient...")
    from modules.gemini_client import GeminiClient
    print("Imported GeminiClient")
except Exception as e:
    print(f"Failed GeminiClient: {e}")
print("Done")

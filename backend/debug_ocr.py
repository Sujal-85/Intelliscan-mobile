
import sys
import os
sys.path.append(os.getcwd())

print("Starting debug_ocr.py")
try:
    print("Importing modules.ocr...")
    from modules import ocr
    print("Imported modules.ocr")
except Exception as e:
    print(f"Failed modules.ocr: {e}")

try:
    print("Importing api.routers.history...")
    from api.routers import history
    print("Imported api.routers.history")
except Exception as e:
    print(f"Failed api.routers.history: {e}")

try:
    print("Importing api.routers.ocr...")
    from api.routers import ocr
    print("Imported api.routers.ocr")
except Exception as e:
    print(f"Failed api.routers.ocr: {e}")
print("Done")

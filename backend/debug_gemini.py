
print("Testing GeminiClient imports...")

try:
    print("Importing os...")
    import os
    print("Imported os")
except Exception as e:
    print(f"Failed os: {e}")

try:
    print("Importing json...")
    import json
    print("Imported json")
except Exception as e:
    print(f"Failed json: {e}")

try:
    print("Importing logging...")
    import logging
    print("Imported logging")
except Exception as e:
    print(f"Failed logging: {e}")

try:
    print("Importing requests...")
    import requests
    print("Imported requests")
except Exception as e:
    print(f"Failed requests: {e}")

print("Done")

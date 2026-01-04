import wave
import struct
import io
import sys
import os

# Ensure modules in path
sys.path.append(os.getcwd())

from modules.speech_language import LanguageToolkit

def create_dummy_wav():
    # Generate 1 second of silence/tone at 16kHz mono
    buf = io.BytesIO()
    with wave.open(buf, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(16000)
        # Write silence
        data = struct.pack('<h', 0) * 16000
        w.writeframes(data)
    
    buf.seek(0)
    return buf.read()

def test_transcription():
    print("Initializing Toolkit...")
    lt = LanguageToolkit()
    
    print("Creating dummy audio...")
    audio_data = create_dummy_wav()
    
    print("Attempting transcription...")
    try:
        result = lt.transcribe_audio(audio_data)
        print(f"Result: '{result}'")
    except Exception as e:
        print(f"Exception: {e}")

if __name__ == "__main__":
    test_transcription()

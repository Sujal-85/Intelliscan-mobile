import edge_tts
import asyncio
import tempfile
import os

class TTSService:
    """
    Module for Text-to-Speech using Edge TTS (high quality).
    """

    @staticmethod
    async def generate_speech(text: str, voice: str = "en-US-AriaNeural") -> str:
        """
        Generates audio file and returns the path.
        """
        communicate = edge_tts.Communicate(text, voice)
        
        # Create a temp file
        fd, path = tempfile.mkstemp(suffix=".mp3")
        os.close(fd)
        
        await communicate.save(path)
        
        return path

import logging
import json
import os
from typing import Optional, Tuple
import threading
import io
import wave
import edge_tts
import asyncio
import contextlib

# Global locks/instances
_tts_engine = None
_tts_lock = threading.Lock()

# Translation status flags (determined at runtime)
HAS_OFFLINE_TRANSLATION = False 
HAS_ONLINE_TRANSLATION = False
TRANSLATION_ERROR = None

# Speech Recognition flags
HAS_VOSK = False

class LanguageToolkit:
    def __init__(self):
        self.vosk_model = None
        self.vosk_path = "model-small-en"
        
    def preload_models(self):
        """Perform lightweight checks but avoid loading models into RAM"""
        logging.info("Checking Speech & Language model status...")
        
        # 1. Check Vosk Model (only download, don't load)
        # 1. Check Vosk Model (only download, don't load)
        try:
             import vosk
             if not os.path.exists(self.vosk_path):
                self._download_vosk_model()
        except ImportError:
             pass
            
        # 2. Check Translation Models
        try:
            import argostranslate
            logging.info("Checking Offline Translation package status...")
            # We skip package update/install here to save memory/bandwidth on boot
            # It will be handled on first translation attempt if needed
        except ImportError:
             pass

    def _download_vosk_model(self):
        try:
            import urllib.request
            import zipfile
            
            logging.info("Downloading Vosk model (approx 40MB)...")
            url = "https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip"
            zip_path = "model.zip"
            
            urllib.request.urlretrieve(url, zip_path)
            
            with zipfile.ZipFile(zip_path, 'r') as zip_ref:
                zip_ref.extractall(".")
            
            extracted_name = "vosk-model-small-en-us-0.15"
            if os.path.exists(extracted_name):
                os.rename(extracted_name, self.vosk_path)
            
            if os.path.exists(zip_path):
                os.remove(zip_path)
                
        except Exception as e:
            logging.error(f"Failed to download Vosk model: {e}")

    def get_translation_status(self):
        status = "Unavailable"
        try:
            import argostranslate
            status = "Offline Mode (ArgosTranslate)"
        except ImportError:
            try:
                import deep_translator
                status = "Online Mode (Google Translate Fallback)"
            except ImportError:
                pass
        return status


    async def get_neural_voices(self) -> list:
        """Fetch available neural voices from Edge TTS"""
        try:
            voices = await edge_tts.list_voices()
            formatted_voices = []
            for v in voices:
                formatted_voices.append({
                    'id': v['ShortName'],
                    'name': f"{v['FriendlyName']} ({v['Gender']})",
                    'lang': v['Locale']
                })
            return formatted_voices
        except Exception as e:
            logging.error(f"Error fetching neural voices: {e}")
            return []

    async def text_to_speech_neural(self, text: str, output_file: str = "output_audio.mp3", voice_id: str = "en-US-ChristopherNeural") -> str:
        """
        Convert text to speech using Edge TTS (Neural).
        """
        try:
            if output_file.endswith(".wav"):
                output_file = output_file.replace(".wav", ".mp3")
            
            communicate = edge_tts.Communicate(text, voice_id)
            await communicate.save(output_file)
            return output_file
        except Exception as e:
            logging.error(f"Neural TTS Error: {e}")
            return ""

    def get_voices(self) -> list:
        """
        DEPRECATED: Returns system voices (pyttsx3).
        """
        global _tts_engine, _tts_lock
        voices_list = []
        with _tts_lock:
            if _tts_engine is None:
                try:
                    _tts_engine = pyttsx3.init()
                except Exception:
                     pass
            
            if _tts_engine:
                try:
                    voices = _tts_engine.getProperty('voices')
                    for v in voices:
                        voices_list.append({'id': v.id, 'name': v.name})
                except Exception as e:
                    logging.error(f"Error fetching system voices: {e}")
        return voices_list

    def text_to_speech(self, text: str, output_file: str = "output_audio.mp3", voice_id: str = None) -> str:
        """
        Legacy Sync TTS (pyttsx3).
        """
        global _tts_engine, _tts_lock
        with _tts_lock:
            try:
                if _tts_engine is None:
                    _tts_engine = pyttsx3.init()
                
                if voice_id and "Neural" not in voice_id:
                    _tts_engine.setProperty('voice', voice_id)

                if output_file.endswith(".mp3"):
                    output_file = output_file.replace(".mp3", ".wav")
                
                _tts_engine.save_to_file(text, output_file)
                _tts_engine.runAndWait()
                return output_file
            except Exception as e:
                logging.error(f"Legacy TTS Error: {e}")
                return ""

    def install_translation_packages(self):
        """Installs EN-HI and EN-MR packages if missing"""
        try:
            import argostranslate.package
            import argostranslate.translate
        except ImportError:
            return "ArgosTranslate library missing."
            
        try:
            available_packages = argostranslate.package.get_available_packages()
            installed_packages = argostranslate.package.get_installed_packages()
            installed_pairs = set((p.from_code, p.to_code) for p in installed_packages)

            pairs = [('en', 'hi'), ('hi', 'en'), ('en', 'mr'), ('mr', 'en')]
            
            count = 0
            for src, tgt in pairs:
                if (src, tgt) not in installed_pairs:
                    pkg = next(filter(lambda x: x.from_code == src and x.to_code == tgt, available_packages), None)
                    if pkg:
                        logging.info(f"Installing translation model: {src}->{tgt}...")
                        argostranslate.package.install_from_path(pkg.download())
                        count += 1
            
            if count > 0:
                return f"Installed {count} new translation models."
            return "All required translation models are present."
            
        except Exception as e:
            return f"Model install failed: {e}"

    def translate_text(self, text: str, from_code: str = 'en', to_code: str = 'hi') -> str:
        """Translation with Offline priority, Online fallback"""
        # 1. Try Offline
        try:
            import argostranslate.package
            import argostranslate.translate
            
            # Ensure models are checked/installed lazily
            self.install_translation_packages()
            
            installed = argostranslate.package.get_installed_packages()
            has_pair = any(p.from_code == from_code and p.to_code == to_code for p in installed)
            
            if has_pair:
                return argostranslate.translate.translate(text, from_code, to_code)
        except ImportError:
            pass # Offline not available
        except Exception as e:
            logging.warning(f"Offline translation failed: {e}")
        
        # 2. Try Online (Gemini Priority)
        try:
             from modules.gemini_client import GeminiClient
             gemini = GeminiClient()
             if gemini.is_ready:
                try:
                    prompt = f"Translate the following text from {from_code} to {to_code}. Return ONLY the translated text.\n\nText:\n{text}"
                    result = gemini._generate(prompt)
                    if result:
                        return result
                except Exception as e:
                    logging.warning(f"Gemini translation failed: {e}")
        except ImportError:
             pass

        # 3. Final Fallback (Deep Translator)
        try:
            from deep_translator import GoogleTranslator
            return GoogleTranslator(source=from_code, target=to_code).translate(text)
        except ImportError:
            return "Translation libraries not found."
        except Exception as e:
                return f"Online Translation Error: {e}"

    def transcribe_audio(self, audio_bytes: bytes) -> str:
        """Transcribe audio using Vosk (Offline)"""
        try:
            from vosk import Model, KaldiRecognizer, SetLogLevel
            SetLogLevel(-1) # Suppress Vosk logs
        except ImportError:
            return "Speech recognition module (Vosk) not available."

        # Ensure model is ready (Lazy Load)
        if self.vosk_model is None:
            logging.info("Loading Vosk model for transcription...")
            if not os.path.exists(self.vosk_path):
                self._download_vosk_model()
            
            if os.path.exists(self.vosk_path):
                try:
                    self.vosk_model = Model(self.vosk_path)
                except Exception as e:
                    return f"Failed to load speech model: {e}"
            else:
                return "Speech model missing."

        if not audio_bytes:
            return "No audio data received."

        try:
            # Direct FFmpeg conversion
            try:
                import subprocess
                import imageio_ffmpeg
                
                ffmpeg_exe = imageio_ffmpeg.get_ffmpeg_exe()
                cmd = [
                    ffmpeg_exe, 
                    "-i", "pipe:0", 
                    "-f", "s16le", 
                    "-ac", "1", 
                    "-ar", "16000", 
                    "-v", "quiet",
                    "pipe:1"
                ]
                
                process = subprocess.run(
                    cmd, 
                    input=audio_bytes, 
                    stdout=subprocess.PIPE, 
                    stderr=subprocess.PIPE,
                    check=True
                )
                
                processed_audio_bytes = process.stdout
                
            except Exception as e:
                logging.error(f"Audio processing error: {e}")
                return f"Audio conversion error."

            # Use loaded model
            rec = KaldiRecognizer(self.vosk_model, 16000)
            rec.AcceptWaveform(processed_audio_bytes)
            res = json.loads(rec.FinalResult())
            
            text = res.get('text', '')
            if not text: 
                return "Transcription complete but no text recognized."
            
            # AI Enhancement: Refine transcription
            try:
                from modules.gemini_client import GeminiClient
                gemini = GeminiClient()
                if gemini.is_ready:
                    return gemini.refine_speech_text(text)
            except ImportError:
                pass
                
            return text

        except Exception as e:
            logging.error(f"STT Error: {e}")
            return f"Transcription Failed: {e}"

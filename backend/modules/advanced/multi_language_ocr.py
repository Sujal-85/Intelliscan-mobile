from PIL import Image
import io
import pytesseract
from modules.gemini_client import GeminiClient
from langdetect import detect
import re

class MultiLanguageOCR:
    def __init__(self):
        self.gemini_client = GeminiClient()
        # Common language codes for Tesseract
        self.language_codes = {
            'eng': 'English',
            'ara': 'Arabic', 
            'ben': 'Bengali',
            'chi_sim': 'Chinese (Simplified)',
            'chi_tra': 'Chinese (Traditional)',
            'hin': 'Hindi',
            'spa': 'Spanish',
            'fra': 'French',
            'deu': 'German',
            'jpn': 'Japanese',
            'kor': 'Korean',
            'rus': 'Russian',
            'por': 'Portuguese',
            'ita': 'Italian',
            'nld': 'Dutch',
            'tur': 'Turkish',
            'vie': 'Vietnamese',
            'tha': 'Thai',
            'urd': 'Urdu'
        }
    
    def perform_ocr(self, image: Image.Image, target_language: str = "eng", detect_language: bool = True) -> dict:
        """
        Perform OCR with multi-language support and optional language detection
        """
        try:
            # If language detection is enabled, try to detect the language
            detected_lang = None
            if detect_language:
                # Extract text with English as default to detect language
                try:
                    text_snippet = pytesseract.image_to_string(image, lang='eng')
                    detected_lang = detect(text_snippet[:200] if len(text_snippet) > 200 else text_snippet)
                    
                    # Map detected language to Tesseract language code
                    lang_mapping = {
                        'en': 'eng', 'ar': 'ara', 'bn': 'ben', 'zh-cn': 'chi_sim', 
                        'zh-tw': 'chi_tra', 'hi': 'hin', 'es': 'spa', 'fr': 'fra',
                        'de': 'deu', 'ja': 'jpn', 'ko': 'kor', 'ru': 'rus',
                        'pt': 'por', 'it': 'ita', 'nl': 'nld', 'tr': 'tur',
                        'vi': 'vie', 'th': 'tha', 'ur': 'urd'
                    }
                    
                    target_language = lang_mapping.get(detected_lang, target_language)
                except:
                    # If detection fails, use the provided target language
                    pass
            
            # Perform OCR with the target language
            recognized_text = pytesseract.image_to_string(image, lang=target_language)
            
            # Clean up the text
            cleaned_text = self.clean_text(recognized_text)
            
            # Use Gemini to improve the text quality if needed
            improved_text = self.gemini_client.correct_text(cleaned_text)
            
            result = {
                "text": improved_text,
                "detected_language": detected_lang if detect_language else None,
                "used_language_code": target_language,
                "language_name": self.language_codes.get(target_language, "Unknown"),
                "confidence": self.estimate_confidence(cleaned_text)
            }
            
            return result
        except Exception as e:
            return {
                "text": "",
                "detected_language": None,
                "used_language_code": target_language,
                "language_name": self.language_codes.get(target_language, "Unknown"),
                "confidence": 0.0,
                "error": str(e)
            }
    
    def clean_text(self, text: str) -> str:
        """
        Clean the OCR output text
        """
        # Remove extra whitespace
        text = re.sub(r'\s+', ' ', text)
        # Remove special characters that are likely OCR errors
        text = re.sub(r'[^\w\s\.\,\!\?\;\:\-\n]', '', text)
        return text.strip()
    
    def estimate_confidence(self, text: str) -> float:
        """
        Estimate confidence based on text quality
        """
        if not text or len(text.strip()) == 0:
            return 0.0
        
        # Simple heuristic: longer text with more words is likely more confident
        words = text.split()
        avg_word_length = sum(len(word) for word in words) / len(words) if words else 0
        
        # Base confidence on text length and word characteristics
        confidence = min(len(text) / 100, 0.7)  # Up to 70% for length
        confidence += min(avg_word_length / 10, 0.3)  # Up to 30% for word quality
        
        return min(confidence, 1.0)
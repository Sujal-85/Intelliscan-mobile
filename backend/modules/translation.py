"""
Translation Module for Smart Handwritten Data Recognition
Handles offline multilingual translation
"""
import logging
from typing import Optional

# Attempt to import translation libraries
try:
    from transformers import MarianMTModel, MarianTokenizer
    TRANSFORMERS_AVAILABLE = True
except ImportError:
    TRANSFORMERS_AVAILABLE = False
    logging.warning("Transformers library not available, translation functionality will be disabled")

class TranslationModule:
    """Handles offline multilingual translation"""
    
    def __init__(self):
        self.models = {}
        self.tokenizers = {}
        
        # Language pairs supported
        self.language_pairs = {
            ("en", "hi"): "Helsinki-NLP/opus-mt-en-hi",  # English to Hindi
            ("hi", "en"): "Helsinki-NLP/opus-mt-hi-en",  # Hindi to English
            ("en", "mr"): "Helsinki-NLP/opus-mt-en-mr",  # English to Marathi
            ("mr", "en"): "Helsinki-NLP/opus-mt-mr-en",  # Marathi to English
        }
    
    def load_model(self, source_lang: str, target_lang: str) -> bool:
        """
        Load translation model for a language pair
        
        Args:
            source_lang: Source language code
            target_lang: Target language code
            
        Returns:
            True if successful, False otherwise
        """
        if not TRANSFORMERS_AVAILABLE:
            logging.warning("Transformers library not available")
            return False
        
        lang_pair = (source_lang, target_lang)
        if lang_pair not in self.language_pairs:
            logging.warning(f"Language pair {source_lang}->{target_lang} not supported")
            return False
        
        try:
            model_name = self.language_pairs[lang_pair]
            
            # Load tokenizer and model
            tokenizer = MarianTokenizer.from_pretrained(model_name)
            model = MarianMTModel.from_pretrained(model_name)
            
            # Store in dictionaries
            self.tokenizers[lang_pair] = tokenizer
            self.models[lang_pair] = model
            
            logging.info(f"Loaded translation model for {source_lang}->{target_lang}")
            return True
        except Exception as e:
            logging.error(f"Failed to load translation model for {source_lang}->{target_lang}: {e}")
            return False
    
    def translate(self, text: str, source_lang: str, target_lang: str) -> Optional[str]:
        """
        Translate text between languages
        
        Args:
            text: Text to translate
            source_lang: Source language code
            target_lang: Target language code
            
        Returns:
            Translated text or None if failed
        """
        lang_pair = (source_lang, target_lang)
        
        # Load model if not already loaded
        if lang_pair not in self.models:
            if not self.load_model(source_lang, target_lang):
                return None
        
        try:
            # Get tokenizer and model
            tokenizer = self.tokenizers[lang_pair]
            model = self.models[lang_pair]
            
            # Tokenize input text
            inputs = tokenizer(text, return_tensors="pt", padding=True)
            
            # Generate translation
            translated = model.generate(**inputs)
            
            # Decode translated text
            result = tokenizer.decode(translated[0], skip_special_tokens=True)
            
            return result
        except Exception as e:
            logging.error(f"Translation failed for {source_lang}->{target_lang}: {e}")
            return None
    
    def get_supported_languages(self) -> list:
        """
        Get list of supported language codes
        
        Returns:
            List of supported language codes
        """
        languages = set()
        for source_lang, target_lang in self.language_pairs.keys():
            languages.add(source_lang)
            languages.add(target_lang)
        return list(languages)

# For testing purposes
if __name__ == "__main__":
    # This would be used for testing the module independently
    pass
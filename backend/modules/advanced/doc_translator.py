from deep_translator import GoogleTranslator
import pytesseract
from PIL import Image
import io

class DocumentTranslator:
    """
    Module for translating documents text.
    """

    @staticmethod
    def translate_document(image_file: bytes, target_lang: str = 'es') -> dict:
        """
        Extracts text and translates it.
        Returns original text and translated text.
        """
        # Load image for OCR
        image = Image.open(io.BytesIO(image_file))
        
        # Perform OCR
        original_text = pytesseract.image_to_string(image)
        
        if not original_text.strip():
            return {"original": "", "translated": ""}
            
        # Translate
        # Split into chunks if necessary (GoogleTranslator has limits usually ~5000 chars)
        chunks = [original_text[i:i+4000] for i in range(0, len(original_text), 4000)]
        translated_chunks = []
        
        translator = GoogleTranslator(source='auto', target=target_lang)
        
        for chunk in chunks:
            translated_chunks.append(translator.translate(chunk))
            
        translated_text = " ".join(translated_chunks)
        
        return {
            "original": original_text,
            "translated": translated_text
        }

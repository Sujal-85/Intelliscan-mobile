"""
Gemini API Client Module (REST Implementation for Python 3.8 compatibility)
Handles interaction with Google's Gemini models for text correction, refinement, and math solving.
"""
import requests
import logging
import json
import os

# API Key provided by user
# API Key provided by user
API_KEY = os.getenv("GEMINI_API_KEY") 
BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-pro-preview:generateContent"

class GeminiClient:
    def __init__(self):
        self.api_key = API_KEY
        self.is_ready = bool(self.api_key)

    def _generate(self, prompt: str) -> str:
        if not self.is_ready:
            print("GeminiClient: API Key missing.")
            return ""
            
        try:
            headers = {'Content-Type': 'application/json'}
            data = {
                "contents": [{"parts": [{"text": prompt}]}]
            }
            
            # Print for debugging
            print(f"GeminiClient: Sending request to {BASE_URL}...")
            
            response = requests.post(
                f"{BASE_URL}?key={self.api_key}",
                headers=headers,
                json=data,
                timeout=30
            )
            
            if response.status_code == 200:
                result = response.json()
                try:
                    return result['candidates'][0]['content']['parts'][0]['text']
                except (KeyError, IndexError):
                    print(f"GeminiClient: Unexpected structure: {result}")
                    logging.error(f"Unexpected Gemini response structure: {result}")
                    return ""
            else:
                print(f"GeminiClient: API Error {response.status_code}: {response.text}")
                logging.error(f"Gemini API Error {response.status_code}: {response.text}")
                return ""
                
        except Exception as e:
            print(f"GeminiClient: Request Exception: {e}")
            logging.error(f"Gemini Request failed: {e}")
            return ""

    def correct_ocr_text(self, text: str) -> str:
        """
        Corrects OCR errors and formats text using Gemini.
        """
        if not text: return text
        prompt = f"Please correct the following text, which was extracted using OCR. Fix any scanning errors, spelling mistakes, and formatting issues. Return ONLY the corrected text.\n\nText:\n{text}"
        result = self._generate(prompt)
        return result if result else text

    def refine_speech_text(self, text: str) -> str:
        """
        Refines speech transcription (punctuation, grammar).
        """
        if not text: return text
        prompt = f"Please refine the following speech transcription. Add proper punctuation, capitalization, and fix grammatical errors. Return ONLY the refined text.\n\nTranscription:\n{text}"
        result = self._generate(prompt)
        return result if result else text

    def solve_math_problem(self, latex_or_text: str) -> str:
        """
        Provides a step-by-step solution for a math problem.
        """
        if not latex_or_text: return "AI Solution unavailable."
        prompt = f"Please solve the following math problem step-by-step. The input is in LaTeX or plain text. Explain the solution clearly.\n\nProblem:\n{latex_or_text}"
        result = self._generate(prompt)
        return result if result else "Failed to generate solution."

    def identify_sensitive_data(self, text: str) -> str:
        """
        Identifies sensitive data in the text for redaction.
        Returns a JSON list of strings to redact.
        """
        if not text: return "[]"
        prompt = f"""
        Analyze the following text and identify ALL sensitive personal information that should be redacted.
        Include: Names of people, Email addresses, Phone numbers, Credit Card numbers, Social Security Numbers (SSN), and Physical/Mailing Addresses.
        Return ONLY a raw JSON array of strings containing the exact text segments to redact. Do not include the type, just the text.
        Example output: ["John Doe", "john@example.com", "555-1234"]
        
        Text to analyze:
        {text[:10000]} 
        """ 
        return self._generate(prompt)

    def enhance_svg(self, svg_code: str) -> str:
        """
        Optimizes and cleans up SVG code using Gemini.
        """
        if not svg_code: return svg_code
        prompt = f"Please optimize and clean up the following SVG code. Remove unnecessary elements, group shapes where logical, and ensure it is valid SVG. Return ONLY the improved SVG code.\n\nSVG:\n{svg_code}"
        result = self._generate(prompt)
        return result if result else svg_code

    def detect_language(self, text: str) -> str:
        """
        Detects the language of the provided text.
        Returns the ISO language code (e.g., 'en', 'hi', 'mr').
        """
        if not text: return "en"
        prompt = f"Detect the language of the following text and return ONLY its 2-letter ISO code (e.g., en, hi, mr, es, fr, etc.).\n\nText:\n{text}"
        result = self._generate(prompt).strip().lower()
        return result[:2] if result else "en"

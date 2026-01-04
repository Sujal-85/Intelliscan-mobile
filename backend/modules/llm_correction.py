"""
LLM Correction Module
Uses OpenRouter (via OpenAI client) to correct OCR errors and improve formatting.
"""
from openai import OpenAI
import logging
import streamlit as st

class LLMCorrector:
    def __init__(self, api_key: str):
        self.api_key = api_key
        # OpenRouter Base URL
        self.base_url = "https://openrouter.ai/api/v1"
        self.client = OpenAI(
            base_url=self.base_url,
            api_key=self.api_key,
        )

    def correct_text(self, text: str, model: str = "google/gemma-2-9b-it:free") -> str:
        """
        Sends text to LLM for correction.
        """
        if not self.api_key:
            return "Error: API Key is missing. Please add it in Settings."

        system_prompt = """You are an expert OCR post-processing assistant. 
Your task is to correct OCR errors in the provided text while STRICTLY preserving the original layout, indentation, and line breaks.
- Fix obvious spelling mistakes caused by OCR (e.g., '1mage' -> 'Image').
- Fix broken punctuation.
- Do NOT rephrase valid sentences.
- Do NOT add any preamble or explanation (like "Here is the corrected text").
- JUST return the corrected text."""

        try:
            logging.info("Sending request to OpenRouter...")
            response = self.client.chat.completions.create(
                model=model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": text}
                ],
                extra_headers={
                    "HTTP-Referer": "http://localhost:8501", # Optional: for OpenRouter rankings
                    "X-Title": "Smart Handwritten Data Recognition", # Optional
                }
            )
            return response.choices[0].message.content
        except Exception as e:
            logging.error(f"LLM correction failed: {e}")
            return f"LLM Error: {str(e)}"

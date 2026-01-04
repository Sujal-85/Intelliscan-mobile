from PIL import Image
import io
import base64
from modules.gemini_client import GeminiClient
import numpy as np
import cv2

class HandwritingAnalyzer:
    def __init__(self):
        self.gemini_client = GeminiClient()
    
    def analyze(self, image: Image.Image) -> dict:
        """
        Analyze handwriting characteristics in an image
        """
        try:
            # Convert image to base64 for API
            buffered = io.BytesIO()
            image.save(buffered, format="JPEG")
            img_str = base64.b64encode(buffered.getvalue()).decode()
            
            # Create prompt for handwriting analysis
            prompt = """
            Analyze the handwriting in this image and provide information about:
            - Legibility/Readability score (1-10)
            - Writing style (cursive, print, mixed)
            - Slant direction (left, right, vertical)
            - Letter size consistency
            - Line spacing regularity
            - Any notable characteristics
            - Estimated writer traits (if possible)
            
            Also perform text recognition and return the recognized text.
            
            Respond in JSON format:
            {
                "legibility_score": 7,
                "writing_style": "cursive",
                "slant_direction": "right",
                "letter_size_consistency": "high",
                "line_spacing_regular": true,
                "characteristics": ["trait1", "trait2"],
                "estimated_traits": ["organized", "hurried"],
                "recognized_text": "The recognized text from the handwriting",
                "analysis_notes": "Additional notes about the handwriting"
            }
            """
            
            response = self.gemini_client.generate_content(prompt, image=image)
            
            # Try to parse the response as JSON
            import json
            import re
            
            # Extract JSON from response if it contains markdown
            json_match = re.search(r'```json\s*({.*?})\s*```', response, re.DOTALL)
            if json_match:
                result = json.loads(json_match.group(1))
            else:
                # Try to parse the entire response as JSON
                try:
                    result = json.loads(response)
                except json.JSONDecodeError:
                    # If JSON parsing fails, return a default response
                    result = {
                        "legibility_score": 5,
                        "writing_style": "unknown",
                        "slant_direction": "unknown",
                        "letter_size_consistency": "unknown",
                        "line_spacing_regular": False,
                        "characteristics": ["Could not parse analysis"],
                        "estimated_traits": ["unknown"],
                        "recognized_text": "",
                        "analysis_notes": response[:200] + "..." if len(response) > 200 else response
                    }
            
            return result
        except Exception as e:
            return {
                "legibility_score": 0,
                "writing_style": "error",
                "slant_direction": "error",
                "letter_size_consistency": "error",
                "line_spacing_regular": False,
                "characteristics": [str(e)],
                "estimated_traits": ["error"],
                "recognized_text": "",
                "analysis_notes": "Error in handwriting analysis"
            }

# Example usage
if __name__ == "__main__":
    analyzer = HandwritingAnalyzer()
    # Example would go here
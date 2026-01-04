from PIL import Image
import io
import base64

class DocumentClassifier:
    def __init__(self):
        pass
    
    def classify(self, image: Image.Image) -> dict:
        """
        Classify a document image into categories like invoice, receipt, contract, etc.
        """
        try:
            from modules.gemini_client import GeminiClient
            gemini_client = GeminiClient()
            # Convert image to base64 for API
            buffered = io.BytesIO()
            image.save(buffered, format="JPEG")
            img_str = base64.b64encode(buffered.getvalue()).decode()
            
            # Create prompt for document classification
            prompt = """
            Analyze this document and classify it into one of these categories:
            - Invoice
            - Receipt
            - Contract
            - Letter
            - Report
            - Certificate
            - ID Document
            - Financial Statement
            - Medical Document
            - Legal Document
            - Educational Document
            - Other
            
            Also provide confidence score (0-1) and key identifying features.
            
            Respond in JSON format:
            {
                "category": "category_name",
                "confidence": 0.x,
                "key_features": ["feature1", "feature2"],
                "description": "Brief description of the document"
            }
            """
            
            response = gemini_client.generate_content(prompt, image=image)
            
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
                        "category": "Other",
                        "confidence": 0.5,
                        "key_features": ["Could not parse AI response"],
                        "description": response[:200] + "..." if len(response) > 200 else response
                    }
            
            return result
        except Exception as e:
            return {
                "category": "Other",
                "confidence": 0.0,
                "key_features": [str(e)],
                "description": "Error in classification"
            }

# Example usage
if __name__ == "__main__":
    classifier = DocumentClassifier()
    # Example would go here
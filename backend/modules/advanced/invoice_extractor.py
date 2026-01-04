from PIL import Image
import io
import base64
from modules.gemini_client import GeminiClient
import json
import re

class InvoiceExtractor:
    def __init__(self):
        self.gemini_client = GeminiClient()
    
    def extract(self, image: Image.Image) -> dict:
        """
        Extract key data from invoices and receipts
        """
        try:
            # Convert image to base64 for API
            buffered = io.BytesIO()
            image.save(buffered, format="JPEG")
            img_str = base64.b64encode(buffered.getvalue()).decode()
            
            # Create prompt for invoice data extraction
            prompt = """
            Analyze this invoice/receipt and extract the following information:
            - Total amount
            - Date
            - Vendor/Company name
            - Invoice number
            - Items/services with quantities and prices
            - Tax amount
            - Subtotal
            - Payment terms
            - Due date (if different from issue date)
            
            Respond in JSON format:
            {
                "vendor_name": "string",
                "invoice_number": "string",
                "date": "YYYY-MM-DD",
                "due_date": "YYYY-MM-DD or null",
                "subtotal": number,
                "tax": number,
                "total": number,
                "currency": "string",
                "items": [
                    {
                        "description": "string",
                        "quantity": number,
                        "unit_price": number,
                        "total": number
                    }
                ],
                "payment_terms": "string",
                "notes": "string"
            }
            
            If any field is not found, use null or empty string as appropriate.
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
                        "vendor_name": "Could not extract vendor name",
                        "invoice_number": "Could not extract invoice number",
                        "date": None,
                        "due_date": None,
                        "subtotal": 0,
                        "tax": 0,
                        "total": 0,
                        "currency": "Unknown",
                        "items": [],
                        "payment_terms": "Could not extract payment terms",
                        "notes": response[:200] + "..." if len(response) > 200 else response
                    }
            
            return result
        except Exception as e:
            return {
                "vendor_name": "Error in extraction",
                "invoice_number": "Error in extraction",
                "date": None,
                "due_date": None,
                "subtotal": 0,
                "tax": 0,
                "total": 0,
                "currency": "Unknown",
                "items": [],
                "payment_terms": "Error in extraction",
                "notes": str(e)
            }

# Example usage
if __name__ == "__main__":
    extractor = InvoiceExtractor()
    # Example would go here
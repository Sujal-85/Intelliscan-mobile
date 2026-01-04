from PIL import Image
import io
import base64
from modules.gemini_client import GeminiClient
import json
import pandas as pd
import csv
from io import StringIO

class TableExtractor:
    def __init__(self):
        self.gemini_client = GeminiClient()
    
    def extract_tables(self, image: Image.Image, output_format: str = "csv") -> list:
        """
        Extract tables from documents and convert to structured formats
        """
        try:
            # Convert image to base64 for API
            buffered = io.BytesIO()
            image.save(buffered, format="JPEG")
            img_str = base64.b64encode(buffered.getvalue()).decode()
            
            # Create prompt for table extraction
            prompt = """
            Analyze this image and extract any tables present. 
            Identify the column headers and rows of data.
            
            Respond in JSON format:
            {
                "tables": [
                    {
                        "headers": ["Column1", "Column2", "Column3"],
                        "rows": [
                            ["Value1", "Value2", "Value3"],
                            ["Value4", "Value5", "Value6"]
                        ],
                        "description": "Brief description of the table content"
                    }
                ]
            }
            
            Make sure to preserve the structure of the table as closely as possible to the original.
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
                    return [{
                        "headers": ["Error"],
                        "rows": [["Could not parse table data"]],
                        "description": "Error in table extraction",
                        "format": output_format,
                        "data": "Error: " + response[:200]
                    }]
            
            # Process each table according to the requested format
            processed_tables = []
            for table in result.get("tables", []):
                processed_table = {
                    "headers": table.get("headers", []),
                    "rows": table.get("rows", []),
                    "description": table.get("description", ""),
                    "format": output_format
                }
                
                # Convert to the requested format
                if output_format == "csv":
                    processed_table["data"] = self._to_csv(table.get("headers", []), table.get("rows", []))
                elif output_format == "excel":
                    processed_table["data"] = self._to_excel(table.get("headers", []), table.get("rows", []))
                elif output_format == "json":
                    processed_table["data"] = json.dumps(table, indent=2)
                
                processed_tables.append(processed_table)
            
            return processed_tables
        except Exception as e:
            return [{
                "headers": ["Error"],
                "rows": [[str(e)]],
                "description": "Error in table extraction",
                "format": output_format,
                "data": str(e)
            }]
    
    def _to_csv(self, headers: list, rows: list) -> str:
        """
        Convert table data to CSV format
        """
        output = StringIO()
        writer = csv.writer(output)
        writer.writerow(headers)
        for row in rows:
            writer.writerow(row)
        csv_data = output.getvalue()
        output.close()
        return csv_data
    
    def _to_excel(self, headers: list, rows: list) -> str:
        """
        Convert table data to Excel format (as JSON representation)
        """
        # Create a DataFrame
        df_data = [headers] + rows
        df = pd.DataFrame(df_data[1:], columns=df_data[0])
        return df.to_json(orient='records', indent=2)

# Example usage
if __name__ == "__main__":
    extractor = TableExtractor()
    # Example would go here
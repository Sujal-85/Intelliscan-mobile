from modules.gemini_client import GeminiClient
from difflib import SequenceMatcher
import re

class DocumentComparator:
    def __init__(self):
        self.gemini_client = GeminiClient()
    
    def compare(self, text1: str, text2: str) -> dict:
        """
        Compare two documents and highlight differences
        """
        try:
            # Calculate basic similarity
            similarity_ratio = SequenceMatcher(None, text1, text2).ratio()
            
            # Find differences using difflib
            diff_details = self._find_differences(text1, text2)
            
            # Use Gemini for semantic comparison
            semantic_analysis = self._semantic_comparison(text1, text2)
            
            result = {
                "similarity": similarity_ratio,
                "differences": diff_details,
                "semantic_analysis": semantic_analysis,
                "summary": self._generate_comparison_summary(text1, text2, similarity_ratio)
            }
            
            return result
        except Exception as e:
            return {
                "similarity": 0.0,
                "differences": [],
                "semantic_analysis": "Error in comparison",
                "summary": f"Error in document comparison: {str(e)}"
            }
    
    def _find_differences(self, text1: str, text2: str) -> list:
        """
        Find differences between two texts
        """
        try:
            # Split texts into lines for comparison
            lines1 = text1.splitlines()
            lines2 = text2.splitlines()
            
            # Use SequenceMatcher to find differences
            matcher = SequenceMatcher(None, lines1, lines2)
            differences = []
            
            for tag, i1, i2, j1, j2 in matcher.get_opcodes():
                if tag != 'equal':
                    diff = {
                        "type": tag,  # 'replace', 'delete', 'insert'
                        "text1": lines1[i1:i2] if tag != 'insert' else [],
                        "text2": lines2[j1:j2] if tag != 'delete' else [],
                        "line_range_1": (i1, i2),
                        "line_range_2": (j1, j2)
                    }
                    differences.append(diff)
            
            return differences
        except:
            return [{"type": "error", "message": "Could not compute differences"}]
    
    def _semantic_comparison(self, text1: str, text2: str) -> str:
        """
        Use Gemini to provide semantic comparison
        """
        try:
            prompt = f"""
            Compare the following two texts and provide a semantic analysis of their similarities and differences:
            
            Text 1:
            {text1[:2000]}
            
            Text 2:
            {text2[:2000]}
            
            Provide analysis focusing on:
            - Content similarity
            - Key differences in meaning
            - Structural differences
            - Important changes or additions
            """
            
            response = self.gemini_client.generate_content(prompt)
            return response
        except:
            return "Could not perform semantic analysis"
    
    def _generate_comparison_summary(self, text1: str, text2: str, similarity: float) -> str:
        """
        Generate a summary of the comparison
        """
        try:
            # Get word counts
            words1 = len(text1.split())
            words2 = len(text2.split())
            
            summary = f"""
            Document Comparison Summary:
            - Similarity Score: {similarity:.2%}
            - Text 1 Length: {words1} words
            - Text 2 Length: {words2} words
            - Length Difference: {abs(words1 - words2)} words
            """
            
            return summary.strip()
        except:
            return "Could not generate comparison summary"

# Example usage
if __name__ == "__main__":
    comparator = DocumentComparator()
    text1 = "This is the first document with some content."
    text2 = "This is the second document with different content."
    result = comparator.compare(text1, text2)
    print(result)
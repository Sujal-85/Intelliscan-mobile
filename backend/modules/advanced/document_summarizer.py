from modules.gemini_client import GeminiClient

class DocumentSummarizer:
    def __init__(self):
        self.gemini_client = GeminiClient()
    
    def summarize(self, text: str, max_sentences: int = 3) -> str:
        """
        Summarize a document using AI
        """
        try:
            # Create a prompt for summarization
            prompt = f"""
            Please provide a concise summary of the following text in {max_sentences} sentences or fewer.
            Focus on the most important points and key information.
            
            Text to summarize:
            {text[:4000]}  # Limit text to prevent token issues
            
            Summary:
            """
            
            response = self.gemini_client.generate_content(prompt)
            
            # Clean up the response
            summary = self.clean_summary(response)
            
            return summary
        except Exception as e:
            return f"Error in summarization: {str(e)}"
    
    def clean_summary(self, summary: str) -> str:
        """
        Clean up the summary text
        """
        # Remove extra whitespace and newlines
        import re
        summary = re.sub(r'\s+', ' ', summary)
        return summary.strip()

# Example usage
if __name__ == "__main__":
    summarizer = DocumentSummarizer()
    sample_text = """
    Artificial intelligence (AI) is intelligence demonstrated by machines, in contrast to the natural intelligence displayed by humans and animals. Leading AI textbooks define the field as the study of "intelligent agents": any device that perceives its environment and takes actions that maximize its chance of successfully achieving its goals. Colloquially, the term "artificial intelligence" is often used to describe machines that mimic "cognitive" functions that humans associate with the human mind, such as "learning" and "problem solving".
    
    As machines become increasingly capable, tasks considered to require "intelligence" are often removed from the definition of AI, a phenomenon known as the AI effect. A quip in Tesler's Theorem says "AI is whatever hasn't been done yet." For instance, optical character recognition is frequently excluded from things considered to be AI, having become a routine technology.
    """
    
    summary = summarizer.summarize(sample_text, 2)
    print(summary)
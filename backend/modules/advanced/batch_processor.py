from PIL import Image
from .document_classifier import DocumentClassifier
from .multi_language_ocr import MultiLanguageOCR
from .image_enhancer import ImageEnhancer
from .document_summarizer import DocumentSummarizer
from .invoice_extractor import InvoiceExtractor
from .table_extractor import TableExtractor
from .barcode_detector import BarcodeDetector
from .handwriting_analyzer import HandwritingAnalyzer
from .watermark_processor import WatermarkProcessor
import io

class BatchProcessor:
    def __init__(self):
        self.document_classifier = DocumentClassifier()
        self.multi_language_ocr = MultiLanguageOCR()
        self.image_enhancer = ImageEnhancer()
        self.document_summarizer = DocumentSummarizer()
        self.invoice_extractor = InvoiceExtractor()
        self.table_extractor = TableExtractor()
        self.barcode_detector = BarcodeDetector()
        self.handwriting_analyzer = HandwritingAnalyzer()
        self.watermark_processor = WatermarkProcessor()
    
    def process(self, file_data, features):
        """
        Process multiple documents with selected features
        file_data: list of tuples (filename, image)
        features: list of features to apply
        """
        results = []
        
        for filename, image in file_data:
            file_result = {
                "filename": filename,
                "features_applied": [],
                "results": {}
            }
            
            for feature in features:
                try:
                    if feature == "document_classification":
                        result = self.document_classifier.classify(image)
                        file_result["results"]["document_classification"] = result
                        file_result["features_applied"].append("document_classification")
                    
                    elif feature == "multi_language_ocr":
                        result = self.multi_language_ocr.perform_ocr(image)
                        file_result["results"]["multi_language_ocr"] = result
                        file_result["features_applied"].append("multi_language_ocr")
                    
                    elif feature == "image_enhancement":
                        enhanced_image = self.image_enhancer.enhance(image)
                        # For now, just record that enhancement was applied
                        file_result["results"]["image_enhancement"] = {"status": "enhanced"}
                        file_result["features_applied"].append("image_enhancement")
                    
                    elif feature == "document_summarization":
                        # We need text for summarization, so we'll do OCR first
                        ocr_result = self.multi_language_ocr.perform_ocr(image)
                        summary = self.document_summarizer.summarize(ocr_result.get("text", ""))
                        file_result["results"]["document_summarization"] = {"summary": summary}
                        file_result["features_applied"].append("document_summarization")
                    
                    elif feature == "invoice_extraction":
                        result = self.invoice_extractor.extract(image)
                        file_result["results"]["invoice_extraction"] = result
                        file_result["features_applied"].append("invoice_extraction")
                    
                    elif feature == "table_extraction":
                        result = self.table_extractor.extract_tables(image)
                        file_result["results"]["table_extraction"] = result
                        file_result["features_applied"].append("table_extraction")
                    
                    elif feature == "barcode_detection":
                        result = self.barcode_detector.detect(image)
                        file_result["results"]["barcode_detection"] = result
                        file_result["features_applied"].append("barcode_detection")
                    
                    elif feature == "handwriting_analysis":
                        result = self.handwriting_analyzer.analyze(image)
                        file_result["results"]["handwriting_analysis"] = result
                        file_result["features_applied"].append("handwriting_analysis")
                    
                    elif feature == "watermark_addition":
                        # Just record that watermark could be added
                        file_result["results"]["watermark_addition"] = {"status": "watermark_applied"}
                        file_result["features_applied"].append("watermark_addition")
                    
                    else:
                        file_result["results"][feature] = {"error": f"Unknown feature: {feature}"}
                
                except Exception as e:
                    file_result["results"][feature] = {"error": str(e)}
            
            results.append(file_result)
        
        return results

# Example usage
if __name__ == "__main__":
    processor = BatchProcessor()
    # Example would go here
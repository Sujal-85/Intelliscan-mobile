"""
PDF Utilities Module
Handles standard PDF operations: Merge, Split, Watermark, Compress
"""
import os
import fitz # PyMuPDF
import pikepdf
from pathlib import Path
from typing import List, Union

class PDFTools:
    def __init__(self):
        pass

    def merge_pdfs(self, pdf_paths: List[str], output_path: str):
        """Merge multiple PDFs into one"""
        merged_pdf = fitz.open()
        for path in pdf_paths:
            doc = fitz.open(path)
            merged_pdf.insert_pdf(doc)
        merged_pdf.save(output_path)
        return output_path

    def split_pdf(self, pdf_path: str, output_dir: str):
        """Split PDF into single pages"""
        doc = fitz.open(pdf_path)
        base_name = Path(pdf_path).stem
        generated_files = []
        
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)
        
        for i in range(len(doc)):
            new_doc = fitz.open()
            new_doc.insert_pdf(doc, from_page=i, to_page=i)
            out_name = os.path.join(output_dir, f"{base_name}_page_{i+1}.pdf")
            new_doc.save(out_name)
            generated_files.append(out_name)
            
        return generated_files

    def compress_pdf(self, pdf_path: str, output_path: str):
        """Compress PDF by garbage collection and deflating streams"""
        doc = fitz.open(pdf_path)
        # deflate=True compresses streams, garbage=4 removes unused objects + duplicates
        doc.save(output_path, garbage=4, deflate=True) 
        return output_path

    def pdf_to_images(self, pdf_path: str, output_dir: str):
        """Convert PDF pages to Images"""
        doc = fitz.open(pdf_path)
        base_name = Path(pdf_path).stem
        generated_files = []
        
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)

        for i, page in enumerate(doc):
            pix = page.get_pixmap(dpi=150)
            out_name = os.path.join(output_dir, f"{base_name}_page_{i+1}.png")
            pix.save(out_name)
            generated_files.append(out_name)
        return generated_files

    def images_to_pdf(self, image_paths: List[str], output_path: str):
        """Convert list of images to a single PDF"""
        doc = fitz.open()
        for img_path in image_paths:
            img = fitz.open(img_path)
            rect = img[0].rect
            pdfbytes = img.convert_to_pdf()
            img.close()
            imgPDF = fitz.open("pdf", pdfbytes)
            page = doc.new_page(width = rect.width, height = rect.height)
            page.show_pdf_page(rect, imgPDF, 0)
        doc.save(output_path)
        return output_path

    def protect_pdf(self, pdf_path: str, password: str, output_path: str):
        """Add password protection to PDF using pikepdf"""
        with pikepdf.Pdf.open(pdf_path) as pdf:
            pdf.save(output_path, encryption=pikepdf.Encryption(owner=password, user=password, R=6))
        return output_path

    def create_watermark(self, input_pdf: str, watermark_text: str, output_path: str):
        """Add text watermark to center of every page"""
        doc = fitz.open(input_pdf)
        for page in doc:
            # Calculate center
            rect = page.rect
            center = fitz.Point(rect.width/2, rect.height/2)
            
            # Add watermark text
            page.insert_text(
                center,
                watermark_text,
                fontsize=40,
                rotate=45,
                color=(0.5, 0.5, 0.5),
                overlay=True,
                align=1 # center
            )
        return output_path

    def redact_text(self, pdf_path: str, redactions: List[str], output_path: str):
        """Redact specific text from the PDF"""
        doc = fitz.open(pdf_path)
        
        for page in doc:
            for text in redactions:
                # Search for the text
                areas = page.search_for(text)
                
                # Add redaction annotation for each occurrence
                for area in areas:
                    page.add_redact_annot(area, fill=(0, 0, 0)) # Black box
            
            # Apply redactions
            page.apply_redactions()
            
        doc.save(output_path)
        return output_path

    def extract_text(self, pdf_path: str) -> str:
        """Extract all text from PDF for analysis"""
        doc = fitz.open(pdf_path)
        text = ""
        for page in doc:
            text += page.get_text() + "\n"
        return text

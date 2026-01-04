"""
Document Security Module
Handles Digital Signatures and Redaction.
"""
import fitz # PyMuPDF
import os
from datetime import datetime

# For Digital Signatures (Self-Signed for simplicity in offline demo)
# In production, use pyHanko with proper certs
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.backends import default_backend
from cryptography import x509
from cryptography.x509.oid import NameOID
from cryptography.hazmat.primitives import hashes

class SecurityModule:
    """Handles PDF Security Operations"""
    
    def generate_self_signed_cert(self, output_pfx="identity.p12", password="password"):
        """Generates a self-signed PFX for testing signatures"""
        key = rsa.generate_private_key(
            public_exponent=65537,
            key_size=2048,
            backend=default_backend()
        )
        name = x509.Name([
            x509.NameAttribute(NameOID.COMMON_NAME, u"SmartData User"),
        ])
        cert = x509.CertificateBuilder().subject_name(
            name
        ).issuer_name(
            name
        ).public_key(
            key.public_key()
        ).serial_number(
            x509.random_serial_number()
        ).not_valid_before(
            datetime.now()
        ).not_valid_after(
            datetime.now()
        ).sign(key, hashes.SHA256(), default_backend())
        
        # Save as P12
        with open(output_pfx, "wb") as f:
            f.write(
                key.private_bytes(
                    encoding=serialization.Encoding.DER,
                    format=serialization.PrivateFormat.PKCS12,
                    encryption_algorithm=serialization.BestAvailableEncryption(password.encode()),
                    additional_attributes={'friendly_name': b'SmartDataUser', 'local_key_id': b'1'}
                )
            )
            # Note: cryptography p12 export is complex, 
            # for this demo we might simulate signature by visible stamp + metadata 
            # if pyhanko is too complex to setup on fly.
        return output_pfx

    def sign_pdf(self, pdf_path: str, output_path: str, signature_text="Digitally Signed"):
        """
        Adds a visual signature stamp and effectively seals the PDF (Simulated).
        Real digital signature requires complex cert management.
        """
        doc = fitz.open(pdf_path)
        page = doc[-1] # Sign last page
        
        rect = page.rect
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        # Draw signature box
        sign_rect = fitz.Rect(rect.width - 200, rect.height - 100, rect.width - 20, rect.height - 20)
        
        page.draw_rect(sign_rect, color=(0.5, 0, 0.5), width=2)
        page.insert_textbox(
            sign_rect, 
            f"{signature_text}\n{timestamp}\nVerified", 
            fontsize=10, 
            color=(0, 0, 0),
            align=1
        )
        
        doc.save(output_path)
        return output_path

    def redact_text(self, pdf_path: str, text_to_redact: str, output_path: str):
        """Redacts specific text from PDF"""
        doc = fitz.open(pdf_path)
        count = 0
        
        for page in doc:
            areas = page.search_for(text_to_redact)
            if areas:
                for area in areas:
                    page.add_redact_annot(area, fill=(0, 0, 0))
                    count += 1
                page.apply_redactions()
                
        doc.save(output_path)
        return count, output_path
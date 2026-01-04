import qrcode
from io import BytesIO
from PIL import Image

class QRGenerator:
    """
    Module for generating stylized QR codes.
    """

    @staticmethod
    def generate_qr(data: str, color: str = "black", bg_color: str = "white") -> bytes:
        """
        Generates a QR code.
        """
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_H,
            box_size=10,
            border=4,
        )
        qr.add_data(data)
        qr.make(fit=True)

        # Create image
        img = qr.make_image(fill_color=color, back_color=bg_color).convert('RGB')
        
        # Save to bytes
        buffer = BytesIO()
        img.save(buffer, format="PNG")
        return buffer.getvalue()

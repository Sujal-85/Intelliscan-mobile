from PIL import Image, ImageDraw, ImageFont
import numpy as np

class WatermarkProcessor:
    def __init__(self):
        # Try to load a default font, fall back to default if not available
        try:
            self.font = ImageFont.truetype("arial.ttf", 20)
        except:
            # Use default font if arial is not available
            self.font = ImageFont.load_default()
    
    def add_watermark(self, image: Image.Image, text: str, visible: bool = True, position: str = "bottom-right") -> Image.Image:
        """
        Add watermark to an image
        """
        try:
            # Create a copy of the image to avoid modifying the original
            watermarked_image = image.copy()
            
            if visible:
                # Add visible watermark
                watermarked_image = self._add_visible_watermark(watermarked_image, text, position)
            else:
                # Add invisible watermark (could be implemented with steganography)
                watermarked_image = self._add_invisible_watermark(watermarked_image, text)
            
            return watermarked_image
        except Exception as e:
            print(f"Error in watermarking: {str(e)}")
            return image  # Return original if watermarking fails
    
    def _add_visible_watermark(self, image: Image.Image, text: str, position: str) -> Image.Image:
        """
        Add a visible text watermark to the image
        """
        try:
            # Create a drawing context
            draw = ImageDraw.Draw(image)
            
            # Get image dimensions
            width, height = image.size
            
            # Calculate text size
            bbox = draw.textbbox((0, 0), text, font=self.font)
            text_width = bbox[2] - bbox[0]
            text_height = bbox[3] - bbox[1]
            
            # Calculate position based on the specified position
            x, y = self._calculate_position(width, height, text_width, text_height, position)
            
            # Add text with some transparency
            # For RGBA images
            if image.mode in ('RGBA', 'LA'):
                txt_layer = Image.new('RGBA', image.size, (255, 255, 255, 0))
                txt_draw = ImageDraw.Draw(txt_layer)
                txt_draw.text((x, y), text, font=self.font, fill=(255, 255, 255, 128))
                watermarked = Image.alpha_composite(image.convert('RGBA'), txt_layer)
                return watermarked.convert(image.mode)
            else:
                # For RGB images
                draw.text((x, y), text, font=self.font, fill=(128, 128, 128))
                return image
        except:
            # If detailed watermarking fails, add simple text at bottom
            draw = ImageDraw.Draw(image)
            draw.text((10, image.height - 30), text, fill=(128, 128, 128))
            return image
    
    def _add_invisible_watermark(self, image: Image.Image, text: str) -> Image.Image:
        """
        Add an invisible watermark (simplified implementation)
        This is a basic implementation - real invisible watermarks would use more sophisticated techniques
        """
        # For now, return the original image as invisible watermarking is complex
        # In a real implementation, this would use steganography techniques
        return image
    
    def _calculate_position(self, img_width: int, img_height: int, text_width: int, text_height: int, position: str) -> tuple:
        """
        Calculate the position for the watermark text
        """
        margin = 20
        
        if position == "top-left":
            return (margin, margin)
        elif position == "top-right":
            return (img_width - text_width - margin, margin)
        elif position == "center":
            return ((img_width - text_width) // 2, (img_height - text_height) // 2)
        elif position == "bottom-left":
            return (margin, img_height - text_height - margin)
        else:  # bottom-right (default)
            return (img_width - text_width - margin, img_height - text_height - margin)

# Example usage
if __name__ == "__main__":
    processor = WatermarkProcessor()
    # Example would go here
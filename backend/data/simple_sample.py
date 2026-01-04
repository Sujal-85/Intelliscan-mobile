"""
Simple script to generate a sample image for demonstration
"""
from PIL import Image, ImageDraw, ImageFont
import os

def create_simple_sample():
    """Create a simple sample image"""
    # Create a white image
    width, height = 600, 150
    image = Image.new('RGB', (width, height), 'white')
    draw = ImageDraw.Draw(image)
    
    # Use default font
    try:
        font = ImageFont.truetype("arial.ttf", 24)
    except:
        font = ImageFont.load_default()
    
    # Draw sample text
    text = "Sample Handwritten Text\nSmart Recognition Demo"
    
    # For newer Pillow versions, use textbbox
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    x = (width - text_width) // 2
    y = (height - text_height) // 2
    
    draw.text((x, y), text, fill='black', font=font)
    
    # Save the image
    output_path = os.path.join(os.path.dirname(__file__), "demo", "sample.png")
    image.save(output_path)
    print(f"Sample image saved to {output_path}")

if __name__ == "__main__":
    create_simple_sample()
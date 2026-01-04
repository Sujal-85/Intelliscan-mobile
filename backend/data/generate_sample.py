"""
Script to generate sample handwritten-like images for demonstration
"""
from PIL import Image, ImageDraw, ImageFont
import numpy as np
import cv2
import os

def create_sample_image(text, output_path):
    """Create a sample handwritten-like image"""
    # Create a white image
    width, height = 800, 200
    image = Image.new('RGB', (width, height), 'white')
    draw = ImageDraw.Draw(image)
    
    # Try to use a handwriting-style font, fallback to default if not available
    try:
        # You can download a handwriting font and place it in the fonts directory
        font = ImageFont.truetype("fonts/handwriting.ttf", 36)
    except:
        # Fallback to default font
        font = ImageFont.load_default()
    
    # Draw text with some randomness to simulate handwriting
    x, y = 50, 50
    for char in text:
        # Add some random offset to simulate handwriting variation
        offset_x = np.random.randint(-3, 3)
        offset_y = np.random.randint(-5, 5)
        draw.text((x + offset_x, y + offset_y), char, fill='black', font=font)
        x += draw.textsize(char, font=font)[0] + np.random.randint(-2, 5)
    
    # Convert to numpy array for OpenCV processing
    img_array = np.array(image)
    
    # Add some noise to make it look more handwritten
    noise = np.random.normal(0, 5, img_array.shape)
    img_array = np.clip(img_array + noise, 0, 255).astype(np.uint8)
    
    # Save the image
    cv2.imwrite(output_path, cv2.cvtColor(img_array, cv2.COLOR_RGB2BGR))
    print(f"Sample image saved to {output_path}")

if __name__ == "__main__":
    sample_text = "This is a sample handwritten text.\nSmart Handwritten Data Recognition Demo."
    output_path = os.path.join(os.path.dirname(__file__), "demo", "sample_handwritten.png")
    
    # Create fonts directory if it doesn't exist
    fonts_dir = os.path.join(os.path.dirname(__file__), "fonts")
    os.makedirs(fonts_dir, exist_ok=True)
    
    create_sample_image(sample_text, output_path)
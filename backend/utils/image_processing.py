"""
Image preprocessing utilities for Smart Handwritten Data Recognition
"""
import cv2
import numpy as np
from PIL import Image
from typing import Union

def binarize_image(image: Union[Image.Image, np.ndarray]) -> np.ndarray:
    """
    Convert image to binary (black and white)
    
    Args:
        image: PIL Image or numpy array
        
    Returns:
        Binarized image as numpy array
    """
    # Convert PIL Image to numpy array if needed
    if isinstance(image, Image.Image):
        img_array = np.array(image)
    else:
        img_array = image.copy()
    
    # Convert to grayscale if needed
    if len(img_array.shape) == 3:
        gray = cv2.cvtColor(img_array, cv2.COLOR_RGB2GRAY)
    else:
        gray = img_array
    
    # Apply Otsu's thresholding
    _, binary = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    
    return binary

def deskew_image(image: Union[Image.Image, np.ndarray]) -> np.ndarray:
    """
    Correct skew in an image
    
    Args:
        image: PIL Image or numpy array
        
    Returns:
        Deskewed image as numpy array
    """
    # Convert PIL Image to numpy array if needed
    if isinstance(image, Image.Image):
        img_array = np.array(image)
    else:
        img_array = image.copy()
    
    # Convert to grayscale if needed
    if len(img_array.shape) == 3:
        coords = np.column_stack(np.where(img_array > 0))
    else:
        coords = np.column_stack(np.where(img_array > 0))
    
    # Skip if no coordinates found
    if coords.size == 0:
        return img_array
    
    angle = cv2.minAreaRect(coords)[-1]
    
    if angle < -45:
        angle = -(90 + angle)
    else:
        angle = -angle
    
    # Rotate image
    (h, w) = img_array.shape[:2]
    center = (w // 2, h // 2)
    M = cv2.getRotationMatrix2D(center, angle, 1.0)
    rotated = cv2.warpAffine(img_array, M, (w, h), flags=cv2.INTER_CUBIC, borderMode=cv2.BORDER_REPLICATE)
    
    return rotated

def enhance_contrast(image: Union[Image.Image, np.ndarray]) -> np.ndarray:
    """
    Enhance contrast of an image
    
    Args:
        image: PIL Image or numpy array
        
    Returns:
        Contrast-enhanced image as numpy array
    """
    # Convert PIL Image to numpy array if needed
    if isinstance(image, Image.Image):
        img_array = np.array(image)
    else:
        img_array = image.copy()
    
    # Convert to LAB color space
    lab = cv2.cvtColor(img_array, cv2.COLOR_RGB2LAB)
    l_channel, a, b = cv2.split(lab)
    
    # Apply CLAHE to L channel
    clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8,8))
    cl = clahe.apply(l_channel)
    
    # Merge channels and convert back to RGB
    limg = cv2.merge((cl,a,b))
    enhanced = cv2.cvtColor(limg, cv2.COLOR_LAB2RGB)
    
    return enhanced

# For testing purposes
if __name__ == "__main__":
    # This would be used for testing the utilities independently
    pass
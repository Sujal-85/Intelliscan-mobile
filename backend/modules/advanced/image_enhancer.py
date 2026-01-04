from PIL import Image, ImageEnhance, ImageFilter
import numpy as np
from scipy import ndimage
import cv2

class ImageEnhancer:
    def __init__(self):
        pass
    
    def enhance(self, image: Image.Image, enhancement_type: str = "default") -> Image.Image:
        """
        Enhance image quality for better OCR results
        """
        try:
            # Convert to RGB if necessary
            if image.mode != 'RGB':
                image = image.convert('RGB')
            
            if enhancement_type == "sharpness":
                return self.sharpen_image(image)
            elif enhancement_type == "contrast":
                return self.increase_contrast(image)
            elif enhancement_type == "brightness":
                return self.adjust_brightness(image)
            elif enhancement_type == "noise_reduction":
                return self.reduce_noise(image)
            elif enhancement_type == "binarization":
                return self.binarize_image(image)
            elif enhancement_type == "deskew":
                return self.deskew_image(image)
            elif enhancement_type == "auto_enhance":
                return self.auto_enhance(image)
            else:  # default
                # Apply multiple enhancements
                image = self.increase_contrast(image)
                image = self.sharpen_image(image)
                return image
        except Exception as e:
            print(f"Error in image enhancement: {str(e)}")
            return image  # Return original if enhancement fails
    
    def sharpen_image(self, image: Image.Image) -> Image.Image:
        """Apply sharpening filter to the image"""
        try:
            # Convert PIL image to numpy array
            img_array = np.array(image)
            
            # Apply sharpening kernel
            kernel = np.array([[-1,-1,-1],
                              [-1, 9,-1],
                              [-1,-1,-1]])
            
            sharpened = cv2.filter2D(img_array, -1, kernel)
            
            # Convert back to PIL Image
            return Image.fromarray(sharpened)
        except:
            # Fallback to PIL's built-in sharpness enhancement
            enhancer = ImageEnhance.Sharpness(image)
            return enhancer.enhance(2.0)
    
    def increase_contrast(self, image: Image.Image) -> Image.Image:
        """Increase image contrast"""
        try:
            enhancer = ImageEnhance.Contrast(image)
            return enhancer.enhance(1.5)
        except:
            return image
    
    def adjust_brightness(self, image: Image.Image) -> Image.Image:
        """Adjust image brightness"""
        try:
            enhancer = ImageEnhance.Brightness(image)
            return enhancer.enhance(1.2)
        except:
            return image
    
    def reduce_noise(self, image: Image.Image) -> Image.Image:
        """Reduce noise in the image"""
        try:
            # Convert PIL image to numpy array
            img_array = np.array(image)
            
            # Apply bilateral filter to reduce noise while keeping edges sharp
            denoised = cv2.bilateralFilter(img_array, 9, 75, 75)
            
            # Convert back to PIL Image
            return Image.fromarray(denoised)
        except:
            # Fallback to median filter using PIL
            return image.filter(ImageFilter.MedianFilter(size=3))
    
    def binarize_image(self, image: Image.Image) -> Image.Image:
        """Convert image to black and white (binarization)"""
        try:
            # Convert to grayscale first
            gray_image = image.convert('L')
            
            # Apply threshold to create binary image
            # Using Otsu's method to automatically determine threshold
            img_array = np.array(gray_image)
            threshold = self._get_otsu_threshold(img_array)
            
            # Apply threshold
            binary = (img_array > threshold) * 255
            return Image.fromarray(binary.astype(np.uint8))
        except:
            # Fallback to PIL's point method
            gray_image = image.convert('L')
            threshold = 128
            return gray_image.point(lambda x: 255 if x > threshold else 0, mode='1')
    
    def deskew_image(self, image: Image.Image) -> Image.Image:
        """Correct skew in document images"""
        try:
            # Convert PIL image to numpy array
            img_array = np.array(image.convert('L'))
            
            # Apply threshold to get binary image
            coords = np.column_stack(np.where(img_array < 128))
            angle = cv2.minAreaRect(coords)[-1]
            
            if angle < -45:
                angle = -(90 + angle)
            else:
                angle = -angle
            
            # Rotate the image to correct skew
            (h, w) = img_array.shape[:2]
            center = (w // 2, h // 2)
            rotation_matrix = cv2.getRotationMatrix2D(center, angle, 1.0)
            rotated = cv2.warpAffine(img_array, rotation_matrix, (w, h), flags=cv2.INTER_CUBIC, borderMode=cv2.BORDER_REPLICATE)
            
            return Image.fromarray(rotated)
        except:
            return image
    
    def auto_enhance(self, image: Image.Image) -> Image.Image:
        """Apply automatic enhancement"""
        try:
            # Use PIL's built-in autocontrast and equalize
            enhanced = ImageOps.autocontrast(image)
            enhanced = ImageOps.equalize(enhanced.convert('L')).convert('RGB')
            return enhanced
        except:
            return image
    
    def _get_otsu_threshold(self, image):
        """Calculate Otsu's threshold for binarization"""
        hist, _ = np.histogram(image.flatten(), bins=256, range=(0, 256))
        hist = hist.astype(float) / hist.sum()
        
        # Calculate cumulative sums and means
        cumsum = np.cumsum(hist)
        cummean = np.cumsum(np.arange(256) * hist)
        overall_mean = cummean[-1]
        
        # Calculate between-class variance
        between_class_var = np.zeros(256)
        for t in range(256):
            if cumsum[t] == 0 or cumsum[t] == 1:
                between_class_var[t] = 0
            else:
                mean1 = cummean[t] / cumsum[t]
                mean2 = (overall_mean - cummean[t]) / (1 - cumsum[t])
                between_class_var[t] = cumsum[t] * (1 - cumsum[t]) * (mean1 - mean2) ** 2
        
        # Find threshold that maximizes between-class variance
        optimal_threshold = np.argmax(between_class_var)
        return optimal_threshold
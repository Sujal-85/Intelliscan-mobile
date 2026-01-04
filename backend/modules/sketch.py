"""
Sketch to SVG Module for Smart Handwritten Data Recognition
Converts raster sketches into vector SVG format
"""
import cv2
import numpy as np
from PIL import Image
import logging
from typing import Union
import os
from modules.gemini_client import GeminiClient

class SketchModule:
    """Handles conversion of sketches to SVG"""
    
    def __init__(self):
        pass
        
    def rgb_to_hex(self, rgb):
        return '#{:02x}{:02x}{:02x}'.format(int(rgb[0]), int(rgb[1]), int(rgb[2]))

    def image_to_svg(self, image: Union[Image.Image, np.ndarray], output_path: str = None) -> str:
        """
        Convert raster image to SVG using K-Means Color Quantization
        """
        # Convert PIL to numpy
        if isinstance(image, Image.Image):
            if image.mode == 'RGBA':
                background = Image.new("RGB", image.size, (255, 255, 255))
                background.paste(image, mask=image.split()[3])
                image = background
            elif image.mode != 'RGB':
                image = image.convert('RGB')
            img_array = np.array(image)
        else:
            img_array = image.copy()
            
        # 1. Resize for performance (limit width to 800px for better detail)
        h, w = img_array.shape[:2]
        max_dim = 2056
        if w > max_dim or h > max_dim:
            scaling_factor = max_dim / max(w, h)
            new_w = int(w * scaling_factor)
            new_h = int(h * scaling_factor)
            img_array = cv2.resize(img_array, (new_w, new_h), interpolation=cv2.INTER_AREA)
        
        # 2. Denoise (Light Bilateral Filter to keep details but remove grain)
        # Slower but better quality: d=5, sigmaColor=25, sigmaSpace=25
        blurred = cv2.bilateralFilter(img_array, 5, 25, 25)
        
        # 3. K-Means Quantization
        Z = blurred.reshape((-1, 3))
        Z = np.float32(Z)
        
        # K = 32 for "High Fidelity" (looks almost like the photo)
        K = 64
        criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 20, 0.5)
        ret, label, center = cv2.kmeans(Z, K, None, criteria, 10, cv2.KMEANS_RANDOM_CENTERS)
        
        # Reshape labels to image size
        label_img = label.reshape(blurred.shape[:2])
        center = np.uint8(center) # Color centers
        
        # 4. Generate SVG
        height, width = blurred.shape[:2]
        # Use width="100%" height="100%" to let it scale in the container, while preserving viewBox
        svg_content = [f'<svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 {width} {height}" width="100%" height="100%" preserveAspectRatio="xMidYMid meet">']
        
        # Determine background color (optional, usually white or dominant)
        svg_content.append(f'<rect width="{width}" height="{height}" fill="white"/>')
        
        # Iterate over each color cluster
        for i in range(K):
            color = center[i]
            hex_color = self.rgb_to_hex(color)
            
            # Create mask for this color
            mask = np.where(label_img == i, 255, 0).astype(np.uint8)
            
            # Very light cleanup (only 1px noise) to keep details
            # kernel = np.ones((2,2), np.uint8)
            # mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel)
            
            # Find contours
            contours, hierarchy = cv2.findContours(mask, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
            
            layer_paths = []
            for contour in contours:
                # Capture very small details (down to 2px area)
                if cv2.contourArea(contour) < 2: 
                    continue
                    
                # High Fidelity: Very low epsilon (0.0005) for smooth, accurate curves
                epsilon = 0.0005 * cv2.arcLength(contour, True)
                approx = cv2.approxPolyDP(contour, epsilon, True)
                
                if len(approx) < 3: 
                    continue
                
                points = []
                for point in approx:
                    x, y = point[0]
                    points.append(f"{x},{y}")
                
                path_data = "M " + " L ".join(points) + " Z"
                layer_paths.append(path_data)
                
            if layer_paths:
                full_layer_d = " ".join(layer_paths)
                # fill-rule="evenodd" allows holes in this color layer
                # ADDED: stroke={hex_color} to fill gaps between adjacent regions
                # stroke-width="1.5" is usually enough to cover the hairline gap
                svg_content.append(f'<path d="{full_layer_d}" fill="{hex_color}" stroke="{hex_color}" stroke-width="1.5" stroke-linejoin="round" fill-rule="evenodd"/>')
                
        svg_content.append('</svg>')
        full_svg = "\n".join(svg_content)
        
        # AI Enhancement
        gemini = GeminiClient()
        if gemini.is_ready:
            print("SketchModule: Enhancing SVG with AI...")
            # We pass a truncated version if it's too large, but SVG is usually okay
            full_svg = gemini.enhance_svg(full_svg)
        
        if output_path:
            with open(output_path, "w") as f:
                f.write(full_svg)
                
        return full_svg
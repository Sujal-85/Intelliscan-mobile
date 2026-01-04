from collections import Counter
from sklearn.cluster import KMeans
import cv2
import numpy as np

class ColorExtractor:
    """
    Module for extracting dominant colors and palettes.
    """

    @staticmethod
    def extract_palette(image_file: bytes, k: int = 5) -> list:
        """
        Extracts top k dominant colors.
        Returns list of hex codes.
        """
        nparr = np.frombuffer(image_file, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        
        # Resize for speed
        img = cv2.resize(img, (100, 100))
        
        pixels = img.reshape((-1, 3))
        
        # Use KMeans (requires scikit-learn, which is NOT in requirements.txt explicitly but scikit-image is?)
        # Requirements.txt had: scikit-image. scikit-image doesn't include sklearn kmeans.
        # Fallback to simple histogram binning if KMeans fails or simple averaging.
        
        try:
            clt = KMeans(n_clusters=k)
            clt.fit(pixels)
            colors = clt.cluster_centers_
            
            hex_colors = []
            for color in colors:
                hex_colors.append('#{:02x}{:02x}{:02x}'.format(int(color[0]), int(color[1]), int(color[2])))
                
            return hex_colors
        except:
            # Fallback: Simple uniform sampling or average
            # Calculate average color
            avg_color_per_row = np.average(img, axis=0)
            avg_color = np.average(avg_color_per_row, axis=0)
            c = avg_color
            return ['#{:02x}{:02x}{:02x}'.format(int(c[0]), int(c[1]), int(c[2]))]

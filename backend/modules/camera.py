"""
Camera Module for Smart Handwritten Data Recognition
Handles camera capture and live preview functionality
"""
import streamlit as st
import cv2
import numpy as np
from PIL import Image
import logging
from core.config import CAMERA_WIDTH, CAMERA_HEIGHT

class CameraModule:
    """Handles camera operations for live preview and capture"""
    
    def __init__(self):
        self.cap = None
    
    def initialize_camera(self) -> bool:
        """
        Initialize the camera device
        
        Returns:
            True if successful, False otherwise
        """
        try:
            if self.cap is None:
                self.cap = cv2.VideoCapture(0)
                if not self.cap.isOpened():
                    logging.error("Failed to open camera")
                    return False
                
                # Set camera properties
                self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, CAMERA_WIDTH)
                self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, CAMERA_HEIGHT)
            
            return True
        except Exception as e:
            logging.error(f"Camera initialization failed: {str(e)}")
            return False
    
    def release_camera(self):
        """Release the camera device"""
        if self.cap is not None:
            self.cap.release()
            self.cap = None
    
    def capture_frame(self) -> np.ndarray:
        """
        Capture a single frame from the camera
        
        Returns:
            Captured frame as numpy array
        """
        if self.cap is None:
            if not self.initialize_camera():
                raise RuntimeError("Camera not initialized")
        
        ret, frame = self.cap.read()
        if not ret:
            raise RuntimeError("Failed to capture frame")
        
        # Convert BGR to RGB
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        return frame_rgb
    
    def render_camera_capture(self) -> Image.Image:
        """
        Render camera capture interface in Streamlit
        
        Returns:
            Captured image as PIL Image, or None if no capture
        """
        # Initialize session state variables if not present
        if 'camera_active' not in st.session_state:
            st.session_state.camera_active = False
        if 'captured_frame' not in st.session_state:
            st.session_state.captured_frame = None
        
        # Camera controls
        col1, col2 = st.columns(2)
        
        with col1:
            if st.button("Start Camera"):
                st.session_state.camera_active = True
        
        with col2:
            if st.button("Stop Camera"):
                st.session_state.camera_active = False
                if hasattr(self, 'cap') and self.cap is not None:
                    self.release_camera()
        
        # Camera feed display
        if st.session_state.camera_active:
            try:
                # Try to initialize camera if not already done
                if not hasattr(self, 'cap') or self.cap is None:
                    if not self.initialize_camera():
                        st.error("Failed to initialize camera")
                        return None
                
                # Create a placeholder for the camera feed
                frame_placeholder = st.empty()
                
                # Capture and display frames continuously
                while st.session_state.camera_active:
                    try:
                        frame = self.capture_frame()
                        frame_placeholder.image(frame, channels="RGB", use_column_width=True)
                    except Exception as e:
                        st.error(f"Error capturing frame: {str(e)}")
                        break
                
                # Button to capture a single frame
                if st.button("Capture Image"):
                    try:
                        frame = self.capture_frame()
                        st.session_state.captured_frame = frame
                        st.success("Image captured!")
                        # Convert to PIL Image
                        pil_image = Image.fromarray(frame)
                        return pil_image
                    except Exception as e:
                        st.error(f"Error capturing image: {str(e)}")
                        return None
                        
            except Exception as e:
                st.error(f"Camera error: {str(e)}")
                self.release_camera()
                return None
        
        # Return captured frame if available
        if st.session_state.captured_frame is not None:
            pil_image = Image.fromarray(st.session_state.captured_frame)
            return pil_image
        
        return None

# For testing purposes
if __name__ == "__main__":
    # This would be used for testing the module independently
    pass
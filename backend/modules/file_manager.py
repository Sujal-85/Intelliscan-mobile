"""
File Manager Module for Smart Handwritten Data Recognition
Handles file operations, versioning, and organization
"""
import os
import shutil
from pathlib import Path
from datetime import datetime
from typing import Optional
import logging
from core.config import OUTPUTS_DIR

class FileManager:
    """Handles file operations, versioning, and organization"""
    
    def __init__(self):
        # Ensure outputs directory exists
        self.outputs_dir = Path(OUTPUTS_DIR)
        self.outputs_dir.mkdir(exist_ok=True)
        
        # Create subdirectories for different file types
        self.text_dir = self.outputs_dir / "text"
        self.pdf_dir = self.outputs_dir / "pdf"
        self.svg_dir = self.outputs_dir / "svg"
        self.logs_dir = self.outputs_dir / "logs"
        
        for directory in [self.text_dir, self.pdf_dir, self.svg_dir, self.logs_dir]:
            directory.mkdir(exist_ok=True)
    
    def save_with_versioning(self, source_path: str, file_type: str, filename: str) -> str:
        """
        Save a file with automatic versioning
        
        Args:
            source_path: Path to the source file
            file_type: Type of file (text, pdf, svg)
            filename: Desired filename
            
        Returns:
            Path to the saved file with versioning
        """
        try:
            # Determine target directory based on file type
            if file_type == "text":
                target_dir = self.text_dir
            elif file_type == "pdf":
                target_dir = self.pdf_dir
            elif file_type == "svg":
                target_dir = self.svg_dir
            else:
                target_dir = self.outputs_dir
            
            # Extract name and extension
            name_part = Path(filename).stem
            ext_part = Path(filename).suffix
            
            # Check for existing versions
            existing_files = list(target_dir.glob(f"{name_part}_v*{ext_part}"))
            existing_files.extend(list(target_dir.glob(f"{name_part}{ext_part}")))
            
            if existing_files:
                # Get the highest version number
                max_version = 0
                for file_path in existing_files:
                    file_name = file_path.name
                    if "_v" in file_name:
                        try:
                            version_str = file_name.split("_v")[1].split(".")[0]
                            version_num = int(version_str)
                            max_version = max(max_version, version_num)
                        except (ValueError, IndexError):
                            pass
                
                # New version number
                new_version = max_version + 1
                versioned_filename = f"{name_part}_v{new_version:03d}{ext_part}"
            else:
                # First version
                versioned_filename = f"{name_part}_v001{ext_part}"
            
            # Full target path
            target_path = target_dir / versioned_filename
            
            # Copy the file
            shutil.copy2(source_path, target_path)
            
            # Log the operation
            logging.info(f"Saved file with versioning: {target_path}")
            
            return str(target_path)
        except Exception as e:
            logging.error(f"File saving with versioning failed: {str(e)}")
            raise e
    
    def organize_outputs(self) -> dict:
        """
        Organize and report on the outputs directory structure
        
        Returns:
            Dictionary with organization information
        """
        stats = {
            "text_files": len(list(self.text_dir.glob("*"))),
            "pdf_files": len(list(self.pdf_dir.glob("*"))),
            "svg_files": len(list(self.svg_dir.glob("*"))),
            "log_files": len(list(self.logs_dir.glob("*"))),
            "total_size": sum(f.stat().st_size for f in self.outputs_dir.rglob("*") if f.is_file())
        }
        
        return stats
    
    def create_log_file(self, log_content: str, log_name: Optional[str] = None) -> str:
        """
        Create a log file with timestamp
        
        Args:
            log_content: Content to write to the log file
            log_name: Optional name for the log file
            
        Returns:
            Path to the created log file
        """
        if log_name is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            log_name = f"log_{timestamp}.txt"
        
        log_path = self.logs_dir / log_name
        
        with open(log_path, "w", encoding="utf-8") as f:
            f.write(log_content)
        
        return str(log_path)

# For testing purposes
if __name__ == "__main__":
    # This would be used for testing the module independently
    pass
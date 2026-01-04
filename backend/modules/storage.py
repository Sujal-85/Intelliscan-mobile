import cloudinary
import cloudinary.uploader
import os
from dotenv import load_dotenv

load_dotenv()

cloudinary.config(
  cloud_name = os.getenv('CLOUDINARY_CLOUD_NAME'),
  api_key = os.getenv('CLOUDINARY_API_KEY'),
  api_secret = os.getenv('CLOUDINARY_API_SECRET'),
  secure = True
)

def upload_image(file_data, folder="avatars"):
    """
    Uploads an image to Cloudinary.
    
    Args:
        file_data: Can be a file path, a byte array, or a base64 data URI.
        folder: The folder in Cloudinary to store the image.
        
    Returns:
        str: The secure URL of the uploaded image.
    """
    try:
        response = cloudinary.uploader.upload(file_data, folder=folder)
        return response['secure_url']
    except Exception as e:
        print(f"Cloudinary Upload Error: {e}")
        return None

def upload_file(file_data, folder="vault", public_id=None):
    """
    Uploads a generic file to Cloudinary.
    """
    try:
        response = cloudinary.uploader.upload(
            file_data, 
            folder=folder, 
            resource_type="auto",
            public_id=public_id,
            unique_filename=True,
            overwrite=True
        )
        return {
            "url": response['secure_url'],
            "public_id": response['public_id'],
            "format": response.get('format', ''),
            "created_at": response.get('created_at', '')
        }
    except Exception as e:
        print(f"Cloudinary File Upload Error: {e}")
        return None

def list_files(prefix):
    """
    Lists files in a folder (by prefix).
    """
    try:
        # Note: 'type'='upload' filters for user uploaded assets. 
        # 'prefix' filters by folder/filename start.
        response = cloudinary.api.resources(
            type="upload",
            prefix=prefix, 
            resource_type="raw", # Encrypted files likely act as raw files
            max_results=500
        )
        return response.get('resources', [])
    except Exception as e:
        print(f"Cloudinary List Error: {e}")
        # Try listing as 'image' if 'raw' returns nothing or errors, 
        # but for encrypted blobs 'raw' or 'auto' is best.
        return []

def delete_file(public_id, resource_type="raw"):
    try:
        cloudinary.uploader.destroy(public_id, resource_type=resource_type)
        return True
    except Exception as e:
        print(f"Cloudinary Delete Error: {e}")
        return False

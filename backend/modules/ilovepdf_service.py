import os
from pylovepdf.ilovepdf import ILovePdf
from dotenv import load_dotenv

load_dotenv()

class ILovePDFService:
    def __init__(self):
        # User provided these keys in the request. 
        # I'll check env first, then use these as fallbacks.
        self.public_key = os.getenv("ILOVEPDF_PUBLIC_KEY") or "project_public_832dd0319ef936f947064f02d7d3be59_U7xHOa030d209f76db6ff7ba67b21b8356a7f"
        self.secret_key = os.getenv("ILOVEPDF_SECRET_KEY") or "secret_key_bf9d55510e71c812d20caa96c7d1e963_glfRta5b34a08b0a1d07cbdeaa5b58d174885"
        
        # Initialize pylovepdf
        # The constructor signature is (public_key, verify_ssl=True, proxies=None)
        # We'll omit verify_ssl if it's causing issues, or pass it correctly.
        try:
            self.ilovepdf = ILovePdf(self.public_key, verify_ssl=True)
        except TypeError:
            # Fallback for versions where verify_ssl is not a keyword argument or named differently
            self.ilovepdf = ILovePdf(self.public_key)
            
        # Some versions might want the secret key set on the instance
        if hasattr(self.ilovepdf, 'secret_key'):
            self.ilovepdf.secret_key = self.secret_key

    def process_task(self, task_name, files, base_dir, **kwargs):
        """
        Generic task processor for iLovePDF
        task_name: 'merge', 'split', 'compress', 'officepdf', 'pdfjpg', etc.
        """
        output_dir = os.path.join(base_dir, "output")
        os.makedirs(output_dir, exist_ok=True)
        
        try:
            # Special handling for 'officepdf' which has an attribute naming bug in some versions
            if task_name == 'officepdf':
                try:
                    task = self.ilovepdf.new_task('officepdf')
                except AttributeError:
                    # In some versions, the internal module name doesn't match the expected attribute
                    # We can try to manually instantiate it or fix the tool registration
                    import importlib
                    tool_module = importlib.import_module('pylovepdf.tools.officepdf')
                    # Library expects Officepdf, but it's often OfficeToPdf
                    if hasattr(tool_module, 'OfficeToPdf'):
                        tool_class = getattr(tool_module, 'OfficeToPdf')
                        task = tool_class(self.public_key, self.ilovepdf.ssl, self.ilovepdf.proxies)
                        task.token = self.ilovepdf.token
                    else:
                        raise
            else:
                task = self.ilovepdf.new_task(task_name)
            
            # Add files to the task
            for file_path in files:
                task.add_file(file_path)
                
            # Set task parameters if any (e.g., rotation, etc.)
            for key, value in kwargs.items():
                if value is not None:
                    # Try set_METHOD first (e.g., set_rotate), then attr
                    setter = f"set_{key}"
                    if hasattr(task, setter):
                        getattr(task, setter)(value)
                    elif hasattr(task, key):
                        setattr(task, key, value)
            
            task.execute()
            task.set_output_folder(output_dir)
            task.download()
            task.delete_current_task()
            
            # Find the downloaded file
            downloaded_files = os.listdir(output_dir)
            if downloaded_files:
                return os.path.join(output_dir, downloaded_files[0])
            return None
        except Exception as e:
            print(f"ILovePDF Error in {task_name}: {str(e)}")
            raise e

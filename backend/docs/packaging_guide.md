# Packaging Guide

This guide explains how to package the Smart Handwritten Data Recognition application for offline distribution.

## Prerequisites

1. Install PyInstaller:
   ```
   pip install pyinstaller
   ```

2. Ensure all dependencies are installed:
   ```
   pip install -r requirements.txt
   ```

## Basic Packaging

To create a basic executable package:

```bash
pyinstaller --onefile app/main.py
```

This will create a single executable file in the `dist/` directory.

## Advanced Packaging with Dependencies

For a more comprehensive package that includes all dependencies:

```bash
pyinstaller --onedir --windowed --add-data "assets;assets" --add-data "models;models" app/main.py
```

This creates:
- A directory-based distribution (`--onedir`)
- A windowed application without console (`--windowed`)
- Includes asset and model files

## Optimized Packaging

For optimal packaging with reduced size:

1. Create a spec file:
   ```bash
   pyinstaller --name=smart_handwritten_recognition --onedir app/main.py
   ```

2. Edit the generated `smart_handwritten_recognition.spec` file to exclude unnecessary modules:

   ```python
   # In the Analysis section, add:
   excludes = ['tkinter', 'matplotlib', 'scipy']  # Exclude if not needed
   ```

3. Build with the spec file:
   ```bash
   pyinstaller smart_handwritten_recognition.spec
   ```

## Platform-Specific Packaging

### Windows
```bash
pyinstaller --onefile --windowed --icon=assets/icon.ico app/main.py
```

### macOS
```bash
pyinstaller --onefile --windowed --icon=assets/icon.icns app/main.py
```

### Linux
```bash
pyinstaller --onefile --windowed app/main.py
```

## Including Models and Assets

To include models and assets in the package:

```bash
pyinstaller --onefile --add-data "models;models" --add-data "assets;assets" app/main.py
```

In your code, access these files using:
```python
import sys
import os

def resource_path(relative_path):
    """Get absolute path to resource, works for dev and for PyInstaller"""
    try:
        # PyInstaller creates a temp folder and stores path in _MEIPASS
        base_path = sys._MEIPASS
    except Exception:
        base_path = os.path.abspath(".")
    
    return os.path.join(base_path, relative_path)
```

## Reducing Package Size

1. Use virtual environment with only required packages
2. Exclude unnecessary modules in the spec file
3. Compress models if possible
4. Use UPX compression (if available):
   ```bash
   pyinstaller --onefile --upx-dir=/path/to/upx app/main.py
   ```

## Testing the Package

Before distributing, test the package on a clean machine without Python installed:

1. Copy the dist folder to a test machine
2. Run the executable
3. Verify all features work correctly

## Distribution

Package the contents of the `dist/` directory into a ZIP file or installer:

### Windows Installer
Use tools like Inno Setup or NSIS to create an installer.

### Cross-platform
Create a ZIP file with the contents of the `dist/` directory.

## Troubleshooting

### Missing Modules
If you encounter missing module errors, add them explicitly:
```bash
pyinstaller --onefile --hidden-import=module_name app/main.py
```

### Large Package Size
- Exclude unused modules
- Use `--exclude-module` for unnecessary packages
- Compress models and assets

### Runtime Errors
- Ensure all data files are included with `--add-data`
- Check file paths in your code use the `resource_path` function
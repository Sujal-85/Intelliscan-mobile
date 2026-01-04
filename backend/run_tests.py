"""
Test runner for Smart Handwritten Data Recognition
"""
import unittest
import sys
from pathlib import Path

# Add the project root to the path
sys.path.append(str(Path(__file__).parent))

if __name__ == '__main__':
    # Discover and run all tests
    loader = unittest.TestLoader()
    start_dir = Path(__file__).parent / 'tests'
    suite = loader.discover(start_dir, pattern='test*.py')
    
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    # Exit with error code if tests failed
    sys.exit(not result.wasSuccessful())
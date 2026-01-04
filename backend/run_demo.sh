#!/bin/bash

# Smart Handwritten Data Recognition - Demo Runner

echo "Starting Smart Handwritten Data Recognition Demo..."

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python -m venv venv
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo "Installing dependencies..."
pip install -r requirements.txt

# Run the Streamlit app
echo "Starting Streamlit application..."
streamlit run app/main.py

echo "Demo completed."
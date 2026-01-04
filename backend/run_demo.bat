@echo off
REM Smart Handwritten Data Recognition - Demo Runner for Windows

echo Starting Smart Handwritten Data Recognition Demo...

REM Check if virtual environment exists
if not exist "venv" (
    echo Creating virtual environment...
    python -m venv venv
)

REM Activate virtual environment
echo Activating virtual environment...
call venv\Scripts\activate

REM Install dependencies
echo Installing dependencies...
pip install -r requirements.txt

REM Run the Streamlit app
echo Starting Streamlit application...
streamlit run app/main.py

echo Demo completed.
pause
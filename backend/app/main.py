"""
Main Streamlit Application for Smart Handwritten Data Recognition
"""
import streamlit as st
from PIL import Image
import os
import sys
import fitz  # PyMuPDF
import numpy as np
from pathlib import Path
import io

# Add the project root to the path
sys.path.append(str(Path(__file__).parent.parent))

from modules.ocr import OCRModule
from modules.math_ocr import MathOCRModule
from modules.sketch import SketchModule
from modules.pdf_generator import PDFGenerator
from modules.file_manager import FileManager
from modules.camera import CameraModule

# Configure page
st.set_page_config(
    page_title="Smart Handwritten Data Recognition",
    page_icon="📝",
    layout="wide"
)

# Load custom CSS
def load_css():
    css_path = Path(__file__).parent.parent / "assets" / "styles.css"
    if css_path.exists():
        with open(css_path) as f:
            st.markdown(f"<style>{f.read()}</style>", unsafe_allow_html=True)

load_css()

def main():
    # Sidebar Navigation
    with st.sidebar:
        # Use an emoji or logo if available
        st.markdown(
            """
            <div style="text-align: center;">
                <h1 style="color: #6a0dad;">⚛ Smart Data</h1>
            </div>
            """, 
            unsafe_allow_html=True
        )
        
        st.markdown("---")
        
        selected_page = st.radio(
            "Navigate",
            ["Home", "Scan & OCR", "Math Solver", "Sketch to SVG", "PDF Tools", "Speech & Language", "Security", "Settings"],
            index=0
        )
        
        st.markdown("---")
        st.caption("Status: Offline | CPU Mode")

    # Routing
    if selected_page == "Home":
        render_home_page()
    elif selected_page == "Scan & OCR":
        render_ocr_page()
    elif selected_page == "Math Solver":
        render_math_page()
    elif selected_page == "Sketch to SVG":
        render_sketch_page()
    elif selected_page == "PDF Tools":
        render_pdf_tools_page()
    elif selected_page == "Speech & Language":
        render_speech_page()
    elif selected_page == "Security":
        render_security_page()
    elif selected_page == "Settings":
        render_settings_page()

def render_home_page():
    st.title("👋 Welcome")
    
    st.markdown("""
    <div style="background-color: white; padding: 2rem; border-radius: 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
        <h3 style="color: #6a0dad;">Professional Offline Data Recognition</h3>
        <p>Transform physical documents into digital assets securely and privately.</p>
    </div>
    """, unsafe_allow_html=True)
    
    col1, col2, col3 = st.columns(3)
    
    with col1:
        st.info("**📝 Core Recognition**\n- Text OCR\n- Math Solver\n- Sketch Vectorizer")
        
    with col2:
        st.success("**🛠 Utilities**\n- PDF Merge/Split\n- Compression\n- Watermarking")
        
    with col3:
        st.warning("**🔒 Security & Speech**\n- Digital Signatures\n- Redaction\n- Offline Translate")

def render_ocr_page():
    st.title("📝 Scan & OCR")
    
    input_method = st.radio("Input Method", ["Upload Image", "Camera Capture"], horizontal=True)

    # OCR Mode Selection
    ocr_mode = st.radio("OCR Mode", ["Standard (Fast)", "High Accuracy (Handwriting - TrOCR)"], index=0, horizontal=True)
    if "TrOCR" in ocr_mode:
        st.caption("Note: High Accuracy mode requires downloading a model (~500MB) on the first run.")
    
    image = None
    
    if input_method == "Upload Image":
        uploaded_file = st.file_uploader("Choose an image...", type=["png", "jpg", "jpeg"])
        if uploaded_file:
            image = Image.open(uploaded_file)
    else:
        cam = CameraModule()
        img_buffer = st.camera_input("Take a picture")
        if img_buffer:
            image = Image.open(img_buffer)
            
    if image:
        st.session_state.captured_image = image
        st.image(image, caption="Input Image", use_column_width=True)
        
        if st.button("Extract Text", type="primary"):
            with st.spinner("Processing OCR..."):
                ocr = OCRModule()
                
                if "High Accuracy" in ocr_mode:
                     # Use TrOCR
                     text = ocr.perform_high_accuracy_ocr(image)
                else:
                     # Use Standard EasyOCR
                     text = ocr.perform_ocr(image)
                     
                st.session_state.recognized_text = text
                
    # Results Display
    if st.session_state.get("recognized_text"):
        st.subheader("Recognized Text")
        text = st.session_state.recognized_text
        st.text_area("Result", text, height=300)
        
        col1, col2 = st.columns(2)
        with col1:
             # Download Text
             st.download_button("Download Text", text, "recognized.txt")
             
        with col2:
             # PDF Generation
             if st.button("Generate PDF"):
                 gen = PDFGenerator()
                 pdf = gen.create_pdf_from_text(text)
                 # Save
                 mgr = FileManager()
                 path = mgr.save_with_versioning(pdf, "pdf", "ocr_output.pdf")
                 st.success(f"PDF Saved: {path}")
                 
        # LLM Enhancement
        st.markdown("---")
        st.subheader("✨ AI Enhancement")
        if st.button("Enhance with LLM"):
            api_key = st.session_state.get("openrouter_key")
            if not api_key:
                st.error("Please set your OpenRouter API Key in 'Settings' first.")
            else:
                from modules.llm_correction import LLMCorrector
                corrector = LLMCorrector(api_key=api_key)
                with st.spinner("Refining text with AI..."):
                    enhanced_text = corrector.correct_text(text)
                    st.text_area("Enhanced Text", enhanced_text, height=300)
def render_math_page():
    st.title("🧮 Math Solver (Beta)")
    st.info("Upload an image of a math equation/expression (Printed or Handwritten).")
    
    uploaded_file = st.file_uploader("Upload Math Image", type=['png', 'jpg', 'jpeg'])
    
    if uploaded_file is not None:
        image = Image.open(uploaded_file)
        st.image(image, caption="Uploaded Equation")
        
        if st.button("Solve & Convert to LaTeX"):
            with st.spinner("Analyzing equation..."):
                math_module = MathOCRModule()
                latex_result = math_module.perform_math_ocr(image)
                
            st.code(latex_result, language="latex")
            st.success("LaTeX Generated!")

def render_sketch_page():
    st.title("🎨 Sketch to SVG")
    st.write("Convert hand-drawn sketches into scalable vector graphics.")
    
    uploaded_file = st.file_uploader("Upload Sketch", type=['png', 'jpg', 'jpeg'])
    
    if uploaded_file is not None:
        image = Image.open(uploaded_file)
        st.image(image, caption="Original Sketch")
        
        if st.button("Vectorize"):
            with st.spinner("Tracing paths..."):
                sketch_module = SketchModule()
                # Assuming save_uploaded_file is handled or we pass bytes/image
                # SketchModule usually takes a path or an image object depending on impl.
                # Let's save to temp for safety as many opencv based modules prefer paths.
                temp_path = f"temp_sketch_{uploaded_file.name}"
                image.save(temp_path)
                
                output_svg = "vectorized_output.svg"
                svg_path = sketch_module.convert_to_svg(temp_path, output_svg)
                
                if os.path.exists(svg_path):
                    st.success("Vectorization pipeline complete.")
                    with open(svg_path, "r") as f:
                        svg_content = f.read()
                        st.download_button("Download SVG", svg_content, "sketch.svg", "image/svg+xml")
                    
                    # Cleanup
                    os.remove(temp_path)
                else:
                    st.error("Vectorization faled.")

def render_speech_page():
    st.title("🗣 Speech & Language")
    
    tab1, tab2, tab3 = st.tabs(["Speech to Text", "Text to Speech", "Translation"])
    from modules.speech_language import LanguageToolkit
    lang_tool = LanguageToolkit()
    mgr = FileManager()

    with tab1:
        st.subheader("Dictation (Offline)")
        st.write("Upload an audio file (WAV) to transcribe using Vosk.")
        aud = st.file_uploader("Upload Audio", type=["wav"])
        if aud and st.button("Transcribe"):
            with st.spinner("Listening..."):
                text = lang_tool.transcribe_audio(aud.read())
                st.text_area("Transcription", text, height=150)
    
    with tab2:
        st.subheader("Read Aloud")
        txt = st.text_area("Enter Text", "Hello, welcome to Smart Data Recognition.")
        
        # Voice Selection
        voices = lang_tool.get_voices()
        voice_names = [v['name'] for v in voices]
        selected_voice_name = st.selectbox("Select Voice", voice_names) if voice_names else None
        
        if st.button("Speak"):
            # Find ID
            vid = None
            if selected_voice_name:
                for v in voices:
                    if v['name'] == selected_voice_name:
                        vid = v['id']
                        break
            
            path = lang_tool.text_to_speech(txt, "output_audio.wav", voice_id=vid)
            if path:
                st.audio(path)
                
    with tab3:
        st.subheader("Translation")
        status = lang_tool.get_translation_status()
        st.caption(f"Status: {status}")
        
        if "Unavailable" in status:
            from modules.speech_language import TRANSLATION_ERROR
            st.error("Translation Modules Failed to Load.")
            st.warning(f"Error: {TRANSLATION_ERROR}")
            st.info("Try running: `pip install deep-translator` or `pip install argostranslate`")
        else:
            if "Offline" in status:
                st.success("✅ Offline Mode Active")
                # Check models
                if st.button("Install/Update Offline Models (EN/HI/MR)"):
                    with st.spinner("Downloading models... This may take a while."):
                        msg = lang_tool.install_translation_packages()
                        st.success(msg)
            else:
                st.warning("⚠️ Online Mode Active (Fallback)")
                st.markdown("Offline engine (`argostranslate`) failed to load. Using `Google Translate`.")
                    
            col_src, col_tgt = st.columns(2)
            with col_src:
                src_lang = st.selectbox("From", ["en", "hi", "mr"])
                src_text = st.text_area("Source Text", height=150)
                
            with col_tgt:
                tgt_lang = st.selectbox("To", ["hi", "en", "mr"])
                if st.button("Translate", type="primary"):
                    if src_lang == tgt_lang:
                        st.warning("Source and Target languages must be different.")
                    else:
                        with st.spinner("Translating..."):
                            res = lang_tool.translate_text(src_text, src_lang, tgt_lang)
                            st.success(res)

def render_security_page():
    st.title("🔐 Document Security")
    
    mode = st.radio("Mode", ["Digital Signature", "Redaction"], horizontal=True)
    from modules.security import SecurityModule
    sec = SecurityModule()
    mgr = FileManager()
    
    if mode == "Digital Signature":
        st.write("Sign a PDF locally with a timestamped visual seal.")
        f = st.file_uploader("Upload PDF", type="pdf", key="sig_up")
        if f and st.button("Sign Document"):
            p = f"temp_{f.name}"
            with open(p, "wb") as w: w.write(f.read())
            
            out = sec.sign_pdf(p, "signed.pdf")
            saved = mgr.save_with_versioning(out, "pdf", "signed_doc.pdf")
            st.success(f"Signed & Sealed. Saved to: {saved}")
            if os.path.exists(p): os.remove(p)
            
    elif mode == "Redaction":
        st.write("Permanently remove sensitive text from a PDF.")
        f = st.file_uploader("Upload PDF", type="pdf", key="red_up")
        txt = st.text_input("Text to Redact (Case Sensitive)")
        
        if f and txt and st.button("Redact All Occurrences"):
            p = f"temp_{f.name}"
            with open(p, "wb") as w: w.write(f.read())
            
            count, out = sec.redact_text(p, txt, "redacted.pdf")
            saved = mgr.save_with_versioning(out, "pdf", "redacted_doc.pdf")
            st.success(f"Redacted {count} occurrences. Saved to: {saved}")
            if os.path.exists(p): os.remove(p)
            
def render_pdf_tools_page():
    st.title("📄 PDF Utilities")
    
    tool = st.selectbox("Select Action", ["Merge PDFs", "Split PDF", "Compress PDF", "Convert PDF to Images", "Convert Images to PDF", "Protect with Password"])
    
    from modules.pdf_tools import PDFTools
    tools = PDFTools()
    mgr = FileManager()
    
    if tool == "Merge PDFs":
        files = st.file_uploader("Select PDF Files", accept_multiple_files=True, type="pdf")
        if files and st.button("Merge Files"):
            paths = []
            for f in files:
                p = f"temp_{f.name}"
                with open(p, "wb") as w: w.write(f.read())
                paths.append(p)
            out = tools.merge_pdfs(paths, "merged_output.pdf")
            saved = mgr.save_with_versioning(out, "pdf", "merged_doc.pdf")
            st.success(f"Merged! Saved to: {saved}")
            
    elif tool == "Split PDF":
        f = st.file_uploader("Upload PDF", type="pdf")
        if f and st.button("Split Pages"):
            p = f"temp_{f.name}"
            with open(p, "wb") as w: w.write(f.read())
            output_dir = "split_output"
            files = tools.split_pdf(p, output_dir)
            st.success(f"Split into {len(files)} pages in '{output_dir}/'")

    elif tool == "Compress PDF":
        f = st.file_uploader("Upload PDF", type="pdf")
        if f and st.button("Compress"):
            p = f"temp_{f.name}"
            with open(p, "wb") as w: w.write(f.read())
            out = tools.compress_pdf(p, "compressed.pdf")
            saved = mgr.save_with_versioning(out, "pdf", "compressed.pdf")
            st.success(f"Compressed! Saved to {saved}")
            
    elif tool == "Convert PDF to Images":
        f = st.file_uploader("Upload PDF", type="pdf")
        if f and st.button("Convert"):
             p = f"temp_{f.name}"
             with open(p, "wb") as w: w.write(f.read())
             out_dir = "pdf_images"
             files = tools.pdf_to_images(p, out_dir)
             st.success(f"Converted {len(files)} pages to images in '{out_dir}/'")
             
    elif tool == "Convert Images to PDF":
        imgs = st.file_uploader("Select Images", accept_multiple_files=True, type=["png","jpg"])
        if imgs and st.button("Create PDF"):
            paths = []
            for f in imgs:
                p = f"temp_{f.name}"
                with open(p, "wb") as w: w.write(f.read())
                paths.append(p)
            out = tools.images_to_pdf(paths, "images.pdf")
            saved = mgr.save_with_versioning(out, "pdf", "images_doc.pdf")
            st.success(f"Created PDF! Saved to {saved}")

    elif tool == "Protect with Password":
        f = st.file_uploader("Upload PDF", type="pdf")
        pw = st.text_input("Enter Password", type="password")
        if f and pw and st.button("Encrypt & Save"):
            p = "temp_src.pdf"
            with open(p, "wb") as w: w.write(f.read())
            
            out = tools.protect_pdf(p, pw, "protected.pdf")
            saved = mgr.save_with_versioning(out, "pdf", "secure_doc.pdf")
            st.success(f"Encrypted! Saved to: {saved}")
            if os.path.exists(p): os.remove(p)

def render_settings_page():
    st.title("⚙ Settings")
    st.write("Current Configuration")
    st.table({
        "Parameter": ["Offline Mode", "OCR Engine", "Theme", "Log Level"],
        "Value": ["Active", "EasyOCR + TrOCR (Inactive)", "Purple-Orange", "Error Only"]
    })
    
    st.markdown("### 🔑 API Keys")
    key = st.text_input("OpenRouter API Key (for LLM Enhancement)", type="password", value=st.session_state.get("openrouter_key", ""))
    if key:
        st.session_state.openrouter_key = key
        st.caption("Key saved temporarily for this session.")

if __name__ == "__main__":
    main()
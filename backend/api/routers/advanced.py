from fastapi import APIRouter, UploadFile, File, Form, HTTPException, BackgroundTasks, Depends
from fastapi.responses import JSONResponse, FileResponse
from PIL import Image
import io
import tempfile
import os
import shutil
from typing import List, Optional
import json
from pydantic import BaseModel

from modules.database import save_task
from api.routers.history import get_current_user
from modules.gemini_client import GeminiClient

router = APIRouter()
gemini_client = GeminiClient()

# NOTE: Advanced feature modules are imported lazily inside endpoints 
# to prevents server startup timeouts on Cloud Run (avoiding heavy global imports like cv2, torch, etc.)

class SummarizeRequest(BaseModel):
    text: str
    max_sentences: int = 3

class CompareRequest(BaseModel):
    text1: str
    text2: str

class WatermarkRequest(BaseModel):
    text: str
    visible: bool = True
    position: str = "bottom-right"  # top-left, top-right, center, bottom-left, bottom-right

class BatchProcessRequest(BaseModel):
    features: List[str]  # List of features to apply to all files

@router.post("/classify-document")
async def classify_document(
    file: UploadFile = File(...),
    userId: str = Depends(get_current_user)
):
    """
    Classify a document into categories like invoice, receipt, contract, etc.
    """
    try:
        from modules.advanced.document_classifier import DocumentClassifier
        document_classifier = DocumentClassifier()
        
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        
        classification = document_classifier.classify(image)
        
        if userId:
            await save_task(userId, "document_classification", file.filename, classification)
        
        return {"classification": classification, "confidence": classification.get("confidence", 0)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/multi-language-ocr")
async def multi_language_ocr_endpoint(
    file: UploadFile = File(...),
    target_language: str = Form("eng"),  # Default to English
    detect_language: bool = Form(True),
    userId: str = Depends(get_current_user)
):
    """
    Perform OCR in multiple languages with optional language detection
    """
    try:
        from modules.advanced.multi_language_ocr import MultiLanguageOCR
        multi_language_ocr = MultiLanguageOCR()

        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        
        result = multi_language_ocr.perform_ocr(image, target_language, detect_language)
        
        if userId:
            await save_task(userId, "multi_language_ocr", file.filename, result.get("text", ""))
        
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/enhance-image")
async def enhance_image(
    file: UploadFile = File(...),
    enhancement_type: str = Form("default"),  # sharpness, contrast, brightness, noise_reduction
    userId: str = Depends(get_current_user)
):
    """
    Enhance image quality for better OCR results
    """
    try:
        from modules.advanced.image_enhancer import ImageEnhancer
        image_enhancer = ImageEnhancer()

        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        
        enhanced_image = image_enhancer.enhance(image, enhancement_type)
        
        # Save to temporary file
        temp_dir = tempfile.mkdtemp()
        output_path = os.path.join(temp_dir, f"enhanced_{file.filename}")
        
        enhanced_image.save(output_path)
        
        if userId:
            await save_task(userId, "image_enhancement", file.filename, f"Enhanced with {enhancement_type}")
        
        return FileResponse(
            output_path,
            media_type="image/jpeg",
            filename=f"enhanced_{file.filename}",
            background=BackgroundTasks().add_task(shutil.rmtree, temp_dir)
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/summarize-document")
async def summarize_document(
    request: SummarizeRequest,
    userId: str = Depends(get_current_user)
):
    """
    Summarize a document using AI
    """
    try:
        from modules.advanced.document_summarizer import DocumentSummarizer
        document_summarizer = DocumentSummarizer()

        summary = document_summarizer.summarize(request.text, request.max_sentences)
        
        if userId:
            await save_task(userId, "document_summarization", "text_input", summary)
        
        return {"summary": summary}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/extract-invoice-data")
async def extract_invoice_data(
    file: UploadFile = File(...),
    userId: str = Depends(get_current_user)
):
    """
    Extract key data from invoices and receipts
    """
    try:
        from modules.advanced.invoice_extractor import InvoiceExtractor
        invoice_extractor = InvoiceExtractor()

        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        
        extracted_data = invoice_extractor.extract(image)
        
        if userId:
            await save_task(userId, "invoice_extraction", file.filename, json.dumps(extracted_data))
        
        return {"extracted_data": extracted_data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/extract-tables")
async def extract_tables(
    file: UploadFile = File(...),
    format: str = Form("csv"),  # csv, excel, json
    userId: str = Depends(get_current_user)
):
    """
    Extract tables from documents and convert to structured formats
    """
    try:
        from modules.advanced.table_extractor import TableExtractor
        table_extractor = TableExtractor()

        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        
        tables = table_extractor.extract_tables(image, format)
        
        if userId:
            await save_task(userId, "table_extraction", file.filename, f"Extracted {len(tables)} tables")
        
        return {"tables": tables, "format": format}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/detect-barcodes")
async def detect_barcodes(
    file: UploadFile = File(...),
    barcode_types: str = Form("all"),  # all, qr, code128, code39, etc.
    userId: str = Depends(get_current_user)
):
    """
    Detect and decode barcodes and QR codes in images
    """
    try:
        from modules.advanced.barcode_detector import BarcodeDetector
        barcode_detector = BarcodeDetector()

        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        
        barcodes = barcode_detector.detect(image, barcode_types)
        
        if userId:
            await save_task(userId, "barcode_detection", file.filename, f"Detected {len(barcodes)} barcodes")
        
        return {"barcodes": barcodes}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/compare-documents")
async def compare_documents(
    request: CompareRequest,
    userId: str = Depends(get_current_user)
):
    """
    Compare two documents and highlight differences
    """
    try:
        from modules.advanced.document_comparison import DocumentComparator
        document_comparator = DocumentComparator()

        differences = document_comparator.compare(request.text1, request.text2)
        
        if userId:
            await save_task(userId, "document_comparison", "text_comparison", f"Found {len(differences)} differences")
        
        return {"differences": differences, "similarity_score": differences.get("similarity", 0)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/analyze-handwriting")
async def analyze_handwriting(
    file: UploadFile = File(...),
    userId: str = Depends(get_current_user)
):
    """
    Analyze handwriting characteristics
    """
    try:
        from modules.advanced.handwriting_analyzer import HandwritingAnalyzer
        handwriting_analyzer = HandwritingAnalyzer()

        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        
        analysis = handwriting_analyzer.analyze(image)
        
        if userId:
            await save_task(userId, "handwriting_analysis", file.filename, json.dumps(analysis))
        
        return {"analysis": analysis}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/enhance-audio")
async def enhance_audio(
    file: UploadFile = File(...),
    enhancement_type: str = Form("denoise"),  # denoise, amplify, normalize
    userId: str = Depends(get_current_user)
):
    """
    Enhance audio quality before transcription
    """
    try:
        from modules.advanced.audio_enhancer import AudioEnhancer
        audio_enhancer = AudioEnhancer()

        contents = await file.read()
        
        enhanced_audio_path = audio_enhancer.enhance(contents, enhancement_type, file.filename)
        
        if userId:
            await save_task(userId, "audio_enhancement", file.filename, f"Enhanced with {enhancement_type}")
        
        # Return the enhanced audio file
        return FileResponse(
            enhanced_audio_path,
            media_type="audio/wav",
            filename=f"enhanced_{file.filename}"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/add-watermark")
async def add_watermark(
    file: UploadFile = File(...),
    request: WatermarkRequest = Depends(),
    userId: str = Depends(get_current_user)
):
    """
    Add watermark to documents
    """
    try:
        from modules.advanced.watermark_processor import WatermarkProcessor
        watermark_processor = WatermarkProcessor()

        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        
        watermarked_image = watermark_processor.add_watermark(
            image, request.text, request.visible, request.position
        )
        
        # Save to temporary file
        temp_dir = tempfile.mkdtemp()
        output_path = os.path.join(temp_dir, f"watermarked_{file.filename}")
        
        watermarked_image.save(output_path)
        
        if userId:
            await save_task(userId, "watermark_addition", file.filename, f"Added watermark: {request.text}")
        
        return FileResponse(
            output_path,
            media_type="image/jpeg",
            filename=f"watermarked_{file.filename}",
            background=BackgroundTasks().add_task(shutil.rmtree, temp_dir)
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/batch-process")
async def batch_process(
    request: BatchProcessRequest,
    files: List[UploadFile] = File(...),
    userId: str = Depends(get_current_user)
):
    """
    Process multiple documents with selected features
    """
    try:
        from modules.advanced.batch_processor import BatchProcessor
        batch_processor = BatchProcessor()

        file_contents = []
        for file in files:
            contents = await file.read()
            image = Image.open(io.BytesIO(contents))
            file_contents.append((file.filename, image))
        
        results = batch_processor.process(file_contents, request.features)
        
        if userId:
            await save_task(userId, "batch_processing", f"{len(files)} files", f"Applied features: {', '.join(request.features)}")
        
        return {"results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/smart-redaction")
async def smart_redaction_endpoint(
    file: UploadFile = File(...),
    redact_types: str = Form("email,phone,credit_card"),
    userId: str = Depends(get_current_user)
):
    try:
        from modules.advanced.smart_redaction import SmartRedaction
        smart_redaction = SmartRedaction()

        contents = await file.read()
        types_list = redact_types.split(',')
        redacted_image = smart_redaction.redact_pii(contents, types_list)
        
        # Save to temp
        temp_dir = tempfile.mkdtemp()
        output_path = os.path.join(temp_dir, f"redacted_{file.filename}")
        with open(output_path, "wb") as f:
            f.write(redacted_image)
            
        if userId:
            await save_task(userId, "smart_redaction", file.filename, f"Redacted {redact_types}")
            
        return FileResponse(
            output_path,
            media_type="image/png",
            filename=f"redacted_{file.filename}",
            background=BackgroundTasks().add_task(shutil.rmtree, temp_dir)
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/extract-signature")
async def extract_signature_endpoint(
    file: UploadFile = File(...),
    userId: str = Depends(get_current_user)
):
    try:
        from modules.advanced.signature_extractor import SignatureExtractor
        signature_extractor = SignatureExtractor()

        contents = await file.read()
        sig_image = signature_extractor.extract_signature(contents)
        
        temp_dir = tempfile.mkdtemp()
        output_path = os.path.join(temp_dir, f"signature_{file.filename}.png")
        with open(output_path, "wb") as f:
            f.write(sig_image)
            
        if userId:
            await save_task(userId, "signature_extraction", file.filename, "Extracted signature")
            
        return FileResponse(
            output_path,
            media_type="image/png",
            filename=f"signature.png",
            background=BackgroundTasks().add_task(shutil.rmtree, temp_dir)
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/translate-document")
async def translate_document_endpoint(
    file: UploadFile = File(...),
    target_language: str = Form("es"),
    userId: str = Depends(get_current_user)
):
    try:
        from modules.advanced.doc_translator import DocumentTranslator
        document_translator = DocumentTranslator()

        contents = await file.read()
        result = document_translator.translate_document(contents, target_language)
        
        if userId:
            await save_task(userId, "document_translation", file.filename, f"Translated to {target_language}")
            
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/solve-math")
async def solve_math_endpoint(
    problem_text: str = Form(...),
    userId: str = Depends(get_current_user)
):
    try:
        from modules.advanced.advanced_math import AdvancedMathSolver
        advanced_math_solver = AdvancedMathSolver()

        result = advanced_math_solver.solve_problem(problem_text)
        
        if userId:
            await save_task(userId, "math_solver", problem_text[:20], "Solved")
            
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/recognize-objects")
async def recognize_objects_endpoint(
    file: UploadFile = File(...),
    userId: str = Depends(get_current_user)
):
    try:
        from modules.advanced.object_recognition import ObjectRecognizer
        object_recognizer = ObjectRecognizer()

        contents = await file.read()
        result = object_recognizer.recognize_objects(contents)
        
        if userId:
            await save_task(userId, "object_recognition", file.filename, f"Found {len(result['objects'])} objects")
            
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/text-to-speech")
async def text_to_speech_endpoint(
    text: str = Form(...),
    voice: str = Form("en-US-AriaNeural"),
    userId: str = Depends(get_current_user)
):
    try:
        from modules.advanced.tts_service import TTSService
        tts_service = TTSService()

        audio_path = await tts_service.generate_speech(text, voice)
        
        if userId:
            await save_task(userId, "text_to_speech", text[:20], "Generated audio")
            
        return FileResponse(
            audio_path,
            media_type="audio/mpeg",
            filename="speech.mp3",
            background=BackgroundTasks().add_task(os.remove, audio_path)
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/extract-colors")
async def extract_colors_endpoint(
    file: UploadFile = File(...),
    userId: str = Depends(get_current_user)
):
    try:
        from modules.advanced.color_extractor import ColorExtractor
        color_extractor = ColorExtractor()

        contents = await file.read()
        palette = color_extractor.extract_palette(contents)
        
        if userId:
            await save_task(userId, "color_extraction", file.filename, f"Extracted {len(palette)} colors")
            
        return {"palette": palette}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/generate-qr")
async def generate_qr_endpoint(
    data: str = Form(...),
    color: str = Form("black"),
    bg_color: str = Form("white"),
    userId: str = Depends(get_current_user)
):
    try:
        from modules.advanced.qr_generator import QRGenerator
        qr_generator = QRGenerator()

        qr_image = qr_generator.generate_qr(data, color, bg_color)
        
        temp_dir = tempfile.mkdtemp()
        output_path = os.path.join(temp_dir, f"qr.png")
        with open(output_path, "wb") as f:
            f.write(qr_image)
            
        if userId:
            await save_task(userId, "qr_generation", data[:20], "Generated QR")
            
        return FileResponse(
            output_path,
            media_type="image/png",
            filename="qr_code.png",
            background=BackgroundTasks().add_task(shutil.rmtree, temp_dir)
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/scan-id")
async def scan_id_endpoint(
    file: UploadFile = File(...),
    userId: str = Depends(get_current_user)
):
    try:
        from modules.advanced.id_scanner import IDScanner
        id_scanner = IDScanner()

        contents = await file.read()
        result = id_scanner.extract_id_info(contents)
        
        if userId:
            await save_task(userId, "id_scanning", file.filename, result["document_type"])
            
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/track-receipt")
async def track_receipt_endpoint(
    file: UploadFile = File(...),
    userId: str = Depends(get_current_user)
):
    try:
        from modules.advanced.receipt_tracker import ReceiptTracker
        receipt_tracker = ReceiptTracker()

        contents = await file.read()
        result = receipt_tracker.extract_expense(contents)
        
        if userId:
            await save_task(userId, "receipt_tracking", file.filename, f"Total: {result['total']}")
            
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
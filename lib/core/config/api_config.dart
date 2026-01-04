class ApiConfig {
  static const String baseUrl =
      'https://intelliscan-backend-718288215858.us-central1.run.app';
  // static const String baseUrl =
  //     'http://10.0.2.2:8000'; // Localhost for Android Emulator

  // Auth
  static const String loginEndpoint = '$baseUrl/api/auth/login';
  static const String signupEndpoint = '$baseUrl/api/auth/signup';
  static const String meEndpoint = '$baseUrl/api/auth/me';

  // Features
  static const String ocrEndpoint = '$baseUrl/api/ocr/extract';
  static const String mathEndpoint = '$baseUrl/api/math/solve';
  static const String sketchEndpoint = '$baseUrl/api/sketch/vectorize';
  static const String pdfMergeEndpoint = '$baseUrl/api/pdf/merge';
  static const String pdfCompressEndpoint = '$baseUrl/api/pdf/compress';
  static const String pdfSplitEndpoint = '$baseUrl/api/pdf/split';
  static const String pdfImageToPdfEndpoint = '$baseUrl/api/pdf/image-to-pdf';
  static const String pdfProtectEndpoint = '$baseUrl/api/pdf/protect';
  static const String pdfRedactEndpoint = '$baseUrl/api/pdf/redact';
  static const String pdfUnlockEndpoint = '$baseUrl/api/pdf/unlock';
  static const String pdfRotateEndpoint = '$baseUrl/api/pdf/rotate';
  static const String pdfConvertEndpoint = '$baseUrl/api/pdf/convert';
  static const String signatureExtractionEndpoint =
      '$baseUrl/api/advanced/extract-signature';
  static const String classifyEndpoint =
      '$baseUrl/api/advanced/classify-document';
  static const String multiOcrEndpoint =
      '$baseUrl/api/advanced/multi-language-ocr';
  static const String enhanceImageEndpoint =
      '$baseUrl/api/advanced/enhance-image';
  static const String summarizeDocumentEndpoint =
      '$baseUrl/api/advanced/summarize-document';
  static const String invoiceExtractionEndpoint =
      '$baseUrl/api/advanced/extract-invoice-data';
  static const String tableExtractionEndpoint =
      '$baseUrl/api/advanced/extract-tables';
  static const String barcodeDetectionEndpoint =
      '$baseUrl/api/advanced/detect-barcodes';
  static const String objectRecognitionEndpoint =
      '$baseUrl/api/advanced/recognize-objects';
  static const String summarizeEndpoint =
      '$baseUrl/api/advanced/summarize-document';
  // invoiceExtractionEndpoint is already there at line 33/34

  // Speech & Language
  static const String transcribeEndpoint = '$baseUrl/api/speech/transcribe';
  static const String ttsEndpoint = '$baseUrl/api/speech/tts';
  static const String translateEndpoint = '$baseUrl/api/speech/translate';

  // AI Guide
  static const String guideEndpoint = '$baseUrl/api/guide/ask';

  // System & Social
  static const String feedbackEndpoint = '$baseUrl/api/system/feedback';
  static const String communityEndpoint = '$baseUrl/api/system/community';
  static const String referralInfoEndpoint = '$baseUrl/api/referral/info';
  static const String referralClaimEndpoint = '$baseUrl/api/referral/claim';

  // History
  static const String historyEndpoint = '$baseUrl/api/history/';

  // Subscription
  static const String subscriptionStatusEndpoint =
      '$baseUrl/api/subscription/status';
  static const String deductCreditsEndpoint =
      '$baseUrl/api/subscription/deduct';
  static const String createOrderEndpoint =
      '$baseUrl/api/subscription/create-order';
  static const String verifyPaymentEndpoint =
      '$baseUrl/api/subscription/verify-payment';
}

/// OCR result models — mirrors shared `ocr_results` and `extracted_fields`
/// tables. Extraction is performed by Member 4's FastAPI service; Flutter
/// only displays, allows correction, and confirms.
///
/// Expected FastAPI/NestJS response shape (contract to be finalised):
/// ```json
/// {
///   "jobId": "ocr-job-123",
///   "status": "COMPLETED" | "PROCESSING" | "FAILED",
///   "progressStep": "EXTRACTING_TEXT",
///   "fields": [
///     {"key": "PRODUCT_NAME", "label": "Product Name", "value": "...",
///      "confidence": 0.94, "sourceImageId": "...", "boundingBox": {...}}
///   ]
/// }
/// ```
library;

/// Canonical declaration keys the backend is expected to return.
/// Labels are display strings; keys are stable contract identifiers.
abstract final class OcrFieldKeys {
  static const productName = 'PRODUCT_NAME';
  static const genericName = 'GENERIC_NAME';
  static const manufacturer = 'MANUFACTURER';
  static const packer = 'PACKER';
  static const importer = 'IMPORTER';
  static const netQuantity = 'NET_QUANTITY';
  static const mrp = 'MRP';
  static const manufacturingDate = 'MANUFACTURING_DATE';
  static const expiryOrUseBy = 'EXPIRY_USE_BY';
  static const countryOfOrigin = 'COUNTRY_OF_ORIGIN';
  static const consumerCare = 'CONSUMER_CARE';
  static const batchOrLot = 'BATCH_LOT';
  static const other = 'OTHER';
}

enum OcrStatus { pending, processing, completed, failed }

enum OcrPipelineStep {
  uploadingEvidence,
  processingImages,
  extractingText,
  identifyingDeclarations,
  checkingCompliance;

  String get label => switch (this) {
        OcrPipelineStep.uploadingEvidence => 'Uploading Evidence',
        OcrPipelineStep.processingImages => 'Processing Images',
        OcrPipelineStep.extractingText => 'Extracting Text',
        OcrPipelineStep.identifyingDeclarations => 'Identifying Declarations',
        OcrPipelineStep.checkingCompliance => 'Checking Compliance',
      };
}

/// One extracted declaration. Every field is editable by the inspector —
/// `isCorrected` tracks human-in-the-loop verification.
class ExtractedField {
  const ExtractedField({
    required this.key,
    required this.label,
    required this.value,
    required this.confidence,
    this.isMissing = false,
    this.isCorrected = false,
    this.sourceImageId,
    this.unit,
  });

  final String key;
  final String label;
  final String value;

  /// 0.0–1.0 AI confidence from FastAPI.
  final double confidence;

  /// Backend flags declarations it could not find on the package.
  final bool isMissing;

  /// True after the inspector edits/corrects the value.
  final bool isCorrected;

  /// Evidence item the value was read from, when backend provides it.
  final String? sourceImageId;

  final String? unit;

  ExtractedField copyWith({
    String? key,
    String? label,
    String? value,
    double? confidence,
    bool? isMissing,
    bool? isCorrected,
    String? sourceImageId,
    String? unit,
  }) {
    return ExtractedField(
      key: key ?? this.key,
      label: label ?? this.label,
      value: value ?? this.value,
      confidence: confidence ?? this.confidence,
      isMissing: isMissing ?? this.isMissing,
      isCorrected: isCorrected ?? this.isCorrected,
      sourceImageId: sourceImageId ?? this.sourceImageId,
      unit: unit ?? this.unit,
    );
  }

  factory ExtractedField.fromJson(Map<String, dynamic> json) => ExtractedField(
        key: json['key'] as String,
        label: (json['label'] as String?) ?? json['key'] as String,
        value: (json['value'] as String?) ?? '',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
        isMissing: json['isMissing'] as bool? ?? false,
        isCorrected: json['isCorrected'] as bool? ?? false,
        sourceImageId: json['sourceImageId'] as String?,
        unit: json['unit'] as String?,
      );
}

/// Full OCR analysis result for one package/product.
class OcrResult {
  const OcrResult({
    required this.jobId,
    required this.status,
    required this.fields,
    required this.analyzedAt,
    this.currentStep,
    this.failureReason,
    this.rawTextPreview,
  });

  final String jobId;
  final OcrStatus status;
  final List<ExtractedField> fields;

  final DateTime analyzedAt;

  /// Active pipeline step while `status == processing`.
  final OcrPipelineStep? currentStep;

  final String? failureReason;

  /// Optional raw OCR text for inspector reference.
  final String? rawTextPreview;

  bool get isCompleted => status == OcrStatus.completed;
  bool get isFailed => status == OcrStatus.failed;

  OcrResult copyWith({
    String? jobId,
    OcrStatus? status,
    List<ExtractedField>? fields,
    DateTime? analyzedAt,
    OcrPipelineStep? currentStep,
    String? failureReason,
    String? rawTextPreview,
  }) {
    return OcrResult(
      jobId: jobId ?? this.jobId,
      status: status ?? this.status,
      fields: fields ?? this.fields,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      currentStep: currentStep ?? this.currentStep,
      failureReason: failureReason ?? this.failureReason,
      rawTextPreview: rawTextPreview ?? this.rawTextPreview,
    );
  }
}

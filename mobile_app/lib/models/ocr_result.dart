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
///
/// NOTE: The FastAPI OCR backend returns lowercase snake_case keys
/// ("product_name", "mrp", "consumer_care"). Field lookups MUST be
/// case-insensitive and normalised — see [_normalizeKey].
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
  static const fssaiLicense = 'FSSAI_LICENSE';
  static const unitSalePrice = 'UNIT_SALE_PRICE';
  static const other = 'OTHER';

  /// Normalise a raw key from JSON into uppercase with underscores.
  /// "product_name" → "PRODUCT_NAME", "manufacturerNameAddress" → "MANUFACTURERNAMEADDRESS"
  static String normalise(String raw) =>
      raw.toUpperCase().replaceAll('-', '_');

  /// Alias map: alternate backend keys that map to canonical keys.
  static const Map<String, String> _aliases = {
    'MANUFACTURER_NAME_ADDRESS': 'MANUFACTURER',
    'MANUFACTURER_NAME': 'MANUFACTURER',
    'PACKER_NAME_ADDRESS': 'PACKER',
    'PACKER_NAME': 'PACKER',
    'DATE_OF_MANUFACTURE': 'MANUFACTURING_DATE',
    'MFG_DATE': 'MANUFACTURING_DATE',
    'DATE_OF_EXPIRY': 'EXPIRY_USE_BY',
    'BEST_BEFORE': 'EXPIRY_USE_BY',
    'EXPIRY_DATE': 'EXPIRY_USE_BY',
    'CONSUMER_CARE_DETAILS': 'CONSUMER_CARE',
    'CUSTOMER_CARE': 'CONSUMER_CARE',
    'BATCH_NUMBER': 'BATCH_LOT',
    'LOT_NUMBER': 'BATCH_LOT',
    'FSSAI': 'FSSAI_LICENSE',
    'FSSAI_NO': 'FSSAI_LICENSE',
    'UNIT_PRICE': 'UNIT_SALE_PRICE',
    'COMMODITY_NAME': 'PRODUCT_NAME',
  };

  /// Resolve a raw JSON key to its canonical OcrFieldKeys constant.
  static String resolve(String raw) {
    final norm = normalise(raw);
    return _aliases[norm] ?? norm;
  }
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

  factory ExtractedField.fromJson(Map<String, dynamic> json) {
    // Resolve backend key (may be snake_case / camelCase) to canonical UPPER form.
    final rawKey = json['key'] as String? ?? '';
    final resolvedKey = OcrFieldKeys.resolve(rawKey);
    return ExtractedField(
      key: resolvedKey,
      label: (json['label'] as String?) ?? rawKey,
      value: (json['value'] as String?) ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      isMissing: json['isMissing'] as bool? ?? false,
      isCorrected: json['isCorrected'] as bool? ?? false,
      sourceImageId: json['sourceImageId'] as String?,
      unit: json['unit'] as String?,
    );
  }
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

  /// Returns the value for [key], case-insensitively matching both the
  /// canonical key (e.g. "MRP") and any backend alias.
  String? getFieldValue(String key) {
    final canonical = OcrFieldKeys.resolve(key);
    try {
      final match = fields.firstWhere(
        (f) =>
            (OcrFieldKeys.resolve(f.key) == canonical ||
                f.key.toUpperCase() == canonical ||
                f.label.toUpperCase() == canonical) &&
            !f.isMissing &&
            f.value.trim().isNotEmpty,
      );
      return match.value.trim();
    } catch (_) {
      return null;
    }
  }

  String? get productName => getFieldValue(OcrFieldKeys.productName);
  String? get genericName => getFieldValue(OcrFieldKeys.genericName);
  String? get manufacturerDetails => getFieldValue(OcrFieldKeys.manufacturer);
  String? get batchNumber => getFieldValue(OcrFieldKeys.batchOrLot);
  String? get mrp => getFieldValue(OcrFieldKeys.mrp);
  String? get netQuantity => getFieldValue(OcrFieldKeys.netQuantity);
  String? get manufacturingDate => getFieldValue(OcrFieldKeys.manufacturingDate);
  String? get expiryDate => getFieldValue(OcrFieldKeys.expiryOrUseBy);
  String? get consumerCare => getFieldValue(OcrFieldKeys.consumerCare);
  String? get fssaiNumber => getFieldValue(OcrFieldKeys.fssaiLicense);
  String? get unitSalePrice => getFieldValue(OcrFieldKeys.unitSalePrice);

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

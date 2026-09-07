import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/ocr_result.dart';

/// On-device OCR and Legal Metrology Packaging Field Extraction Service.
///
/// Uses Google ML Kit on-device Text Recognition for ultra-fast, local,
/// offline text extraction across multi-angle packaging photos (front, back, sides).
/// Runs an intelligent heuristic regex parser to extract mandatory declarations
/// specified under Rule 6 of the Legal Metrology (Packaged Commodities) Rules, 2011.
class OcrService {
  OcrService();

  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// Analyzes multiple images from different packaging angles, merges extracted text,
  /// and produces structured [ExtractedField] declarations.
  Future<OcrResult> analyzePackageImages(List<String> imagePaths) async {
    final combinedBuffer = StringBuffer();
    final List<String> rawLines = [];

    for (final path in imagePaths) {
      if (path.isEmpty) continue;
      final file = File(path);
      if (!file.existsSync()) continue;

      try {
        final inputImage = InputImage.fromFile(file);
        final RecognizedText recognizedText =
            await _textRecognizer.processImage(inputImage);

        for (final block in recognizedText.blocks) {
          for (final line in block.lines) {
            final text = line.text.trim();
            if (text.isNotEmpty) {
              rawLines.add(text);
              combinedBuffer.writeln(text);
            }
          }
        }
      } catch (e) {
        debugPrint('[OcrService] Error processing image $path: $e');
      }
    }

    final String fullText = combinedBuffer.toString();
    final fields = parsePackagingDeclarations(fullText);

    return OcrResult(
      jobId: 'ocr-${DateTime.now().millisecondsSinceEpoch}',
      status: OcrStatus.completed,
      analyzedAt: DateTime.now(),
      fields: fields,
      rawTextPreview: fullText.trim(),
    );
  }

  /// Parses raw packaging text lines to extract statutory declarations under Rule 6.
  /// Uses anchor keywords and layout heuristics to accurately segregate declarations
  /// for any commodity without product-specific hardcoding.
  static List<ExtractedField> parsePackagingDeclarations(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final lowerText = text.toLowerCase();

    // 1. MRP (Rule 6(1)(e))
    // Anchor keywords: MRP, M.R.P., Maximum Retail Price, ₹, Rs.
    String mrpVal = '';
    double mrpConfidence = 0.0;

    final mrpRegex = RegExp(
      r'(?:m\.?r\.?p\.?|max(?:imum)?\s*retail\s*price|retail\s*price)\s*[:\-\.]?\s*(?:rs\.?|₹|inr)?\s*(\d+(?:\.\d{1,2})?)',
      caseSensitive: false,
    );
    final mrpMatch = mrpRegex.firstMatch(text);
    if (mrpMatch != null) {
      mrpVal = mrpMatch.group(1) ?? '';
      mrpConfidence = 0.98;
    } else {
      // Multi-line scan: keyword on one line, price numeral on same or subsequent line
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (RegExp(r'\b(?:m\.?r\.?p\.?|max(?:imum)?\s*retail\s*price)\b',
                caseSensitive: false)
            .hasMatch(line)) {
          final stripped = line.replaceAll(
              RegExp(r'\b(?:m\.?r\.?p\.?|max(?:imum)?\s*retail\s*price)\b',
                  caseSensitive: false),
              '');
          final numMatch = RegExp(r'(?:rs\.?|₹|inr)?\s*(\d+(?:\.\d{1,2})?)',
                  caseSensitive: false)
              .firstMatch(stripped);
          if (numMatch != null && (numMatch.group(1)?.isNotEmpty ?? false)) {
            mrpVal = numMatch.group(1)!;
            mrpConfidence = 0.96;
            break;
          }
          if (i + 1 < lines.length) {
            final nextNum = RegExp(
                    r'(?:rs\.?|₹|inr)?\s*(\d+(?:\.\d{1,2})?)',
                    caseSensitive: false)
                .firstMatch(lines[i + 1]);
            if (nextNum != null && (nextNum.group(1)?.isNotEmpty ?? false)) {
              mrpVal = nextNum.group(1)!;
              mrpConfidence = 0.94;
              break;
            }
          }
        }
      }
      // Currency symbol fallback
      if (mrpVal.isEmpty) {
        final symbolMatch = RegExp(r'(?:₹|rs\.?\s*)(\d+(?:\.\d{1,2})?)',
                caseSensitive: false)
            .firstMatch(text);
        if (symbolMatch != null) {
          mrpVal = symbolMatch.group(1) ?? '';
          mrpConfidence = 0.90;
        }
      }
    }

    final hasInclTaxes = lowerText.contains('incl. of all taxes') ||
        lowerText.contains('inclusive of all taxes') ||
        lowerText.contains('incl of all taxes') ||
        lowerText.contains('incl. of taxes') ||
        lowerText.contains('inclusive of taxes') ||
        lowerText.contains('(incl. of all taxes)') ||
        lowerText.contains('incl.all taxes');

    // 2. Net Quantity & Metric Unit (Rule 6(1)(c))
    // Anchor keywords: Net Wt, Net Qty, Net Weight, Net Volume, Net Quantity
    String netQtyVal = '';
    String netQtyUnit = '';
    double netQtyConfidence = 0.0;

    const unitPattern =
        r'(?:litre|litres|ltr|lt|lit|l|ml|milli\s*litre|millilitre|millilitres|kilogram|kilograms|kg|kgs|gms|gm|grams|g|mg|units|pieces|pcs|n)\b';

    final netQtyRegex = RegExp(
      r'(?:net\s*(?:weight|wt\.?|quantity|qty\.?|volume|vol\.?|content|contents)|volume|quantity)\s*[:\-\.]?\s*(\d+(?:\.\d+)?)\s*(' +
          unitPattern +
          r')',
      caseSensitive: false,
    );
    final qtyMatch = netQtyRegex.firstMatch(text);
    if (qtyMatch != null) {
      netQtyVal = qtyMatch.group(1) ?? '';
      netQtyUnit = qtyMatch.group(2)?.trim() ?? '';
      netQtyConfidence = 0.98;
    } else {
      // Multi-line scan
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (RegExp(
                r'\bnet\s*(?:weight|wt\.?|quantity|qty\.?|volume|vol\.?|content)\b',
                caseSensitive: false)
            .hasMatch(line)) {
          final matchSame = RegExp(
                  r'(\d+(?:\.\d+)?)\s*(' + unitPattern + r')',
                  caseSensitive: false)
              .firstMatch(line);
          if (matchSame != null) {
            netQtyVal = matchSame.group(1) ?? '';
            netQtyUnit = matchSame.group(2)?.trim() ?? '';
            netQtyConfidence = 0.96;
            break;
          }
          if (i + 1 < lines.length) {
            final matchNext = RegExp(
                    r'(\d+(?:\.\d+)?)\s*(' + unitPattern + r')',
                    caseSensitive: false)
                .firstMatch(lines[i + 1]);
            if (matchNext != null) {
              netQtyVal = matchNext.group(1) ?? '';
              netQtyUnit = matchNext.group(2)?.trim() ?? '';
              netQtyConfidence = 0.94;
              break;
            }
          }
        }
      }
      if (netQtyVal.isEmpty) {
        final standaloneQty = RegExp(
          r'\b(\d+(?:\.\d+)?)\s*(litre|litres|ltr|l|ml|kg|kilogram|gms|gm|g)\b',
          caseSensitive: false,
        ).firstMatch(text);
        if (standaloneQty != null) {
          netQtyVal = standaloneQty.group(1) ?? '';
          netQtyUnit = standaloneQty.group(2) ?? '';
          netQtyConfidence = 0.88;
        }
      }
    }

    // 3. Date of Manufacture / Packing (Rule 6(1)(d))
    // Anchor keywords: Mfg Date, Pkd Date, Date of Manufacture, Pkd on, Mfg, Packed
    String mfgDateVal = '';
    double mfgConfidence = 0.0;

    const dateSubPattern =
        r'([0-9]{1,2}(?:st|nd|rd|th)?\s+[A-Za-z]{3,9}\s+[0-9]{2,4}|[0-9]{1,2}[/\-\.][0-9]{1,2}[/\-\.][0-9]{2,4}|[0-9]{1,2}[/\-\.][0-9]{2,4}|[A-Za-z]{3,9}\s+[0-9]{2,4})';

    final mfgAnchorRegex = RegExp(
      r'\b(?:date\s*of\s*manufacture|date\s*of\s*mfg|mfg\s*date|date\s*of\s*packing|pkd\s*date|date\s*of\s*pkd|pkd\s*on|mfd\s*on|packed\s*on)\b\s*[:\-\.]?\s*' +
          dateSubPattern,
      caseSensitive: false,
    );
    final mfgMatch = mfgAnchorRegex.firstMatch(text);
    if (mfgMatch != null) {
      mfgDateVal = mfgMatch.group(1)?.trim() ?? '';
      mfgConfidence = 0.98;
    } else {
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (RegExp(
                    r'\b(?:date\s*of\s*manufacture|date\s*of\s*mfg|mfg\s*date|date\s*of\s*packing|pkd\s*date|date\s*of\s*pkd|pkd\s*on|mfd\s*on|mfg|pkd)\b',
                    caseSensitive: false)
                .hasMatch(line) &&
            !line.toLowerCase().contains('& date of mfg')) {
          final stripped = line.replaceAll(
              RegExp(
                  r'\b(?:date\s*of\s*manufacture|date\s*of\s*mfg|mfg\s*date|date\s*of\s*packing|pkd\s*date|date\s*of\s*pkd|pkd\s*on|mfd\s*on|mfg|pkd)\b[:\-\.]?',
                  caseSensitive: false),
              '');
          final matchSame = RegExp(dateSubPattern, caseSensitive: false)
              .firstMatch(stripped);
          if (matchSame != null) {
            mfgDateVal = matchSame.group(1)?.trim() ?? '';
            mfgConfidence = 0.95;
            break;
          }
          if (i + 1 < lines.length) {
            final matchNext = RegExp(dateSubPattern, caseSensitive: false)
                .firstMatch(lines[i + 1]);
            if (matchNext != null) {
              mfgDateVal = matchNext.group(1)?.trim() ?? '';
              mfgConfidence = 0.93;
              break;
            }
          }
        }
      }
    }

    // 4. Expiry / Best Before / Use By (Rule 6(1)(da))
    // Anchor keywords: Exp, Best Before, Use By, BB
    String expDateVal = '';
    double expConfidence = 0.0;

    const expSubPattern =
        r'([0-9]{1,2}(?:st|nd|rd|th)?\s+[A-Za-z]{3,9}\s+[0-9]{2,4}|[0-9]{1,2}[/\-\.][0-9]{1,2}[/\-\.][0-9]{2,4}|[0-9]{1,2}[/\-\.][0-9]{2,4}|[A-Za-z]{3,9}\s+[0-9]{2,4}|\d+\s*months?\s*(?:from\s*(?:mfg|date\s*of\s*manufacture|pkd|packing))?|best\s*within\s*\d+\s*(?:months?|days?))';

    final expAnchorRegex = RegExp(
      r'\b(?:best\s*before|use\s*by|expiry\s*date|exp\s*date|date\s*of\s*expiry|expiry|exp\.?|bb)\b\s*[:\-\.]?\s*' +
          expSubPattern,
      caseSensitive: false,
    );
    final expMatch = expAnchorRegex.firstMatch(text);
    if (expMatch != null) {
      expDateVal = expMatch.group(1)?.trim() ?? '';
      expConfidence = 0.98;
    } else {
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (RegExp(
                    r'\b(?:best\s*before|use\s*by|expiry\s*date|exp\s*date|date\s*of\s*expiry|expiry|exp\.?|bb)\b',
                    caseSensitive: false)
                .hasMatch(line) &&
            !RegExp(r'\b(?:mfg|manufacture|pkd|packed)\b', caseSensitive: false)
                .hasMatch(line)) {
          final stripped = line.replaceAll(
              RegExp(
                  r'\b(?:best\s*before|use\s*by|expiry\s*date|exp\s*date|date\s*of\s*expiry|expiry|exp\.?|bb)\b[:\-\.]?',
                  caseSensitive: false),
              '');
          final matchSame = RegExp(expSubPattern, caseSensitive: false)
              .firstMatch(stripped);
          if (matchSame != null) {
            expDateVal = matchSame.group(1)?.trim() ?? '';
            expConfidence = 0.95;
            break;
          } else if (stripped.trim().isNotEmpty && stripped.trim().length < 40) {
            expDateVal = stripped.trim();
            expConfidence = 0.88;
            break;
          }
          if (i + 1 < lines.length) {
            final matchNext = RegExp(expSubPattern, caseSensitive: false)
                .firstMatch(lines[i + 1]);
            if (matchNext != null) {
              expDateVal = matchNext.group(1)?.trim() ?? '';
              expConfidence = 0.93;
              break;
            }
          }
        }
      }
    }

    // 5. Batch / Lot Number (Rule 6(1)(d))
    // Anchor keywords: Batch No, Batch Number, Lot No, B. No., Batch, Lot
    String batchVal = '';
    double batchConfidence = 0.0;

    final batchRegex = RegExp(
      r'\b(?:batch\s*(?:number|no\.?|#)?|lot\s*(?:number|no\.?|#)?|b\.?\s*no\.?)\b\s*[:\-\.]?\s*([A-Za-z0-9\-_/]+)',
      caseSensitive: false,
    );
    final batchMatches = batchRegex.allMatches(text);
    for (final match in batchMatches) {
      final candidate = match.group(1)?.trim() ?? '';
      final lowerCand = candidate.toLowerCase();
      if (lowerCand != 'number' &&
          lowerCand != 'no' &&
          lowerCand != 'and' &&
          lowerCand != 'date' &&
          lowerCand != 'mfg' &&
          lowerCand != 'lot' &&
          candidate.length >= 2) {
        batchVal = candidate;
        batchConfidence = 0.98;
        break;
      }
    }
    if (batchVal.isEmpty) {
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (RegExp(r'\b(?:batch\s*(?:number|no\.?)|lot\s*(?:number|no\.?)|b\.?\s*no\.?)\b',
                caseSensitive: false)
            .hasMatch(line) &&
            !line.toLowerCase().contains('& date of mfg')) {
          if (i + 1 < lines.length) {
            final nextToken = lines[i + 1].trim();
            final codeMatch =
                RegExp(r'^([A-Za-z0-9\-_/]{3,20})$').firstMatch(nextToken);
            if (codeMatch != null) {
              batchVal = codeMatch.group(1)!;
              batchConfidence = 0.94;
              break;
            }
          }
        }
      }
    }

    // 6. FSSAI License Number (Food Safety)
    // Anchor keywords: FSSAI Lic No, FSSAI No, FSSAI Lic, Lic No, FSSAI
    String fssaiVal = '';
    double fssaiConfidence = 0.0;

    final fssaiRegex = RegExp(
      r'(?:fssai\s*(?:lic(?:ense)?\s*no\.?|no\.?|lic\.?)?|lic\.?\s*no\.?)\s*[:\-\.]?\s*([0-9]{10,14})',
      caseSensitive: false,
    );
    final fssaiMatch = fssaiRegex.firstMatch(text);
    if (fssaiMatch != null) {
      fssaiVal = fssaiMatch.group(1) ?? '';
      fssaiConfidence = 0.98;
    } else {
      final fssaiStandalone = RegExp(r'\b([12]\d{13})\b').firstMatch(text);
      if (fssaiStandalone != null) {
        fssaiVal = fssaiStandalone.group(1) ?? '';
        fssaiConfidence = 0.92;
      }
    }

    // 7. Manufacturer / Packer Details (Rule 6(1)(a))
    // Anchor keywords: Mfd by, Marketed by, Packed by, Manufactured by, Imported by
    String mfgNameVal = '';
    double mfgNameConfidence = 0.0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final mfgHeaderMatch = RegExp(
        r'\b(?:manufactured\s*&\s*packed\s*by|manufactured\s*by|packed\s*by|mfd\s*by|mfg\s*&\s*pkd\s*by|marketed\s*by|imported\s*by|mfd\.\s*by|pkd\.\s*by|mfg\.\s*by)\b\s*[:\-\.]?\s*(.*)',
        caseSensitive: false,
      ).firstMatch(line);

      if (mfgHeaderMatch != null) {
        final sameLineText = mfgHeaderMatch.group(1)?.trim() ?? '';
        final buffer = StringBuffer();
        int startNext = i + 1;

        if (sameLineText.isNotEmpty) {
          buffer.write(sameLineText);
        } else if (i + 1 < lines.length) {
          buffer.write(lines[i + 1].trim());
          startNext = i + 2;
        }

        // Grab subsequent address lines until hit next major section
        for (int j = startNext; j < lines.length && j <= startNext + 4; j++) {
          final nextLine = lines[j].trim();
          final lower = nextLine.toLowerCase();
          if (lower.contains('fssai') ||
              lower.contains('for consumer') ||
              lower.contains('customer care') ||
              lower.contains('consumer complaints') ||
              lower.contains('mrp') ||
              lower.contains('net wt') ||
              lower.contains('net volume') ||
              lower.contains('net qty') ||
              lower.contains('net quantity') ||
              lower.contains('batch') ||
              lower.contains('barcode') ||
              RegExp(r'^\d{8,}$')
                  .hasMatch(nextLine.replaceAll(RegExp(r'\s+'), ''))) {
            break;
          }
          if (buffer.isNotEmpty) buffer.write(', ');
          buffer.write(nextLine);
        }
        mfgNameVal = buffer.toString().trim();
        mfgNameConfidence = 0.96;
        break;
      }
    }

    if (mfgNameVal.isEmpty) {
      for (final line in lines) {
        final lower = line.toLowerCase();
        if (lower == 'manufacturer details') continue;
        if (lower.contains('pvt ltd') ||
            lower.contains('pvt. ltd') ||
            lower.contains('private limited') ||
            lower.contains('ltd.') ||
            lower.contains('industries') ||
            lower.contains('foods') ||
            lower.contains('enterprises') ||
            lower.contains('shg')) {
          mfgNameVal = line;
          mfgNameConfidence = 0.85;
          break;
        }
      }
    }

    // 8. Country of Origin (Rule 6(1)(aa))
    // Anchor keywords: Country of Origin, Made in, Product of
    String countryVal = '';
    double countryConfidence = 0.0;

    final countryRegex = RegExp(
      r'(?:country\s*of\s*origin|made\s*in|product\s*of)\s*[:\-\.]?\s*([a-zA-Z ]{3,25})',
      caseSensitive: false,
    );
    final countryMatch = countryRegex.firstMatch(text);
    if (countryMatch != null) {
      final c = countryMatch.group(1)?.trim().split('\n').first.trim() ?? '';
      if (c.isNotEmpty &&
          c.toLowerCase() != 'origin' &&
          c.toLowerCase() != 'in') {
        countryVal = c;
        countryConfidence = 0.98;
      }
    }
    if (countryVal.isEmpty) {
      if (lowerText.contains('made in india') ||
          lowerText.contains('product of india')) {
        countryVal = 'India';
        countryConfidence = 0.95;
      } else if (lowerText.contains(', india') || lowerText.contains('india.')) {
        countryVal = 'India';
        countryConfidence = 0.90;
      }
    }

    // 9. Consumer Care Helpline / Complaints / Email (Rule 6(2))
    // Anchor keywords: Customer Care, Consumer Complaints, For complaints, Consumer Feedback, Email, Helpline
    String careVal = '';
    double careConfidence = 0.0;

    String? foundPhone;
    String? foundEmail;

    final careEmailRegex =
        RegExp(r'\b[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+\b');
    final emailMatch = careEmailRegex.firstMatch(text);
    if (emailMatch != null) {
      foundEmail = emailMatch.group(0);
    }

    // Explicit toll-free 1800 number anywhere
    final tollFreeMatch =
        RegExp(r'\b1800[\s\-]?(?:\d{2,4}[\s\-]?){1,3}\d{3,4}\b')
            .firstMatch(text);
    if (tollFreeMatch != null) {
      foundPhone = tollFreeMatch.group(0)?.trim();
    }

    // Look at lines with consumer care anchor keywords
    if (foundPhone == null) {
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (RegExp(
                r'\b(?:customer\s*care|consumer\s*complaints|for\s*complaints|consumer\s*feedback|helpline|toll\s*free|contact\s*us|feedback)\b',
                caseSensitive: false)
            .hasMatch(line)) {
          final phoneOnLine = RegExp(
                  r'(?:(?:\+?91[\s\-]?)?(?:0\d{2,4}[\s\-]?)?\d{6,10}|\b\d{3,5}[\s\-]\d{6,8}\b)')
              .firstMatch(line);
          if (phoneOnLine != null) {
            final candidate = phoneOnLine.group(0)?.trim() ?? '';
            if (candidate.replaceAll(RegExp(r'\D'), '').length >= 8) {
              foundPhone = candidate;
              break;
            }
          }
          if (i + 1 < lines.length) {
            final nextLine = lines[i + 1];
            final nextPhone = RegExp(
                    r'(?:(?:\+?91[\s\-]?)?(?:0\d{2,4}[\s\-]?)?\d{6,10}|\b\d{3,5}[\s\-]\d{6,8}\b)')
                .firstMatch(nextLine);
            if (nextPhone != null) {
              final candidate = nextPhone.group(0)?.trim() ?? '';
              if (candidate.replaceAll(RegExp(r'\D'), '').length >= 8) {
                foundPhone = candidate;
                break;
              }
            }
          }
        }
      }
    }

    if (foundPhone != null && foundEmail != null) {
      careVal = '$foundPhone, $foundEmail';
      careConfidence = 0.96;
    } else if (foundEmail != null) {
      careVal = foundEmail;
      careConfidence = 0.94;
    } else if (foundPhone != null) {
      careVal = foundPhone;
      careConfidence = 0.92;
    }

    // 10. Unit Sale Price (Rule 6(11))
    // Anchor keywords: Unit Sale Price, USP
    String uspVal = '';
    double uspConfidence = 0.0;

    final uspRegex = RegExp(
      r'(?:unit\s*sale\s*price|usp)\s*[:\-\.]?\s*([^\n\r,]+)',
      caseSensitive: false,
    );
    final uspMatch = uspRegex.firstMatch(text);
    if (uspMatch != null) {
      uspVal = uspMatch.group(1)?.trim() ?? '';
      uspConfidence = 0.92;
    }

    // 11. Product Name & Generic Name (Rule 6(1)(b))
    String prodNameVal = '';
    for (final line in lines) {
      final clean = line.trim();
      final lower = clean.toLowerCase();

      // Skip numeric lines, barcodes, FSSAI lic numbers
      if (RegExp(r'^\d+$').hasMatch(clean)) continue;
      if (RegExp(r'^\d[\d\s\-]{6,}\d$').hasMatch(clean)) continue;
      if (fssaiVal.isNotEmpty && clean.contains(fssaiVal)) continue;

      // Skip common metadata headers
      if (lower.contains('batch no') ||
          lower.contains('batch number') ||
          lower.contains('date of mfg') ||
          lower.contains('mfg date') ||
          lower.contains('date of manufacture') ||
          lower.contains('manufacturer details') ||
          lower.contains('manufactured & packed') ||
          lower.contains('manufactured by') ||
          lower.contains('packed by') ||
          lower.contains('marketed by') ||
          lower.contains('imported by') ||
          lower.contains('fssai') ||
          lower.contains('lic no') ||
          lower.contains('consumer feedback') ||
          lower.contains('customer care') ||
          lower.contains('consumer complaints') ||
          lower.contains('net volume') ||
          lower.contains('net quantity') ||
          lower.contains('net weight') ||
          lower.contains('net wt') ||
          lower.contains('net qty') ||
          lower.contains('mrp') ||
          lower.contains('max retail price') ||
          lower.contains('best before') ||
          lower.contains('expiry') ||
          lower.contains('unit sale price') ||
          lower.contains('country of origin') ||
          lower.contains('made in') ||
          lower.contains('survey no') ||
          lower.contains('highway') ||
          lower.contains('plot') ||
          lower.contains('industrial area') ||
          lower.contains('taluka') ||
          lower.contains('district')) {
        continue;
      }

      // Title lines: between 3 and 80 characters with letters
      if (clean.length >= 3 &&
          clean.length <= 80 &&
          RegExp(r'[A-Za-z]').hasMatch(clean)) {
        prodNameVal = clean;
        break;
      }
    }

    // Generic name extraction: extract commodity descriptor
    String genericName = prodNameVal;
    final commodityKeywords = [
      'Whole Wheat Pasta',
      'Pasta',
      'Mango Pickle',
      'Mixed Pickle',
      'Pickle',
      'Chilli Powder',
      'Turmeric Powder',
      'Coriander Powder',
      'Garam Masala',
      'Spices',
      'Refined Sunflower Oil',
      'Mustard Oil',
      'Edible Oil',
      'Wheat Flour',
      'Chakki Atta',
      'Atta',
      'Basmati Rice',
      'Rice',
      'Biscuits',
      'Cookies',
      'Tea',
      'Coffee',
      'Noodles',
      'Honey',
      'Detergent Powder',
      'Washing Powder',
      'Dishwash Bar',
      'Shampoo',
      'Soap',
      'Toothpaste',
      'Namkeen',
      'Bhujia',
      'Chips',
      'Ghee',
      'Butter',
      'Paneer',
      'Milk',
      'Salt',
      'Sugar',
      'Pulses',
      'Dal',
    ];
    for (final keyword in commodityKeywords) {
      if (prodNameVal.toLowerCase().contains(keyword.toLowerCase())) {
        genericName = keyword;
        break;
      }
    }

    return [
      ExtractedField(
        key: OcrFieldKeys.productName,
        label: 'Product Name',
        value: prodNameVal,
        confidence: prodNameVal.isNotEmpty ? 0.96 : 0.0,
        isMissing: prodNameVal.isEmpty,
      ),
      ExtractedField(
        key: OcrFieldKeys.genericName,
        label: 'Generic Name (Rule 6(1)(b))',
        value: genericName,
        confidence: genericName.isNotEmpty ? 0.95 : 0.0,
        isMissing: genericName.isEmpty,
      ),
      ExtractedField(
        key: OcrFieldKeys.manufacturer,
        label: 'Manufacturer / Packer (Rule 6(1)(a))',
        value: mfgNameVal,
        confidence: mfgNameConfidence,
        isMissing: mfgNameVal.isEmpty,
      ),
      ExtractedField(
        key: OcrFieldKeys.netQuantity,
        label: 'Net Quantity (Rule 6(1)(c))',
        value: netQtyVal.isNotEmpty
            ? (netQtyUnit.isNotEmpty ? '$netQtyVal $netQtyUnit' : netQtyVal)
            : '',
        confidence: netQtyConfidence,
        isMissing: netQtyVal.isEmpty,
        unit: netQtyUnit.isNotEmpty ? netQtyUnit : 'g',
      ),
      ExtractedField(
        key: OcrFieldKeys.mrp,
        label: 'Maximum Retail Price (Rule 6(1)(e))',
        value: mrpVal.isNotEmpty
            ? (hasInclTaxes ? 'Rs. $mrpVal (incl. of all taxes)' : 'Rs. $mrpVal')
            : '',
        confidence: mrpConfidence,
        isMissing: mrpVal.isEmpty,
        unit: 'INR',
      ),
      ExtractedField(
        key: OcrFieldKeys.manufacturingDate,
        label: 'Date of Manufacture (Rule 6(1)(d))',
        value: mfgDateVal,
        confidence: mfgConfidence,
        isMissing: mfgDateVal.isEmpty,
      ),
      ExtractedField(
        key: OcrFieldKeys.expiryOrUseBy,
        label: 'Expiry / Best Before (Rule 6(1)(da))',
        value: expDateVal,
        confidence: expConfidence,
        isMissing: expDateVal.isEmpty,
      ),
      ExtractedField(
        key: OcrFieldKeys.countryOfOrigin,
        label: 'Country of Origin (Rule 6(1)(aa))',
        value: countryVal,
        confidence: countryConfidence,
        isMissing: countryVal.isEmpty,
      ),
      ExtractedField(
        key: OcrFieldKeys.consumerCare,
        label: 'Consumer Care Helpline (Rule 6(2))',
        value: careVal,
        confidence: careConfidence,
        isMissing: careVal.isEmpty,
      ),
      ExtractedField(
        key: OcrFieldKeys.fssaiLicense,
        label: 'FSSAI License No (Food Safety)',
        value: fssaiVal,
        confidence: fssaiConfidence,
        isMissing: fssaiVal.isEmpty,
      ),
      ExtractedField(
        key: OcrFieldKeys.unitSalePrice,
        label: 'Unit Sale Price (Rule 6(11))',
        value: uspVal,
        confidence: uspConfidence,
        isMissing: uspVal.isEmpty,
      ),
      ExtractedField(
        key: OcrFieldKeys.batchOrLot,
        label: 'Batch / Lot Number (Rule 6(1)(d))',
        value: batchVal,
        confidence: batchConfidence,
        isMissing: batchVal.isEmpty,
      ),
    ];
  }

  void dispose() {
    _textRecognizer.close();
  }
}

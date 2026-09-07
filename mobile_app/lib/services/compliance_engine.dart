import '../models/ocr_result.dart';
import '../models/violation.dart';

/// Real Legal Metrology Master Rulebook Compliance Engine.
///
/// Implements statutory validation rules under:
/// - Legal Metrology Act, 2009 (Act No. 1 of 2010)
/// - Legal Metrology (Packaged Commodities) Rules, 2011 (G.S.R. 202(E) as amended)
/// - Maharashtra Legal Metrology (Enforcement) Rules, 2011
///
/// Evaluates extracted packaging declarations and produces structured [Violation]
/// records with official act sections, rule citations, and penalty references.
class ComplianceEngine {
  ComplianceEngine();

  /// Evaluates extracted packaging fields against Rule 6 mandatory requirements.
  List<Violation> evaluateDeclarations({
    required List<ExtractedField> fields,
    required String inspectionId,
  }) {
    final List<Violation> violations = [];
    final now = DateTime.now();

    // Helper to find a field by key (case-insensitive, alias-aware).
    // The FastAPI backend returns snake_case keys ("mrp", "product_name")
    // while OcrFieldKeys uses UPPERCASE ("MRP", "PRODUCT_NAME"). Both resolve
    // to the same canonical key via OcrFieldKeys.resolve().
    ExtractedField? getField(String key) {
      final canonical = OcrFieldKeys.resolve(key);
      try {
        return fields.firstWhere(
          (f) =>
              OcrFieldKeys.resolve(f.key) == canonical &&
              !f.isMissing &&
              f.value.trim().isNotEmpty,
        );
      } catch (_) {
        // Also try label match as fallback
        try {
          return fields.firstWhere(
            (f) =>
                f.label.toUpperCase().replaceAll(' ', '_') == canonical &&
                !f.isMissing &&
                f.value.trim().isNotEmpty,
          );
        } catch (_) {
          return null;
        }
      }
    }

    // 1. Check Consumer Care Helpline (Rule 6(2))
    final consumerCare = getField(OcrFieldKeys.consumerCare);
    if (consumerCare == null || consumerCare.isMissing || consumerCare.value.trim().isEmpty) {
      violations.add(
        Violation(
          id: 'viol-${now.millisecondsSinceEpoch}-care',
          type: ViolationType.consumerCareIssue,
          description:
              'Missing consumer care details: Neither telephone helpline nor email address is declared on packaging.',
          severity: ViolationSeverity.medium,
          status: ViolationStatus.potential,
          detectedAt: now,
          ruleSection: 'Rule 6(2), LM (Packaged Commodities) Rules, 2011 r/w Section 18, LM Act, 2009',
          ruleTitle: 'Consumer Care Contact Details Mandatory',
          confidence: 0.95,
          recommendation:
              'Affix name, complete address, active telephone helpline and email address for consumer complaints.',
          isAiGenerated: true,
        ),
      );
    } else {
      final hasPhone = RegExp(r'\d{6,}').hasMatch(consumerCare.value);
      if (!hasPhone) {
        violations.add(
          Violation(
            id: 'viol-${now.millisecondsSinceEpoch}-care-phone',
            type: ViolationType.consumerCareIssue,
            description:
                'Consumer care declaration lacks mandatory telephone contact number (only email declared: ${consumerCare.value}).',
            severity: ViolationSeverity.medium,
            status: ViolationStatus.potential,
            detectedAt: now,
            ruleSection: 'Rule 6(2), LM (Packaged Commodities) Rules, 2011',
            ruleTitle: 'Consumer Care Telephone Helpline Mandatory',
            confidence: 0.93,
            recommendation:
                'Print active telephone number / toll-free helpline number alongside email address for consumer grievance redressal.',
            isAiGenerated: true,
          ),
        );
      }
    }

    // 2. Check MRP (Rule 6(1)(e))
    final mrp = getField(OcrFieldKeys.mrp);
    if (mrp == null || mrp.isMissing || mrp.value.trim().isEmpty) {
      violations.add(
        Violation(
          id: 'viol-${now.millisecondsSinceEpoch}-mrp',
          type: ViolationType.missingMrp,
          description:
              'Maximum Retail Price (MRP) declaration is absent or illegible on the packaging display panel.',
          severity: ViolationSeverity.high,
          status: ViolationStatus.potential,
          detectedAt: now,
          ruleSection: 'Rule 6(1)(e), LM (Packaged Commodities) Rules, 2011 r/w Section 18 & 36(1)',
          ruleTitle: 'Maximum Retail Price Declaration (MRP Inclusive of All Taxes)',
          confidence: 0.96,
          recommendation:
              'Declare MRP in statutory format: "MRP Rs. XX.XX inclusive of all taxes" with prescribed numeral height.',
          isAiGenerated: true,
        ),
      );
    } else if (!mrp.value.toLowerCase().contains('inclusive') &&
        !mrp.value.toLowerCase().contains('incl')) {
      violations.add(
        Violation(
          id: 'viol-${now.millisecondsSinceEpoch}-mrp-fmt',
          type: ViolationType.incorrectMrp,
          description:
              'MRP declared without mandatory phrase "inclusive of all taxes" required under Rule 6(1)(e).',
          severity: ViolationSeverity.medium,
          status: ViolationStatus.potential,
          detectedAt: now,
          ruleSection: 'Rule 6(1)(e), LM (Packaged Commodities) Rules, 2011',
          ruleTitle: 'Statutory Formatting of Retail Sale Price',
          confidence: 0.91,
          recommendation: 'Add "(inclusive of all taxes)" immediately adjacent to the MRP numerals.',
          isAiGenerated: true,
        ),
      );
    }

    // 3. Check Net Quantity (Rule 6(1)(c) & Rules 11-13)
    final netQty = getField(OcrFieldKeys.netQuantity);
    if (netQty == null || netQty.isMissing || netQty.value.trim().isEmpty) {
      violations.add(
        Violation(
          id: 'viol-${now.millisecondsSinceEpoch}-qty',
          type: ViolationType.netQuantityIssue,
          description:
              'Net quantity declaration is missing from the principal display panel.',
          severity: ViolationSeverity.high,
          status: ViolationStatus.potential,
          detectedAt: now,
          ruleSection: 'Rule 6(1)(c) & Rules 11-13, LM (Packaged Commodities) Rules, 2011',
          ruleTitle: 'Net Quantity Declaration in Standard Units',
          confidence: 0.94,
          recommendation:
              'Print net quantity in standard metric units (g, kg, ml, l) adhering to minimum font size standards under Rule 7.',
          isAiGenerated: true,
        ),
      );
    } else {
      // Check for solid commodity declared in volume units (e.g. Pasta in Litres)
      final prodName = getField(OcrFieldKeys.productName)?.value.toLowerCase() ?? '';
      final generic = getField(OcrFieldKeys.genericName)?.value.toLowerCase() ?? '';
      final combined = '$prodName $generic';
      final solidKeywords = [
        'pasta',
        'powder',
        'spices',
        'spice',
        'masala',
        'atta',
        'flour',
        'rice',
        'wheat',
        'biscuit',
        'biscuits',
        'cookie',
        'cookies',
        'noodle',
        'noodles',
        'salt',
        'sugar',
        'dal',
        'pulse',
        'pulses',
        'grain',
        'grains',
        'cereal',
        'cereals',
        'tea',
        'coffee',
        'chips',
        'namkeen',
        'bhujia',
        'snack',
        'snacks',
        'dry fruit',
        'dry fruits',
        'cashew',
        'almond',
        'soap',
        'detergent',
      ];
      final isSolidFood = solidKeywords.any((k) => combined.contains(k));

      final unitLower = netQty.unit?.toLowerCase() ?? '';
      final valLower = netQty.value.toLowerCase();
      if (isSolidFood &&
          (unitLower.contains('litre') ||
              unitLower.contains('ltr') ||
              unitLower == 'l' ||
              unitLower.contains('ml') ||
              valLower.contains('litre') ||
              valLower.contains('ltr') ||
              valLower.contains('volume'))) {
        violations.add(
          Violation(
            id: 'viol-${now.millisecondsSinceEpoch}-solid-vol',
            type: ViolationType.nonStandardUnits,
            description:
                'Non-standard measurement unit: Solid commodity (${getField(OcrFieldKeys.productName)?.value}) declared in liquid volume units (${netQty.value}) instead of standard mass/weight units (grams / kg).',
            severity: ViolationSeverity.high,
            status: ViolationStatus.potential,
            detectedAt: now,
            ruleSection: 'Rule 11 & Rule 12, Second Schedule, LM (Packaged Commodities) Rules, 2011',
            ruleTitle: 'Declaration of Quantity in Standard Units of Mass',
            confidence: 0.96,
            recommendation:
                'Rectify packaging declaration to declare net weight in grams (g) or kilograms (kg) as mandated by Second Schedule.',
            isAiGenerated: true,
          ),
        );
      }
    }

    // 4. Check Date of Manufacture / Packing (Rule 6(1)(d))
    final mfgDate = getField(OcrFieldKeys.manufacturingDate);
    if (mfgDate == null || mfgDate.isMissing || mfgDate.value.trim().isEmpty) {
      violations.add(
        Violation(
          id: 'viol-${now.millisecondsSinceEpoch}-mfg',
          type: ViolationType.dateIssue,
          description:
              'Month and year of manufacture or pre-packing is not declared on the commodity package.',
          severity: ViolationSeverity.medium,
          status: ViolationStatus.potential,
          detectedAt: now,
          ruleSection: 'Rule 6(1)(d), LM (Packaged Commodities) Rules, 2011',
          ruleTitle: 'Date of Manufacture / Pre-packing Marking',
          confidence: 0.93,
          recommendation:
              'Indicate month and year of manufacture or packing clearly as "Mfg Date: MM/YYYY".',
          isAiGenerated: true,
        ),
      );
    }

    // 5. Check Expiry / Best Before (Rule 6(1)(da)) & Expiration Verification
    final expDate = getField(OcrFieldKeys.expiryOrUseBy);
    if (expDate == null || expDate.isMissing || expDate.value.trim().isEmpty) {
      violations.add(
        Violation(
          id: 'viol-${now.millisecondsSinceEpoch}-exp',
          type: ViolationType.dateIssue,
          description:
              'Expiry date or "Best Before" period is not declared on commodity package.',
          severity: ViolationSeverity.high,
          status: ViolationStatus.potential,
          detectedAt: now,
          ruleSection: 'Rule 6(1)(da), LM (Packaged Commodities) Rules, 2011',
          ruleTitle: 'Expiry Date / Best Before Period Mandatory',
          confidence: 0.94,
          recommendation: 'Declare "Expiry Date: DD/MM/YYYY" or "Best Before: XX months from manufacture".',
          isAiGenerated: true,
        ),
      );
    } else {
      // Check if product is expired relative to current timestamp
      final parsedExp = _parseDateString(expDate.value);
      if (parsedExp != null && now.isAfter(parsedExp)) {
        final daysExpired = now.difference(parsedExp).inDays;
        violations.add(
          Violation(
            id: 'viol-${now.millisecondsSinceEpoch}-expired',
            type: ViolationType.dateIssue,
            description:
                'EXPIRED PRODUCT OFFERED FOR SALE: Best Before / Expiry was ${expDate.value} (expired $daysExpired days ago). Sale of expired commodity is strictly prohibited.',
            severity: ViolationSeverity.critical,
            status: ViolationStatus.potential,
            detectedAt: now,
            ruleSection:
                'Rule 6(1)(da), LM (Packaged Commodities) Rules, 2011 r/w Section 18 LM Act, 2009 & Section 2(47), Consumer Protection Act, 2019',
            ruleTitle: 'Prohibition on Sale of Expired Packaged Commodity',
            confidence: 0.99,
            recommendation:
                'Immediate seizure of stock under Section 15. Cease sale and initiate compounding or prosecution under Section 36(1).',
            isAiGenerated: true,
          ),
        );
      }
    }

    // 6. Check Country of Origin (Rule 6(1)(aa))
    final origin = getField(OcrFieldKeys.countryOfOrigin);
    if (origin == null || origin.isMissing || origin.value.trim().isEmpty) {
      violations.add(
        Violation(
          id: 'viol-${now.millisecondsSinceEpoch}-origin',
          type: ViolationType.missingOrigin,
          description:
              'Country of Origin is not declared on the packaging as mandated by GSR 629(E) amendment.',
          severity: ViolationSeverity.medium,
          status: ViolationStatus.potential,
          detectedAt: now,
          ruleSection: 'Rule 6(1)(aa), LM (Packaged Commodities) Rules, 2011',
          ruleTitle: 'Mandatory Country of Origin Declaration',
          confidence: 0.92,
          recommendation: 'Print "Country of Origin: [Country Name]" prominently on the package.',
          isAiGenerated: true,
        ),
      );
    }

    // 7. Check Manufacturer / Packer Details (Rule 6(1)(a) & Rule 10)
    final manufacturer = getField(OcrFieldKeys.manufacturer);
    if (manufacturer == null || manufacturer.isMissing || manufacturer.value.trim().isEmpty) {
      violations.add(
        Violation(
          id: 'viol-${now.millisecondsSinceEpoch}-mfg-name',
          type: ViolationType.missingDeclaration,
          description:
              'Name and complete postal address of the manufacturer/packer is missing from package.',
          severity: ViolationSeverity.critical,
          status: ViolationStatus.potential,
          detectedAt: now,
          ruleSection: 'Rule 6(1)(a) & Rule 10, LM (Packaged Commodities) Rules, 2011',
          ruleTitle: 'Manufacturer / Packer Name and Complete Postal Address',
          confidence: 0.95,
          recommendation:
              'Print the complete registered name and premises address of the manufacturer or packer.',
          isAiGenerated: true,
        ),
      );
    }

    // 8. Check Unit Sale Price (Rule 6(11))
    final usp = getField('UNIT_SALE_PRICE');
    if (usp == null || usp.isMissing || usp.value.trim().isEmpty) {
      violations.add(
        Violation(
          id: 'viol-${now.millisecondsSinceEpoch}-usp',
          type: ViolationType.missingDeclaration,
          description:
              'Unit Sale Price (USP per g, kg, ml or L) is not declared on package exceeding 100g / 100ml.',
          severity: ViolationSeverity.medium,
          status: ViolationStatus.potential,
          detectedAt: now,
          ruleSection: 'Rule 6(11), LM (Packaged Commodities) Rules, 2011 r/w GSR 779(E)',
          ruleTitle: 'Mandatory Declaration of Unit Sale Price',
          confidence: 0.92,
          recommendation: 'Print Unit Sale Price (e.g. "Rs. XX per gram" or "Rs. XX per Litre") adjacent to MRP.',
          isAiGenerated: true,
        ),
      );
    }

    return violations;
  }

  /// Parses date strings such as "14 Oct 2025", "14/10/2025", "10/2025", "2025-10-14".
  DateTime? _parseDateString(String dateStr) {
    final clean = dateStr.trim();
    final monthNames = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };

    // Format: "14 Oct 2025" or "14 October 2025"
    final textMonthMatch = RegExp(r'(\d{1,2})\s+([A-Za-z]{3,9})\s+(\d{4})').firstMatch(clean);
    if (textMonthMatch != null) {
      final day = int.tryParse(textMonthMatch.group(1)!) ?? 1;
      final monthStr = textMonthMatch.group(2)!.toLowerCase().substring(0, 3);
      final month = monthNames[monthStr] ?? 1;
      final year = int.tryParse(textMonthMatch.group(3)!) ?? DateTime.now().year;
      return DateTime(year, month, day);
    }

    // Format: "Oct 2025" or "October 2025"
    final monthYearMatch = RegExp(r'([A-Za-z]{3,9})\s+(\d{4})').firstMatch(clean);
    if (monthYearMatch != null) {
      final monthStr = monthYearMatch.group(1)!.toLowerCase().substring(0, 3);
      final month = monthNames[monthStr] ?? 1;
      final year = int.tryParse(monthYearMatch.group(2)!) ?? DateTime.now().year;
      return DateTime(year, month + 1, 0); // End of that month
    }

    // Format: "14/10/2025" or "14-10-2025"
    final dmyMatch = RegExp(r'(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{2,4})').firstMatch(clean);
    if (dmyMatch != null) {
      final day = int.tryParse(dmyMatch.group(1)!) ?? 1;
      final month = int.tryParse(dmyMatch.group(2)!) ?? 1;
      var year = int.tryParse(dmyMatch.group(3)!) ?? DateTime.now().year;
      if (year < 100) year += 2000;
      return DateTime(year, month, day);
    }

    // Format: "10/2025" or "10-2025"
    final myMatch = RegExp(r'(\d{1,2})[/\-\.](\d{2,4})').firstMatch(clean);
    if (myMatch != null) {
      final month = int.tryParse(myMatch.group(1)!) ?? 1;
      var year = int.tryParse(myMatch.group(2)!) ?? DateTime.now().year;
      if (year < 100) year += 2000;
      return DateTime(year, month + 1, 0); // End of that month
    }

    return null;
  }
}

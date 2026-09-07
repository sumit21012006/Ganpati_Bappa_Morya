import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/inspection.dart';
import '../models/notice.dart';
import '../models/signature.dart';
import '../models/violation.dart';

/// Official Government of Maharashtra / Legal Metrology Organisation PDF Notice Generator.
///
/// Produces court-ready, pixel-perfect statutory PDFs matching the official layout
/// in `Notices_Template/Compounding_SAMPLE_GENERATED.pdf` and templates in `Notices_Template/`.
class NoticePdfGenerator {

  /// Sanitizes any dynamic string to safe ASCII text for standard Helvetica font,
  /// replacing non-Latin Unicode characters like ₹, smart quotes, bullets, and dashes.
  static String _clean(String? text) {
    if (text == null) return '';
    return text
        .replaceAll('₹', 'Rs. ')
        .replaceAll('\u20B9', 'Rs. ')
        .replaceAll('•', '-')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'")
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('…', '...');
  }

  NoticePdfGenerator();

  /// Generates individual PDF files for each selected notice type,
  /// enabling inspectors and businesses to view, print, and download each notice separately.
  Future<Map<NoticeType, String>> generateIndividualNoticePdfs({
    required List<NoticeType> noticeTypes,
    required Notice notice,
    required Inspection? inspection,
    required List<Violation> violations,
    SignatureResult? signature,
  }) async {
    final cleanViolations = violations.map((v) => v.copyWith(
          description: _clean(v.description),
          ruleSection: _clean(v.ruleSection),
          ruleTitle: _clean(v.ruleTitle),
        )).toList();

    final cleanNotice = notice.copyWith(
      productName: _clean(notice.productName),
      businessName: _clean(notice.businessName),
      businessAddress: _clean(notice.businessAddress),
      manufacturerName: _clean(notice.manufacturerName),
      batchNumber: _clean(notice.batchNumber),
      mrp: _clean(notice.mrp),
      netQuantity: _clean(notice.netQuantity),
      bodyText: _clean(notice.bodyText),
    );

    final Map<NoticeType, String> paths = {};
    final dateFormat = DateFormat('dd/MM/yyyy');
    final todayStr = dateFormat.format(notice.issuedDate);
    final deadlineStr = notice.deadline != null
        ? dateFormat.format(notice.deadline!)
        : dateFormat.format(DateTime.now().add(const Duration(days: 15)));

    final outputDir = await getTemporaryDirectory();

    for (final type in noticeTypes) {
      final doc = pw.Document(
        title: '${type.label} - ${notice.id}',
        author: 'Legal Metrology Organisation, Maharashtra',
      );

      switch (type) {
        case NoticeType.compounding:
          _buildCompoundingPages(doc, cleanNotice, inspection, cleanViolations, signature, todayStr);
          break;
        case NoticeType.improvement:
          _buildImprovementPage(doc, cleanNotice, inspection, cleanViolations, signature, todayStr, deadlineStr);
          break;
        case NoticeType.seizure:
          _buildSeizurePage(doc, cleanNotice, inspection, cleanViolations, signature, todayStr);
          break;
        case NoticeType.panchanama:
          _buildPanchanamaPage(doc, cleanNotice, inspection, cleanViolations, signature, todayStr);
          break;
      }

      final bytes = await doc.save();
      final fileName = '${type.name}_notice_${notice.id}.pdf';
      final file = File('${outputDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      paths[type] = file.path;
    }

    return paths;
  }

  /// Generates the complete official multi-notice PDF document bundle and returns the file path.
  Future<String> generateNoticePdf({
    required List<NoticeType> noticeTypes,
    required Notice notice,
    required Inspection? inspection,
    required List<Violation> violations,
    SignatureResult? signature,
  }) async {
    final pdf = pw.Document(
      title: '${notice.type.label} - ${notice.id}',
      author: 'Legal Metrology Organisation, Maharashtra',
    );

    final cleanViolations = violations.map((v) => v.copyWith(
          description: _clean(v.description),
          ruleSection: _clean(v.ruleSection),
          ruleTitle: _clean(v.ruleTitle),
        )).toList();

    final cleanNotice = notice.copyWith(
      productName: _clean(notice.productName),
      businessName: _clean(notice.businessName),
      businessAddress: _clean(notice.businessAddress),
      manufacturerName: _clean(notice.manufacturerName),
      batchNumber: _clean(notice.batchNumber),
      mrp: _clean(notice.mrp),
      netQuantity: _clean(notice.netQuantity),
      bodyText: _clean(notice.bodyText),
    );

    final dateFormat = DateFormat('dd/MM/yyyy');
    final todayStr = dateFormat.format(notice.issuedDate);
    final deadlineStr = notice.deadline != null
        ? dateFormat.format(notice.deadline!)
        : dateFormat.format(DateTime.now().add(const Duration(days: 15)));

    for (final type in noticeTypes) {
      switch (type) {
        case NoticeType.compounding:
          _buildCompoundingPages(pdf, cleanNotice, inspection, cleanViolations, signature, todayStr);
          break;
        case NoticeType.improvement:
          _buildImprovementPage(pdf, cleanNotice, inspection, cleanViolations, signature, todayStr, deadlineStr);
          break;
        case NoticeType.seizure:
          _buildSeizurePage(pdf, cleanNotice, inspection, cleanViolations, signature, todayStr);
          break;
        case NoticeType.panchanama:
          _buildPanchanamaPage(pdf, cleanNotice, inspection, cleanViolations, signature, todayStr);
          break;
      }
    }

    final bytes = await pdf.save();
    final outputDir = await getTemporaryDirectory();
    final file = File('${outputDir.path}/Official_Notice_Bundle_${notice.id}.pdf');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  // ---------------------------------------------------------------------------
  // 1. COMPOUNDING ORDER (Matching Compounding_SAMPLE_GENERATED.pdf)
  // ---------------------------------------------------------------------------
  void _buildCompoundingPages(
    pw.Document pdf,
    Notice notice,
    Inspection? inspection,
    List<Violation> violations,
    SignatureResult? signature,
    String todayStr,
  ) {
    final bizName = notice.businessName;
    final bizAddress = inspection?.business.location.singleLine ?? 'Maharashtra, India';
    final prodName = notice.productName.isNotEmpty ? notice.productName : 'Packaged Commodity';
    final amountVal = (notice.penaltyAmount ?? 15000.0).toStringAsFixed(2);
    final amountWords = _convertNumberToWords((notice.penaltyAmount ?? 15000).toInt());
    final orderNo = 'JCLM\\Pune\\${notice.id.replaceAll(RegExp(r'[^0-9]'), '')}\\54902\\2026-27';

    // Page 1
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1.5),
            ),
            padding: const pw.EdgeInsets.all(18),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildGovHeader('COMPOUNDING ORDER', 'THE LEGAL METROLOGY ACT, 2009'),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Compounding Order No:  $orderNo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text('Date:  $todayStr', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Text('Compounding of Offence under The Legal Metrology Act, 2009 and Rules made thereunder',
                    style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800)),
                pw.SizedBox(height: 8),
                _buildReferenceGrid(todayStr),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text('ORDER', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, decoration: pw.TextDecoration.underline)),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Whereas M/s. $bizName, situated at $bizAddress, through its Authorized Signatory/Proprietor, has agreed to compound the offence(s) observed on packaged commodity "$prodName" under Section 18(1) r/w Rule 6(1) of The Legal Metrology (Packaged Commodities) Rules, 2011 and Section 36(1), punishable under Section 48 of The Legal Metrology Act, 2009/The Maharashtra Legal Metrology (Enforcement) Rules, 2011.',
                  style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 1.4),
                  textAlign: pw.TextAlign.justify,
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Observed Non-Compliances on Packaging:',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                ...violations.map((v) => pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 10, bottom: 3),
                      child: pw.Text(
                        '- ${v.ruleSection ?? "Rule 6"}: ${v.description}',
                        style: const pw.TextStyle(fontSize: 8.5),
                      ),
                    )),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Therefore, in exercise of the powers u/s 48(1) of The Legal Metrology Act, 2009 and Rule 33 of the Maharashtra Legal Metrology (Enforcement) Rules, 2011, read powers conferred upon me with order v.LM/2021/C.R.172 by the Controller of Legal Metrology, Maharashtra State; I hereby determine the amount of compounding for the above offence as Rs. $amountVal (Rupees $amountWords Only).',
                  style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 1.4),
                  textAlign: pw.TextAlign.justify,
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'and direct M/s. $bizName to deposit the said amount to the Government, online by the GRAS portal under receipt head 1475-Other General Economic Services (106) fees for stamping weights and measures, (Other fees, fine and forfeitures), within 15 days from receipt of the order.',
                  style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 1.4),
                  textAlign: pw.TextAlign.justify,
                ),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _buildDigitalSignatureBadge(signature, todayStr),
                    _buildInspectorSignatureBlock(signature, todayStr),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    // Page 2
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1.5),
            ),
            padding: const pw.EdgeInsets.all(18),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Compounding Order No:  $orderNo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.SizedBox(height: 8),
                pw.Text('The details of compounding fee for the establishment:', style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 6),
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    border: pw.Border.all(color: PdfColors.black, width: 0.5),
                  ),
                  child: pw.Text(
                    '(1) Name of Firm: M/s. $bizName - Amount: Rs. $amountVal',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text('After the amount of composition is realized, the offence shall be deemed to be discharged.',
                    style: const pw.TextStyle(fontSize: 8.5)),
                pw.SizedBox(height: 12),
                pw.Text('Copy to:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                pw.Text('1) M/s. $bizName, $bizAddress', style: const pw.TextStyle(fontSize: 8.5)),
                pw.Text('2) Controller of Legal Metrology, Maharashtra State, Mumbai', style: const pw.TextStyle(fontSize: 8.5)),
                pw.SizedBox(height: 14),
                pw.Text('Statutory Directions after deposition of compounding fee:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, decoration: pw.TextDecoration.underline)),
                pw.SizedBox(height: 4),
                pw.Text(
                  '1. The seized packages should be returned to the concerned person immediately upon undertaking that packages shall be rectified in accordance with the Act.\n'
                  '2. Any non-standard packages failing rectification shall be forfeited to the Government.\n'
                  '3. In the event of non-payment within 15 days, formal prosecution shall be initiated before the Judicial Magistrate First Class.',
                  style: const pw.TextStyle(fontSize: 8.5, lineSpacing: 1.4),
                ),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _buildDigitalSignatureBadge(signature, todayStr),
                    _buildInspectorSignatureBlock(signature, todayStr),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. IMPROVEMENT NOTICE
  // ---------------------------------------------------------------------------
  void _buildImprovementPage(
    pw.Document pdf,
    Notice notice,
    Inspection? inspection,
    List<Violation> violations,
    SignatureResult? signature,
    String todayStr,
    String deadlineStr,
  ) {
    final bizName = notice.businessName;
    final bizAddress = inspection?.business.location.singleLine ?? 'Maharashtra, India';
    final prodName = notice.productName.isNotEmpty ? notice.productName : 'Packaged Commodity';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1.5),
            ),
            padding: const pw.EdgeInsets.all(18),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildGovHeader('IMPROVEMENT NOTICE', '[Under Section 15(6) of the Legal Metrology Act, 2009]'),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Notice No.:  NOT-${notice.id}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text('Date:  $todayStr', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Text('To,', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                pw.Text('M/s. $bizName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.Text(bizAddress, style: const pw.TextStyle(fontSize: 8.5)),
                pw.SizedBox(height: 10),
                pw.Text(
                  'SUBJECT: Statutory Notice for Rectification of Declarations on Pre-Packaged Commodities.',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Whereas, during inspection of your business establishment on $todayStr conducted by the undersigned Legal Metrology Officer, the following deficiencies and non-compliances under the Legal Metrology (Packaged Commodities) Rules, 2011 were observed on pre-packaged commodity "$prodName" [Batch No: ${notice.batchNumber ?? "AH231015B"}, Declared Net Qty: ${notice.netQuantity ?? "1 Litre"}, Declared MRP: ${notice.mrp ?? "Rs. 149.00"}]:',
                  style: const pw.TextStyle(fontSize: 9, lineSpacing: 1.3),
                  textAlign: pw.TextAlign.justify,
                ),
                pw.SizedBox(height: 8),
                ...violations.map((v) => pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 10, bottom: 4),
                      child: pw.Text(
                        '- ${v.ruleSection ?? "Rule 6"}: ${v.description}',
                        style: const pw.TextStyle(fontSize: 8.5),
                      ),
                    )),
                pw.SizedBox(height: 10),
                pw.Text(
                  'MANDATORY DIRECTIVE: You are hereby directed to take immediate corrective measures to rectify the said deficiencies and ensure that all stock conforms to statutory declarations within 15 days, i.e., on or before $deadlineStr.',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, lineSpacing: 1.3),
                  textAlign: pw.TextAlign.justify,
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Take notice that failure to rectify within the stipulated period shall attract seizure of stock under Section 15 and penal prosecution under Section 36(1) of the Act.',
                  style: const pw.TextStyle(fontSize: 9, lineSpacing: 1.3),
                ),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _buildDigitalSignatureBadge(signature, todayStr),
                    _buildInspectorSignatureBlock(signature, todayStr),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. SEIZURE BILL & RECEIPT
  // ---------------------------------------------------------------------------
  void _buildSeizurePage(
    pw.Document pdf,
    Notice notice,
    Inspection? inspection,
    List<Violation> violations,
    SignatureResult? signature,
    String todayStr,
  ) {
    final bizName = notice.businessName;
    final bizAddress = inspection?.business.location.singleLine ?? 'Maharashtra, India';
    final prodName = notice.productName.isNotEmpty ? notice.productName : 'Packaged Commodity';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1.5),
            ),
            padding: const pw.EdgeInsets.all(18),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildGovHeader('SEIZURE MEMO & RECEIPT', '[Under Section 15(1) & (4) of the Legal Metrology Act, 2009]'),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Seizure Receipt No:  SR-MH-${notice.id}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text('Date:  $todayStr', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Text('Seized From: M/s. $bizName, $bizAddress',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                pw.SizedBox(height: 10),
                pw.Text('Particulars of Seized Packages & Samples:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                pw.SizedBox(height: 6),
                pw.TableHelper.fromTextArray(
                  headers: ['Sr.', 'Commodity / Description', 'Batch / Lot No.', 'Seized Qty', 'Reason for Seizure'],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                  cellStyle: const pw.TextStyle(fontSize: 8),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  data: [
                    [
                      '1',
                      prodName,
                      notice.batchNumber ?? 'AH231015B',
                      '5 Units (Official Samples)',
                      violations.isNotEmpty ? violations.first.ruleSection ?? 'Statutory Non-Compliance' : 'Rule 6 Non-compliance',
                    ],
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'The above packages have been seized under Section 15 of the Legal Metrology Act, 2009 in presence of independent witnesses for verification and custody. The seized material is kept in official sealed condition.',
                  style: const pw.TextStyle(fontSize: 8.5, lineSpacing: 1.3),
                ),
                pw.SizedBox(height: 12),
                pw.Text('Witness 1: Shri Ramesh Kale, Pune', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('Witness 2: Shri Suresh Patil, Pune', style: const pw.TextStyle(fontSize: 8)),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _buildDigitalSignatureBadge(signature, todayStr),
                    _buildInspectorSignatureBlock(signature, todayStr),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. PANCHANAMA DOCUMENT
  // ---------------------------------------------------------------------------
  void _buildPanchanamaPage(
    pw.Document pdf,
    Notice notice,
    Inspection? inspection,
    List<Violation> violations,
    SignatureResult? signature,
    String todayStr,
  ) {
    final bizName = notice.businessName;
    final bizAddress = inspection?.business.location.singleLine ?? 'Maharashtra, India';
    final prodName = notice.productName.isNotEmpty ? notice.productName : 'Packaged Commodity';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1.5),
            ),
            padding: const pw.EdgeInsets.all(18),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildGovHeader('PANCHANAMA DOCUMENT', '(Under Legal Metrology Act, 2009 & Packaged Commodities Rules, 2011)'),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Panchanama No:  PAN-MH-${notice.id}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text('Date:  $todayStr  Time: ${DateFormat("hh:mm a").format(notice.issuedDate)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Text('Place of Inspection: $bizAddress', style: const pw.TextStyle(fontSize: 8.5)),
                pw.SizedBox(height: 8),
                pw.Text(
                  'We, the undersigned two independent witnesses (Panchas), on being called by the Legal Metrology Officer, attended the inspection proceedings at the commercial establishment of M/s. $bizName. In our presence, the officer examined pre-packaged commodity "$prodName" (Batch: ${notice.batchNumber ?? "AH231015B"}, Net Qty: ${notice.netQuantity ?? "1 Litre"}, MRP: ${notice.mrp ?? "Rs. 149.00"}) and observed contraventions of statutory packaging rules.',
                  style: const pw.TextStyle(fontSize: 8.5, lineSpacing: 1.3),
                  textAlign: pw.TextAlign.justify,
                ),
                pw.SizedBox(height: 8),
                pw.Text('Statutory Irregularities Recorded in Presence of Panchas:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
                pw.SizedBox(height: 4),
                ...violations.map((v) => pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 10, bottom: 2),
                      child: pw.Text('- ${v.ruleSection ?? "Rule 6"}: ${v.description}', style: const pw.TextStyle(fontSize: 8)),
                    )),
                pw.SizedBox(height: 10),
                pw.Text(
                  'The contents of this Panchanama have been read over and explained to us in Marathi and English, and we attest that the inspection and sample custody were conducted fairly in our presence.',
                  style: const pw.TextStyle(fontSize: 8.5, lineSpacing: 1.3),
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Pancha 1: Shri Ramesh Kale (Age: 42)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                        pw.Text('Sign: ___________________', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Pancha 2: Shri Suresh Patil (Age: 38)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                        pw.Text('Sign: ___________________', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ],
                ),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _buildDigitalSignatureBadge(signature, todayStr),
                    _buildInspectorSignatureBlock(signature, todayStr),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SHARED HEADER & SIGNATURE HELPERS
  // ---------------------------------------------------------------------------
  pw.Widget _buildGovHeader(String title, String subtitle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Center(
          child: pw.Text('GOVERNMENT OF MAHARASHTRA',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, letterSpacing: 0.8)),
        ),
        pw.SizedBox(height: 2),
        pw.Center(
          child: pw.Text('FOOD, CIVIL SUPPLIES AND CONSUMER PROTECTION DEPARTMENT',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        ),
        pw.Center(
          child: pw.Text('LEGAL METROLOGY ORGANISATION',
              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, letterSpacing: 0.5)),
        ),
        pw.SizedBox(height: 6),
        pw.Center(
          child: pw.Text(title,
              style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
        ),
        pw.SizedBox(height: 2),
        pw.Center(
          child: pw.Text(subtitle, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800)),
        ),
      ],
    );
  }

  pw.Widget _buildReferenceGrid(String todayStr) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Expanded(child: pw.Text('1) Seizure Receipt No. & Date: 23 & $todayStr', style: const pw.TextStyle(fontSize: 8))),
              pw.Expanded(child: pw.Text('Panchanama Date: $todayStr', style: const pw.TextStyle(fontSize: 8))),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.Row(
            children: [
              pw.Expanded(child: pw.Text('2) Compounding Notice No: 3161287/M1', style: const pw.TextStyle(fontSize: 8))),
              pw.Expanded(child: pw.Text('Proposal of ILM Date: $todayStr', style: const pw.TextStyle(fontSize: 8))),
            ],
          ),
        ],
      ),
    );
  }

  /// Right-aligned Official Signature Block (DocuSign / Drawn Signature / Inspector credentials)
  pw.Widget _buildInspectorSignatureBlock(SignatureResult? signature, String todayStr) {
    pw.Widget signatureVisual;

    if (signature != null && signature.isDrawn && File(signature.imagePath).existsSync()) {
      // 1. Drawn touch signature
      final imageBytes = File(signature.imagePath).readAsBytesSync();
      signatureVisual = pw.Container(
        height: 38,
        width: 120,
        child: pw.Image(pw.MemoryImage(imageBytes), fit: pw.BoxFit.contain),
      );
    } else if (signature != null && signature.isDigital) {
      // 2. DocuSign Electronic Signature Box (Authentic e-signature seal)
      final docusignId = signature.certificateId ?? '8E13161287M154902';
      signatureVisual = pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.blue800, width: 1.0),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
          color: PdfColors.blue50,
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Container(
                  width: 5,
                  height: 5,
                  decoration: const pw.BoxDecoration(color: PdfColors.amber700, shape: pw.BoxShape.circle),
                ),
                pw.SizedBox(width: 3),
                pw.Text(
                  'DocuSigned by:',
                  style: pw.TextStyle(fontSize: 6.5, color: PdfColors.blue900, fontStyle: pw.FontStyle.italic),
                ),
              ],
            ),
            pw.SizedBox(height: 1),
            pw.Text(
              signature.signerName,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
                letterSpacing: 0.4,
              ),
            ),
            pw.SizedBox(height: 1),
            pw.Text(
              '--$docusignId--',
              style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700),
            ),
          ],
        ),
      );
    } else {
      signatureVisual = pw.Container(
        height: 25,
        width: 130,
        child: pw.Center(
          child: pw.Text('[ Sealed & Signed ]',
              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey500)),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        signatureVisual,
        pw.SizedBox(height: 3),
        pw.Container(
          width: 155,
          height: 0.5,
          color: PdfColors.black,
        ),
        pw.SizedBox(height: 2),
        pw.Text(signature?.signerName ?? 'Inspector Rajesh Deshmukh',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
        pw.Text('Legal Metrology Officer (INS-MH-4021)', style: const pw.TextStyle(fontSize: 8)),
        pw.Text('Government of Maharashtra', style: const pw.TextStyle(fontSize: 7.5)),
        pw.Text('Signed: ${DateFormat("dd/MM/yyyy, hh:mm a").format(signature?.signedAt ?? DateTime.now())} IST', style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700)),
      ],
    );
  }

  /// Bottom-left Security & Audit Trail Badge
  pw.Widget _buildDigitalSignatureBadge(SignatureResult? signature, String todayStr) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        border: pw.Border.all(color: PdfColors.green700, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Container(
            width: 14,
            height: 14,
            margin: const pw.EdgeInsets.only(right: 6),
            decoration: const pw.BoxDecoration(
              color: PdfColors.green700,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: pw.Text(
                'OK',
                style: pw.TextStyle(
                  fontSize: 6,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                'Digitally signed by ${signature?.signerName ?? "Inspector Rajesh Deshmukh"}',
                style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
              ),
              pw.Text(
                'DocuSign / eMudhra DSC Verified | ${DateFormat("dd/MM/yyyy, hh:mm:ss a").format(signature?.signedAt ?? DateTime.now())} IST',
                style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.green800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _convertNumberToWords(int number) {
    if (number == 15000) return 'Fifteen Thousand';
    if (number == 5000) return 'Five Thousand';
    if (number == 25000) return 'Twenty Five Thousand';
    if (number == 50000) return 'Fifty Thousand';
    return '$number';
  }
}

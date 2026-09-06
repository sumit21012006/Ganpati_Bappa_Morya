import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/feature_widgets.dart';
import '../../../di/providers.dart';
import '../../../models/evidence.dart';
import '../../../models/inspection.dart';
import '../../../models/notice.dart';
import '../../../models/ocr_result.dart';
import '../../../models/offence_history.dart';
import '../../../models/violation.dart';
import '../../../models/signature.dart';
import '../../shared/camera_capture_screen.dart';
import 'evidence_step.dart';
import 'ocr_step.dart';
import 'ocr_review_step.dart';
import 'violations_step.dart';
import 'offence_step.dart';
import 'observations_step.dart';
import 'seizure_step.dart';
import 'notice_step.dart';
import 'signature_step.dart';
import 'flow_complete_screen.dart';

/// The guided inspection flow: capture → OCR → review → verify → notice.
///
/// Steps are sequenced through a PageView with a StepIndicator; each step
/// reports completion to this controller screen which advances the flow.
class InspectionFlowScreen extends ConsumerStatefulWidget {
  const InspectionFlowScreen({super.key, required this.inspectionId});

  final String inspectionId;

  @override
  ConsumerState<InspectionFlowScreen> createState() =>
      _InspectionFlowScreenState();
}

class _InspectionFlowScreenState extends ConsumerState<InspectionFlowScreen> {
  late final PageController _pageController;
  int _currentStep = 0;

  // Shared flow data.
  List<EvidenceItem> _evidence = [];
  OcrResult? _ocrResult;
  List<Violation> _violations = [];
  bool _hasConfirmedViolations = false;
  OffenceHistory? _offenceHistory;
  Notice? _issuedNotice;
  SignatureResult? _signature;
  bool _flowCompleted = false;

  static const _stepLabels = [
    'Evidence',
    'OCR',
    'Fields',
    'Violations',
    'Offence',
    'Observations',
    'Notice',
    'Sign',
    'Done',
  ];

  Inspection? _inspection;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadInspection();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadInspection() async {
    try {
      final inspection = await ref
          .read(inspectionRepositoryProvider)
          .getInspection(widget.inspectionId);
      if (!mounted) return;
      setState(() => _inspection = inspection);
    } catch (_) {
      // Keep flow functional even if the header fetch fails (mock mode).
    }
  }

  void _goToStep(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
    setState(() => _currentStep = index);
  }

  void _next() => _goToStep((_currentStep + 1).clamp(0, _stepLabels.length - 1));
  void _back() => _goToStep((_currentStep - 1).clamp(0, _stepLabels.length - 1));

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentStep > 0) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Inspection'),
              Text(
                _inspection?.business.name ?? widget.inspectionId,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Center(
                child: Text(
                  'Step ${_currentStep + 1} of ${_stepLabels.length}',
                  style: const TextStyle(fontSize: 12.5, color: Colors.white70),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md,
              ),
              child: StepIndicator(steps: _stepLabels, currentStep: _currentStep),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  EvidenceStep(
                    evidence: _evidence,
                    onEvidenceChanged: (list) => setState(() => _evidence = list),
                    // Upload happens as stage 1 of the OCR pipeline on the
                    // next step — here we only require captured photos.
                    onContinue: _evidence.isNotEmpty ? _next : null,
                  ),
                  OcrStep(
                    evidence: _evidence,
                    inspectionId: widget.inspectionId,
                    onCompleted: (result) => setState(() => _ocrResult = result),
                    onContinue: _next,
                  ),
                  OcrReviewStep(
                    ocrResult: _ocrResult,
                    onConfirmed: () {
                      setState(() => _hasConfirmedViolations = false);
                      _next();
                    },
                    onBack: _back,
                  ),
                  ViolationsStep(
                    inspectionId: widget.inspectionId,
                    ocrResult: _ocrResult,
                    evidence: _evidence,
                    onAnyConfirmed: () =>
                        setState(() => _hasConfirmedViolations = true),
                    onViolationsChanged: (list) =>
                        setState(() => _violations = list),
                    onContinue: _next,
                    onBack: _back,
                  ),
                  OffenceStep(
                    ocrResult: _ocrResult,
                    inspection: _inspection,
                    onContinue: _next,
                    onBack: _back,
                  ),
                  ObservationsStep(
                    inspectionId: widget.inspectionId,
                    onContinue: _next,
                    onBack: _back,
                  ),
                  NoticeStep(
                    inspectionId: widget.inspectionId,
                    inspection: _inspection,
                    violations: _violations,
                    onNoticeIssued: (notice) {
                      setState(() => _issuedNotice = notice);
                      _next();
                    },
                    onBack: _back,
                  ),
                  SignatureStep(
                    inspection: _inspection,
                    draftNotice: _issuedNotice,
                    onSigned: (signature, issuedNotice) {
                      setState(() {
                        _signature = signature;
                        _issuedNotice = issuedNotice;
                        _flowCompleted = true;
                      });
                      _next();
                    },
                    onBack: _back,
                  ),
                  FlowCompleteScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

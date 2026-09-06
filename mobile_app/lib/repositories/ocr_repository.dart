import '../models/ocr_result.dart';
import '../models/evidence.dart';

/// OCR/AI capability contract (Member 4's FastAPI, reached via NestJS).
///
/// Designed for asynchronous pipelines: submit images → poll job status →
/// fetch the completed structured result. The mock implementation simulates
/// the same lifecycle with realistic timings.
abstract class OcrRepository {
  /// Submits package images for analysis. Returns a job id immediately.
  Future<String> submitPackageImages({
    required String ownerId,
    required List<EvidenceItem> images,
  });

  /// One-shot analysis convenience that submits and waits for completion.
  /// Streaming progress updates through [onStep] as the pipeline advances.
  Future<OcrResult> analyzePackage({
    required String ownerId,
    required List<EvidenceItem> images,
    void Function(OcrPipelineStep step)? onStep,
  });

  /// Polls the job status; returns current [OcrResult].
  Future<OcrResult> getAnalysisStatus(String jobId);

  /// Retrieves the final structured result (throws if not completed).
  Future<OcrResult> getOcrResult(String jobId);
}

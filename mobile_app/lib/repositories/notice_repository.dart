import '../models/notice.dart';

/// Notice capability contract — generation through issuance.
///
/// Generation goes: Flutter → NestJS → FastAPI NLP (Member 4) → draft
/// notice. The draft is ALWAYS returned with `isAiDraft: true`; only the
/// authorised inspector can finalise it after review/edit/signature.
abstract class NoticeRepository {
  /// Requests AI/NLP draft generation. Returns a DRAFT notice.
  Future<Notice> generateNotice(GenerateNoticeRequest request);

  Future<Notice> getNotice(String id);

  Future<List<Notice>> listNoticesForBusiness(String businessId);

  Future<List<Notice>> listNoticesForInspector(String inspectorId);

  /// Persists inspector edits (violations/sections/body text).
  Future<Notice> editNotice(Notice notice);

  /// Adds an extra applicable legal section to the draft.
  Future<Notice> addSection(String noticeId, NoticeSection section);

  /// Marks the draft reviewed and ready for signature.
  Future<Notice> confirmDraft(String noticeId, {String? inspectorRemark});

  /// Attaches the captured signature and issues the notice.
  /// Signature verification (eMudhra — Member 6) happens backend-side.
  Future<Notice> signAndIssue(SignIssueRequest request);
}

class SignIssueRequest {
  const SignIssueRequest({
    required this.noticeId,
    required this.signerName,
    required this.signatureImagePath,
    this.remarks,
  });

  final String noticeId;
  final String signerName;
  final String signatureImagePath;
  final String? remarks;
}

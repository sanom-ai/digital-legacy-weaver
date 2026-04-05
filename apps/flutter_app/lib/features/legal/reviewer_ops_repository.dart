import 'package:digital_legacy_weaver/core/config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewerQueueItem {
  const ReviewerQueueItem({
    required this.id,
    required this.ownerId,
    required this.documentType,
    required this.reviewStatus,
    required this.updatedAt,
    required this.approvals,
    required this.rejections,
    required this.needsInfoCount,
  });

  final String id;
  final String ownerId;
  final String documentType;
  final String reviewStatus;
  final DateTime updatedAt;
  final int approvals;
  final int rejections;
  final int needsInfoCount;

  factory ReviewerQueueItem.fromMap(Map<String, dynamic> map) {
    return ReviewerQueueItem(
      id: (map["id"] ?? "").toString(),
      ownerId: (map["owner_id"] ?? "").toString(),
      documentType: (map["document_type"] ?? "").toString(),
      reviewStatus: (map["review_status"] ?? "").toString(),
      updatedAt: DateTime.parse((map["updated_at"] as String?) ?? DateTime.now().toUtc().toIso8601String()),
      approvals: (map["approvals"] as num?)?.toInt() ?? 0,
      rejections: (map["rejections"] as num?)?.toInt() ?? 0,
      needsInfoCount: (map["needs_info_count"] as num?)?.toInt() ?? 0,
    );
  }
}

class ReviewerDecisionEntry {
  const ReviewerDecisionEntry({
    required this.reviewerRef,
    required this.decision,
    required this.notes,
    required this.reviewedAt,
  });

  final String reviewerRef;
  final String decision;
  final String? notes;
  final DateTime reviewedAt;

  factory ReviewerDecisionEntry.fromMap(Map<String, dynamic> map) {
    return ReviewerDecisionEntry(
      reviewerRef: (map["reviewer_ref"] ?? "").toString(),
      decision: (map["decision"] ?? "").toString(),
      notes: map["notes"] as String?,
      reviewedAt: DateTime.parse((map["reviewed_at"] as String?) ?? DateTime.now().toUtc().toIso8601String()),
    );
  }
}

class ReviewerEvidenceSummary {
  const ReviewerEvidenceSummary({
    required this.evidenceId,
    required this.ownerId,
    required this.documentType,
    required this.reviewStatus,
    required this.reviews,
  });

  final String evidenceId;
  final String ownerId;
  final String documentType;
  final String reviewStatus;
  final List<ReviewerDecisionEntry> reviews;

  factory ReviewerEvidenceSummary.fromMap(Map<String, dynamic> map) {
    final evidence = Map<String, dynamic>.from(map["evidence"] as Map? ?? const {});
    final reviewsRaw = (map["reviews"] as List<dynamic>? ?? const []);
    return ReviewerEvidenceSummary(
      evidenceId: (evidence["id"] ?? "").toString(),
      ownerId: (evidence["owner_id"] ?? "").toString(),
      documentType: (evidence["document_type"] ?? "").toString(),
      reviewStatus: (evidence["review_status"] ?? "").toString(),
      reviews: reviewsRaw
          .map((row) => ReviewerDecisionEntry.fromMap(Map<String, dynamic>.from(row as Map)))
          .toList(),
    );
  }
}

class ReviewerOpsRepository {
  ReviewerOpsRepository(this._client);

  final SupabaseClient _client;

  Map<String, String> get _headers => {
        "x-reviewer-key": AppConfig.reviewerApiKey,
      };

  Future<List<ReviewerQueueItem>> loadQueue({
    String status = "under_review",
    int limit = 50,
  }) async {
    final response = await _client.functions.invoke(
      "review-legal-evidence",
      body: {
        "action": "queue",
        "status": status,
        "limit": limit,
      },
      headers: _headers,
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final rows = (data["queue"] as List<dynamic>? ?? const []);
    return rows.map((row) => ReviewerQueueItem.fromMap(Map<String, dynamic>.from(row as Map))).toList();
  }

  Future<Map<String, dynamic>> applyDecision({
    required String evidenceId,
    required String reviewerRef,
    required String decision,
    String? notes,
  }) async {
    final response = await _client.functions.invoke(
      "review-legal-evidence",
      body: {
        "action": "review",
        "evidence_id": evidenceId,
        "reviewer_ref": reviewerRef,
        "decision": decision,
        "notes": notes,
      },
      headers: _headers,
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<ReviewerEvidenceSummary> loadSummary(String evidenceId) async {
    final response = await _client.functions.invoke(
      "review-legal-evidence",
      body: {
        "action": "summary",
        "evidence_id": evidenceId,
      },
      headers: _headers,
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    return ReviewerEvidenceSummary.fromMap(data);
  }
}

/// Represents a community review scoring taste and hygiene separately.
class Review {
  const Review({
    required this.id,
    required this.stallId,
    required this.authorUid,
    required this.authorName,
    required this.tasteRating,
    required this.hygieneRating,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String stallId;
  final String authorUid;
  final String authorName;
  final double tasteRating;
  final double hygieneRating;
  final String comment;
  final DateTime createdAt;

  double get averageRating => (tasteRating + hygieneRating) / 2.0;

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: (json['id'] as String?) ?? '',
      stallId: (json['stallId'] as String?) ?? '',
      authorUid: (json['authorUid'] as String?) ?? '',
      authorName: (json['authorName'] as String?) ?? 'Foodie',
      tasteRating: (json['tasteRating'] as num?)?.toDouble() ?? 4.0,
      hygieneRating: (json['hygieneRating'] as num?)?.toDouble() ?? 4.0,
      comment: (json['comment'] as String?) ?? '',
      createdAt: parseFlexibleDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'stallId': stallId,
      'authorUid': authorUid,
      'authorName': authorName,
      'tasteRating': tasteRating,
      'hygieneRating': hygieneRating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Review copyWith({
    String? id,
    String? stallId,
    String? authorUid,
    String? authorName,
    double? tasteRating,
    double? hygieneRating,
    String? comment,
    DateTime? createdAt,
  }) {
    return Review(
      id: id ?? this.id,
      stallId: stallId ?? this.stallId,
      authorUid: authorUid ?? this.authorUid,
      authorName: authorName ?? this.authorName,
      tasteRating: tasteRating ?? this.tasteRating,
      hygieneRating: hygieneRating ?? this.hygieneRating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Parses Firestore Timestamp, ISO string, DateTime, or epoch milliseconds.
  static DateTime parseFlexibleDateTime(Object? raw) {
    if (raw is DateTime) return raw;
    if (raw is String) {
      return DateTime.tryParse(raw) ?? DateTime.now();
    }
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    if (raw != null) {
      try {
        final dynamic dynamicValue = raw;
        final Object? converted = dynamicValue.toDate();
        if (converted is DateTime) return converted;
      } catch (_) {
        // Fallback if object does not implement toDate().
      }
    }
    return DateTime.now();
  }
}

import 'package:json_annotation/json_annotation.dart';

part 'reading_progress.g.dart';

@JsonSerializable()
class ReadingProgress {
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'doc_id')
  final String docId;
  @JsonKey(name: 'last_page')
  final int? lastPage;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const ReadingProgress({
    required this.userId,
    required this.docId,
    this.lastPage,
    required this.updatedAt,
  });

  factory ReadingProgress.fromJson(Map<String, dynamic> json) => _$ReadingProgressFromJson(json);
  Map<String, dynamic> toJson() => _$ReadingProgressToJson(this);

  ReadingProgress copyWith({
    String? userId,
    String? docId,
    int? lastPage,
    DateTime? updatedAt,
  }) {
    return ReadingProgress(
      userId: userId ?? this.userId,
      docId: docId ?? this.docId,
      lastPage: lastPage ?? this.lastPage,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReadingProgress &&
        other.userId == userId &&
        other.docId == docId &&
        other.lastPage == lastPage &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      userId,
      docId,
      lastPage,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'ReadingProgress(userId: $userId, docId: $docId, lastPage: $lastPage, updatedAt: $updatedAt)';
  }
}
import 'package:json_annotation/json_annotation.dart';

part 'bookmark.g.dart';

@JsonSerializable()
class Bookmark {
  final String id; // UUID
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'doc_id')
  final String docId;
  @JsonKey(name: 'page_number')
  final int? pageNumber;
  final String? note;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const Bookmark({
    required this.id,
    required this.userId,
    required this.docId,
    this.pageNumber,
    this.note,
    required this.createdAt,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) => _$BookmarkFromJson(json);
  Map<String, dynamic> toJson() => _$BookmarkToJson(this);

  Bookmark copyWith({
    String? id,
    String? userId,
    String? docId,
    int? pageNumber,
    String? note,
    DateTime? createdAt,
  }) {
    return Bookmark(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      docId: docId ?? this.docId,
      pageNumber: pageNumber ?? this.pageNumber,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Bookmark &&
        other.id == id &&
        other.userId == userId &&
        other.docId == docId &&
        other.pageNumber == pageNumber &&
        other.note == note &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      docId,
      pageNumber,
      note,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'Bookmark(id: $id, userId: $userId, docId: $docId, pageNumber: $pageNumber, note: $note, createdAt: $createdAt)';
  }
}
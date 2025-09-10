import 'package:json_annotation/json_annotation.dart';

part 'comment.g.dart';

@JsonSerializable()
class Comment {
  final String id; // UUID
  @JsonKey(name: 'doc_id')
  final String docId;
  @JsonKey(name: 'user_id')
  final String? userId;
  @JsonKey(name: 'page_number')
  final int? pageNumber;
  final Map<String, dynamic>? anchor; // JSONB for position/selection data
  final String? content;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.docId,
    this.userId,
    this.pageNumber,
    this.anchor,
    this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);
  Map<String, dynamic> toJson() => _$CommentToJson(this);

  Comment copyWith({
    String? id,
    String? docId,
    String? userId,
    int? pageNumber,
    Map<String, dynamic>? anchor,
    String? content,
    DateTime? createdAt,
  }) {
    return Comment(
      id: id ?? this.id,
      docId: docId ?? this.docId,
      userId: userId ?? this.userId,
      pageNumber: pageNumber ?? this.pageNumber,
      anchor: anchor ?? this.anchor,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Comment &&
        other.id == id &&
        other.docId == docId &&
        other.userId == userId &&
        other.pageNumber == pageNumber &&
        other.anchor == anchor &&
        other.content == content &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      docId,
      userId,
      pageNumber,
      anchor,
      content,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'Comment(id: $id, docId: $docId, userId: $userId, pageNumber: $pageNumber, anchor: $anchor, content: $content, createdAt: $createdAt)';
  }
}
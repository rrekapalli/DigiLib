import 'package:json_annotation/json_annotation.dart';

part 'tag.g.dart';

@JsonSerializable()
class Tag {
  final String id; // UUID
  @JsonKey(name: 'owner_id')
  final String? ownerId;
  final String name;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const Tag({
    required this.id,
    this.ownerId,
    required this.name,
    required this.createdAt,
  });

  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);
  Map<String, dynamic> toJson() => _$TagToJson(this);

  Tag copyWith({
    String? id,
    String? ownerId,
    String? name,
    DateTime? createdAt,
  }) {
    return Tag(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tag &&
        other.id == id &&
        other.ownerId == ownerId &&
        other.name == name &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      ownerId,
      name,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'Tag(id: $id, ownerId: $ownerId, name: $name, createdAt: $createdAt)';
  }
}

@JsonSerializable()
class DocumentTag {
  final String id; // UUID
  @JsonKey(name: 'doc_id')
  final String docId;
  @JsonKey(name: 'tag_id')
  final String tagId;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const DocumentTag({
    required this.id,
    required this.docId,
    required this.tagId,
    required this.createdAt,
  });

  factory DocumentTag.fromJson(Map<String, dynamic> json) => _$DocumentTagFromJson(json);
  Map<String, dynamic> toJson() => _$DocumentTagToJson(this);

  DocumentTag copyWith({
    String? id,
    String? docId,
    String? tagId,
    DateTime? createdAt,
  }) {
    return DocumentTag(
      id: id ?? this.id,
      docId: docId ?? this.docId,
      tagId: tagId ?? this.tagId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocumentTag &&
        other.id == id &&
        other.docId == docId &&
        other.tagId == tagId &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      docId,
      tagId,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'DocumentTag(id: $id, docId: $docId, tagId: $tagId, createdAt: $createdAt)';
  }
}
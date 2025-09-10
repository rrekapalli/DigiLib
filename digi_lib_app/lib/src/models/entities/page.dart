import 'package:json_annotation/json_annotation.dart';

part 'page.g.dart';

@JsonSerializable()
class Page {
  final String id; // UUID
  @JsonKey(name: 'doc_id')
  final String docId;
  @JsonKey(name: 'page_number')
  final int pageNumber;
  @JsonKey(name: 'text_content')
  final String? textContent;
  @JsonKey(name: 'thumbnail_url')
  final String? thumbnailUrl;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const Page({
    required this.id,
    required this.docId,
    required this.pageNumber,
    this.textContent,
    this.thumbnailUrl,
    required this.createdAt,
  });

  factory Page.fromJson(Map<String, dynamic> json) => _$PageFromJson(json);
  Map<String, dynamic> toJson() => _$PageToJson(this);

  Page copyWith({
    String? id,
    String? docId,
    int? pageNumber,
    String? textContent,
    String? thumbnailUrl,
    DateTime? createdAt,
  }) {
    return Page(
      id: id ?? this.id,
      docId: docId ?? this.docId,
      pageNumber: pageNumber ?? this.pageNumber,
      textContent: textContent ?? this.textContent,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Page &&
        other.id == id &&
        other.docId == docId &&
        other.pageNumber == pageNumber &&
        other.textContent == textContent &&
        other.thumbnailUrl == thumbnailUrl &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      docId,
      pageNumber,
      textContent,
      thumbnailUrl,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'Page(id: $id, docId: $docId, pageNumber: $pageNumber, textContent: $textContent, thumbnailUrl: $thumbnailUrl, createdAt: $createdAt)';
  }
}
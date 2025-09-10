import 'package:json_annotation/json_annotation.dart';
import '../entities/document.dart';
import 'pagination.dart';

part 'document_list_response.g.dart';

@JsonSerializable()
class DocumentListResponse {
  final List<Document> documents;
  final Pagination pagination;

  const DocumentListResponse({
    required this.documents,
    required this.pagination,
  });

  factory DocumentListResponse.fromJson(Map<String, dynamic> json) => _$DocumentListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$DocumentListResponseToJson(this);

  DocumentListResponse copyWith({
    List<Document>? documents,
    Pagination? pagination,
  }) {
    return DocumentListResponse(
      documents: documents ?? this.documents,
      pagination: pagination ?? this.pagination,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocumentListResponse &&
        other.documents == documents &&
        other.pagination == pagination;
  }

  @override
  int get hashCode {
    return Object.hash(
      documents,
      pagination,
    );
  }

  @override
  String toString() {
    return 'DocumentListResponse(documents: $documents, pagination: $pagination)';
  }
}
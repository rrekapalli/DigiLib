import 'package:json_annotation/json_annotation.dart';

part 'update_document_request.g.dart';

@JsonSerializable()
class UpdateDocumentRequest {
  final String? title;
  final String? author;
  @JsonKey(name: 'renamed_name')
  final String? renamedName;
  final String? isbn;
  @JsonKey(name: 'year_published')
  final int? yearPublished;
  @JsonKey(name: 'metadata_json')
  final Map<String, dynamic>? metadataJson;

  const UpdateDocumentRequest({
    this.title,
    this.author,
    this.renamedName,
    this.isbn,
    this.yearPublished,
    this.metadataJson,
  });

  factory UpdateDocumentRequest.fromJson(Map<String, dynamic> json) => _$UpdateDocumentRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateDocumentRequestToJson(this);

  UpdateDocumentRequest copyWith({
    String? title,
    String? author,
    String? renamedName,
    String? isbn,
    int? yearPublished,
    Map<String, dynamic>? metadataJson,
  }) {
    return UpdateDocumentRequest(
      title: title ?? this.title,
      author: author ?? this.author,
      renamedName: renamedName ?? this.renamedName,
      isbn: isbn ?? this.isbn,
      yearPublished: yearPublished ?? this.yearPublished,
      metadataJson: metadataJson ?? this.metadataJson,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpdateDocumentRequest &&
        other.title == title &&
        other.author == author &&
        other.renamedName == renamedName &&
        other.isbn == isbn &&
        other.yearPublished == yearPublished &&
        other.metadataJson == metadataJson;
  }

  @override
  int get hashCode {
    return Object.hash(
      title,
      author,
      renamedName,
      isbn,
      yearPublished,
      metadataJson,
    );
  }

  @override
  String toString() {
    return 'UpdateDocumentRequest(title: $title, author: $author, renamedName: $renamedName, isbn: $isbn, yearPublished: $yearPublished, metadataJson: $metadataJson)';
  }
}
import 'package:json_annotation/json_annotation.dart';

part 'document.g.dart';

@JsonSerializable()
class Document {
  final String id; // UUID
  @JsonKey(name: 'library_id')
  final String libraryId;
  final String? title;
  final String? author;
  final String? filename;
  @JsonKey(name: 'relative_path')
  final String? relativePath;
  @JsonKey(name: 'full_path')
  final String? fullPath;
  final String? extension;
  @JsonKey(name: 'renamed_name')
  final String? renamedName;
  final String? isbn;
  @JsonKey(name: 'year_published')
  final int? yearPublished;
  final String? status;
  @JsonKey(name: 'cloud_id')
  final String? cloudId;
  final String? sha256;
  @JsonKey(name: 'size_bytes')
  final int? sizeBytes;
  @JsonKey(name: 'page_count')
  final int? pageCount;
  final String? format;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'amazon_url')
  final String? amazonUrl;
  @JsonKey(name: 'review_url')
  final String? reviewUrl;
  @JsonKey(name: 'metadata_json')
  final Map<String, dynamic>? metadataJson;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const Document({
    required this.id,
    required this.libraryId,
    this.title,
    this.author,
    this.filename,
    this.relativePath,
    this.fullPath,
    this.extension,
    this.renamedName,
    this.isbn,
    this.yearPublished,
    this.status,
    this.cloudId,
    this.sha256,
    this.sizeBytes,
    this.pageCount,
    this.format,
    this.imageUrl,
    this.amazonUrl,
    this.reviewUrl,
    this.metadataJson,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) => _$DocumentFromJson(json);
  Map<String, dynamic> toJson() => _$DocumentToJson(this);

  Document copyWith({
    String? id,
    String? libraryId,
    String? title,
    String? author,
    String? filename,
    String? relativePath,
    String? fullPath,
    String? extension,
    String? renamedName,
    String? isbn,
    int? yearPublished,
    String? status,
    String? cloudId,
    String? sha256,
    int? sizeBytes,
    int? pageCount,
    String? format,
    String? imageUrl,
    String? amazonUrl,
    String? reviewUrl,
    Map<String, dynamic>? metadataJson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Document(
      id: id ?? this.id,
      libraryId: libraryId ?? this.libraryId,
      title: title ?? this.title,
      author: author ?? this.author,
      filename: filename ?? this.filename,
      relativePath: relativePath ?? this.relativePath,
      fullPath: fullPath ?? this.fullPath,
      extension: extension ?? this.extension,
      renamedName: renamedName ?? this.renamedName,
      isbn: isbn ?? this.isbn,
      yearPublished: yearPublished ?? this.yearPublished,
      status: status ?? this.status,
      cloudId: cloudId ?? this.cloudId,
      sha256: sha256 ?? this.sha256,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      pageCount: pageCount ?? this.pageCount,
      format: format ?? this.format,
      imageUrl: imageUrl ?? this.imageUrl,
      amazonUrl: amazonUrl ?? this.amazonUrl,
      reviewUrl: reviewUrl ?? this.reviewUrl,
      metadataJson: metadataJson ?? this.metadataJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Document &&
        other.id == id &&
        other.libraryId == libraryId &&
        other.title == title &&
        other.author == author &&
        other.filename == filename &&
        other.relativePath == relativePath &&
        other.fullPath == fullPath &&
        other.extension == extension &&
        other.renamedName == renamedName &&
        other.isbn == isbn &&
        other.yearPublished == yearPublished &&
        other.status == status &&
        other.cloudId == cloudId &&
        other.sha256 == sha256 &&
        other.sizeBytes == sizeBytes &&
        other.pageCount == pageCount &&
        other.format == format &&
        other.imageUrl == imageUrl &&
        other.amazonUrl == amazonUrl &&
        other.reviewUrl == reviewUrl &&
        other.metadataJson == metadataJson &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      libraryId,
      title,
      author,
      filename,
      relativePath,
      fullPath,
      extension,
      renamedName,
      isbn,
      yearPublished,
      status,
      cloudId,
      sha256,
      sizeBytes,
      pageCount,
      format,
      imageUrl,
      amazonUrl,
      reviewUrl,
      metadataJson,
      createdAt,
      updatedAt,
    ]);
  }

  @override
  String toString() {
    return 'Document(id: $id, libraryId: $libraryId, title: $title, author: $author, filename: $filename, relativePath: $relativePath, fullPath: $fullPath, extension: $extension, renamedName: $renamedName, isbn: $isbn, yearPublished: $yearPublished, status: $status, cloudId: $cloudId, sha256: $sha256, sizeBytes: $sizeBytes, pageCount: $pageCount, format: $format, imageUrl: $imageUrl, amazonUrl: $amazonUrl, reviewUrl: $reviewUrl, metadataJson: $metadataJson, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
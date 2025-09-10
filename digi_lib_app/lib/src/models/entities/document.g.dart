// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Document _$DocumentFromJson(Map<String, dynamic> json) => Document(
      id: json['id'] as String,
      libraryId: json['library_id'] as String,
      title: json['title'] as String?,
      author: json['author'] as String?,
      filename: json['filename'] as String?,
      relativePath: json['relative_path'] as String?,
      fullPath: json['full_path'] as String?,
      extension: json['extension'] as String?,
      renamedName: json['renamed_name'] as String?,
      isbn: json['isbn'] as String?,
      yearPublished: (json['year_published'] as num?)?.toInt(),
      status: json['status'] as String?,
      cloudId: json['cloud_id'] as String?,
      sha256: json['sha256'] as String?,
      sizeBytes: (json['size_bytes'] as num?)?.toInt(),
      pageCount: (json['page_count'] as num?)?.toInt(),
      format: json['format'] as String?,
      imageUrl: json['image_url'] as String?,
      amazonUrl: json['amazon_url'] as String?,
      reviewUrl: json['review_url'] as String?,
      metadataJson: json['metadata_json'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$DocumentToJson(Document instance) => <String, dynamic>{
      'id': instance.id,
      'library_id': instance.libraryId,
      'title': instance.title,
      'author': instance.author,
      'filename': instance.filename,
      'relative_path': instance.relativePath,
      'full_path': instance.fullPath,
      'extension': instance.extension,
      'renamed_name': instance.renamedName,
      'isbn': instance.isbn,
      'year_published': instance.yearPublished,
      'status': instance.status,
      'cloud_id': instance.cloudId,
      'sha256': instance.sha256,
      'size_bytes': instance.sizeBytes,
      'page_count': instance.pageCount,
      'format': instance.format,
      'image_url': instance.imageUrl,
      'amazon_url': instance.amazonUrl,
      'review_url': instance.reviewUrl,
      'metadata_json': instance.metadataJson,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

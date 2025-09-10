import 'package:json_annotation/json_annotation.dart';

part 'create_tag_request.g.dart';

@JsonSerializable()
class CreateTagRequest {
  final String name;

  const CreateTagRequest({
    required this.name,
  });

  factory CreateTagRequest.fromJson(Map<String, dynamic> json) => _$CreateTagRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateTagRequestToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreateTagRequest && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'CreateTagRequest(name: $name)';
}

@JsonSerializable()
class AddTagToDocumentRequest {
  @JsonKey(name: 'tag_id')
  final String tagId;

  const AddTagToDocumentRequest({
    required this.tagId,
  });

  factory AddTagToDocumentRequest.fromJson(Map<String, dynamic> json) => _$AddTagToDocumentRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AddTagToDocumentRequestToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AddTagToDocumentRequest && other.tagId == tagId;
  }

  @override
  int get hashCode => tagId.hashCode;

  @override
  String toString() => 'AddTagToDocumentRequest(tagId: $tagId)';
}
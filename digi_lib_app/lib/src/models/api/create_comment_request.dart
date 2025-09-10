import 'package:json_annotation/json_annotation.dart';

part 'create_comment_request.g.dart';

@JsonSerializable()
class CreateCommentRequest {
  @JsonKey(name: 'page_number')
  final int pageNumber;
  final Map<String, dynamic>? anchor;
  final String content;

  const CreateCommentRequest({
    required this.pageNumber,
    this.anchor,
    required this.content,
  });

  factory CreateCommentRequest.fromJson(Map<String, dynamic> json) => _$CreateCommentRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateCommentRequestToJson(this);

  CreateCommentRequest copyWith({
    int? pageNumber,
    Map<String, dynamic>? anchor,
    String? content,
  }) {
    return CreateCommentRequest(
      pageNumber: pageNumber ?? this.pageNumber,
      anchor: anchor ?? this.anchor,
      content: content ?? this.content,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreateCommentRequest &&
        other.pageNumber == pageNumber &&
        other.anchor == anchor &&
        other.content == content;
  }

  @override
  int get hashCode {
    return Object.hash(
      pageNumber,
      anchor,
      content,
    );
  }

  @override
  String toString() {
    return 'CreateCommentRequest(pageNumber: $pageNumber, anchor: $anchor, content: $content)';
  }
}


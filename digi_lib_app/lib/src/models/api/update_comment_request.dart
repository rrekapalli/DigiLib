import 'package:json_annotation/json_annotation.dart';

part 'update_comment_request.g.dart';

@JsonSerializable()
class UpdateCommentRequest {
  final String content;

  const UpdateCommentRequest({
    required this.content,
  });

  factory UpdateCommentRequest.fromJson(Map<String, dynamic> json) => _$UpdateCommentRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateCommentRequestToJson(this);

  UpdateCommentRequest copyWith({
    String? content,
  }) {
    return UpdateCommentRequest(
      content: content ?? this.content,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpdateCommentRequest && other.content == content;
  }

  @override
  int get hashCode => content.hashCode;

  @override
  String toString() => 'UpdateCommentRequest(content: $content)';
}
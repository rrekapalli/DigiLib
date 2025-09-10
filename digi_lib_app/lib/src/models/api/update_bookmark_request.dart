import 'package:json_annotation/json_annotation.dart';

part 'update_bookmark_request.g.dart';

@JsonSerializable()
class UpdateBookmarkRequest {
  final String? note;

  const UpdateBookmarkRequest({
    this.note,
  });

  factory UpdateBookmarkRequest.fromJson(Map<String, dynamic> json) => _$UpdateBookmarkRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateBookmarkRequestToJson(this);

  UpdateBookmarkRequest copyWith({
    String? note,
  }) {
    return UpdateBookmarkRequest(
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpdateBookmarkRequest && other.note == note;
  }

  @override
  int get hashCode => note.hashCode;

  @override
  String toString() => 'UpdateBookmarkRequest(note: $note)';
}
import 'package:json_annotation/json_annotation.dart';

part 'create_bookmark_request.g.dart';

@JsonSerializable()
class CreateBookmarkRequest {
  @JsonKey(name: 'page_number')
  final int pageNumber;
  final String? note;

  const CreateBookmarkRequest({
    required this.pageNumber,
    this.note,
  });

  factory CreateBookmarkRequest.fromJson(Map<String, dynamic> json) => _$CreateBookmarkRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateBookmarkRequestToJson(this);

  CreateBookmarkRequest copyWith({
    int? pageNumber,
    String? note,
  }) {
    return CreateBookmarkRequest(
      pageNumber: pageNumber ?? this.pageNumber,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreateBookmarkRequest &&
        other.pageNumber == pageNumber &&
        other.note == note;
  }

  @override
  int get hashCode {
    return Object.hash(
      pageNumber,
      note,
    );
  }

  @override
  String toString() {
    return 'CreateBookmarkRequest(pageNumber: $pageNumber, note: $note)';
  }
}


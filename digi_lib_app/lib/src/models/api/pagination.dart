import 'package:json_annotation/json_annotation.dart';

part 'pagination.g.dart';

@JsonSerializable()
class Pagination {
  final int page;
  final int limit;
  final int total;
  @JsonKey(name: 'total_pages')
  final int totalPages;

  const Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) => _$PaginationFromJson(json);
  Map<String, dynamic> toJson() => _$PaginationToJson(this);

  Pagination copyWith({
    int? page,
    int? limit,
    int? total,
    int? totalPages,
  }) {
    return Pagination(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Pagination &&
        other.page == page &&
        other.limit == limit &&
        other.total == total &&
        other.totalPages == totalPages;
  }

  @override
  int get hashCode {
    return Object.hash(
      page,
      limit,
      total,
      totalPages,
    );
  }

  @override
  String toString() {
    return 'Pagination(page: $page, limit: $limit, total: $total, totalPages: $totalPages)';
  }
}
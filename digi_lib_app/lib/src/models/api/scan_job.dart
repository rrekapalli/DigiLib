import 'package:json_annotation/json_annotation.dart';

part 'scan_job.g.dart';

@JsonSerializable()
class ScanJob {
  final String id;
  @JsonKey(name: 'library_id')
  final String libraryId;
  final String status; // pending, running, completed, failed
  final int progress; // 0-100
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;

  const ScanJob({
    required this.id,
    required this.libraryId,
    required this.status,
    required this.progress,
    required this.createdAt,
    this.completedAt,
  });

  factory ScanJob.fromJson(Map<String, dynamic> json) => _$ScanJobFromJson(json);
  Map<String, dynamic> toJson() => _$ScanJobToJson(this);

  ScanJob copyWith({
    String? id,
    String? libraryId,
    String? status,
    int? progress,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return ScanJob(
      id: id ?? this.id,
      libraryId: libraryId ?? this.libraryId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScanJob &&
        other.id == id &&
        other.libraryId == libraryId &&
        other.status == status &&
        other.progress == progress &&
        other.createdAt == createdAt &&
        other.completedAt == completedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      libraryId,
      status,
      progress,
      createdAt,
      completedAt,
    );
  }

  @override
  String toString() {
    return 'ScanJob(id: $id, libraryId: $libraryId, status: $status, progress: $progress, createdAt: $createdAt, completedAt: $completedAt)';
  }
}
import 'package:json_annotation/json_annotation.dart';

part 'library.g.dart';

enum LibraryType {
  @JsonValue('local')
  local,
  @JsonValue('gdrive')
  gdrive,
  @JsonValue('onedrive')
  onedrive,
  @JsonValue('s3')
  s3,
}

@JsonSerializable()
class Library {
  final String id; // UUID
  @JsonKey(name: 'owner_id')
  final String? ownerId;
  final String name;
  final LibraryType type;
  final Map<String, dynamic>? config; // JSONB
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const Library({
    required this.id,
    this.ownerId,
    required this.name,
    required this.type,
    this.config,
    required this.createdAt,
  });

  factory Library.fromJson(Map<String, dynamic> json) => _$LibraryFromJson(json);
  Map<String, dynamic> toJson() => _$LibraryToJson(this);

  Library copyWith({
    String? id,
    String? ownerId,
    String? name,
    LibraryType? type,
    Map<String, dynamic>? config,
    DateTime? createdAt,
  }) {
    return Library(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      type: type ?? this.type,
      config: config ?? this.config,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Library &&
        other.id == id &&
        other.ownerId == ownerId &&
        other.name == name &&
        other.type == type &&
        other.config == config &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      ownerId,
      name,
      type,
      config,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'Library(id: $id, ownerId: $ownerId, name: $name, type: $type, config: $config, createdAt: $createdAt)';
  }
}
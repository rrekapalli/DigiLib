import 'package:json_annotation/json_annotation.dart';
import '../entities/library.dart';

part 'create_library_request.g.dart';

@JsonSerializable()
class CreateLibraryRequest {
  final String name;
  final LibraryType type;
  final Map<String, dynamic>? config;

  const CreateLibraryRequest({
    required this.name,
    required this.type,
    this.config,
  });

  factory CreateLibraryRequest.fromJson(Map<String, dynamic> json) => _$CreateLibraryRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateLibraryRequestToJson(this);

  CreateLibraryRequest copyWith({
    String? name,
    LibraryType? type,
    Map<String, dynamic>? config,
  }) {
    return CreateLibraryRequest(
      name: name ?? this.name,
      type: type ?? this.type,
      config: config ?? this.config,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreateLibraryRequest &&
        other.name == name &&
        other.type == type &&
        other.config == config;
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      type,
      config,
    );
  }

  @override
  String toString() {
    return 'CreateLibraryRequest(name: $name, type: $type, config: $config)';
  }
}
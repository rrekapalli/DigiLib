import '../entities/tag.dart';

/// Model representing a tag with its usage count
class TagWithCount {
  final Tag tag;
  final int count;

  const TagWithCount({
    required this.tag,
    required this.count,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TagWithCount &&
        other.tag == tag &&
        other.count == count;
  }

  @override
  int get hashCode => Object.hash(tag, count);

  @override
  String toString() => 'TagWithCount(tag: $tag, count: $count)';
}
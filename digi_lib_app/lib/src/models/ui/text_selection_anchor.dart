/// Anchor information for text selection in comments
class TextSelectionAnchor {
  final int startOffset;
  final int endOffset;
  final String selectedText;
  final double? x;
  final double? y;
  final double? width;
  final double? height;
  final Map<String, dynamic>? additionalData;

  const TextSelectionAnchor({
    required this.startOffset,
    required this.endOffset,
    required this.selectedText,
    this.x,
    this.y,
    this.width,
    this.height,
    this.additionalData,
  });

  factory TextSelectionAnchor.fromJson(Map<String, dynamic> json) {
    return TextSelectionAnchor(
      startOffset: json['startOffset'] as int,
      endOffset: json['endOffset'] as int,
      selectedText: json['selectedText'] as String,
      x: (json['x'] as num?)?.toDouble(),
      y: (json['y'] as num?)?.toDouble(),
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startOffset': startOffset,
      'endOffset': endOffset,
      'selectedText': selectedText,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (additionalData != null) 'additionalData': additionalData,
    };
  }

  TextSelectionAnchor copyWith({
    int? startOffset,
    int? endOffset,
    String? selectedText,
    double? x,
    double? y,
    double? width,
    double? height,
    Map<String, dynamic>? additionalData,
  }) {
    return TextSelectionAnchor(
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      selectedText: selectedText ?? this.selectedText,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  /// Check if anchor has position information
  bool get hasPosition => x != null && y != null;

  /// Check if anchor has size information
  bool get hasSize => width != null && height != null;

  /// Get selection length
  int get selectionLength => endOffset - startOffset;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextSelectionAnchor &&
        other.startOffset == startOffset &&
        other.endOffset == endOffset &&
        other.selectedText == selectedText &&
        other.x == x &&
        other.y == y &&
        other.width == width &&
        other.height == height &&
        other.additionalData == additionalData;
  }

  @override
  int get hashCode {
    return Object.hash(
      startOffset,
      endOffset,
      selectedText,
      x,
      y,
      width,
      height,
      additionalData,
    );
  }

  @override
  String toString() {
    return 'TextSelectionAnchor(startOffset: $startOffset, '
           'endOffset: $endOffset, '
           'selectedText: "$selectedText", '
           'position: ${hasPosition ? '($x, $y)' : 'null'}, '
           'size: ${hasSize ? '(${width}x$height)' : 'null'})';
  }
}
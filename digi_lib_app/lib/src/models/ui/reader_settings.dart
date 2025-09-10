import 'package:json_annotation/json_annotation.dart';

part 'reader_settings.g.dart';

/// Reading mode for the document viewer
enum ReadingMode {
  @JsonValue('scroll')
  scroll,
  @JsonValue('paginated')
  paginated,
}

/// Page fit mode for document display
enum PageFitMode {
  @JsonValue('fit_width')
  fitWidth,
  @JsonValue('fit_height')
  fitHeight,
  @JsonValue('fit_page')
  fitPage,
  @JsonValue('actual_size')
  actualSize,
}

/// Theme mode for the reader
enum ReaderTheme {
  @JsonValue('light')
  light,
  @JsonValue('dark')
  dark,
  @JsonValue('sepia')
  sepia,
  @JsonValue('system')
  system,
}

/// Reader settings model for user preferences
@JsonSerializable()
class ReaderSettings {
  final ReadingMode readingMode;
  final PageFitMode pageFitMode;
  final ReaderTheme theme;
  final double brightness;
  final double zoom;
  final bool showPageNumbers;
  final bool enableTextSelection;
  final bool enableAnnotations;
  final bool preloadPages;
  final int preloadCount;
  final bool autoSaveProgress;
  final Duration autoSaveInterval;

  const ReaderSettings({
    this.readingMode = ReadingMode.scroll,
    this.pageFitMode = PageFitMode.fitWidth,
    this.theme = ReaderTheme.system,
    this.brightness = 1.0,
    this.zoom = 1.0,
    this.showPageNumbers = true,
    this.enableTextSelection = true,
    this.enableAnnotations = true,
    this.preloadPages = true,
    this.preloadCount = 3,
    this.autoSaveProgress = true,
    this.autoSaveInterval = const Duration(seconds: 2),
  });

  factory ReaderSettings.fromJson(Map<String, dynamic> json) => _$ReaderSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$ReaderSettingsToJson(this);

  ReaderSettings copyWith({
    ReadingMode? readingMode,
    PageFitMode? pageFitMode,
    ReaderTheme? theme,
    double? brightness,
    double? zoom,
    bool? showPageNumbers,
    bool? enableTextSelection,
    bool? enableAnnotations,
    bool? preloadPages,
    int? preloadCount,
    bool? autoSaveProgress,
    Duration? autoSaveInterval,
  }) {
    return ReaderSettings(
      readingMode: readingMode ?? this.readingMode,
      pageFitMode: pageFitMode ?? this.pageFitMode,
      theme: theme ?? this.theme,
      brightness: brightness ?? this.brightness,
      zoom: zoom ?? this.zoom,
      showPageNumbers: showPageNumbers ?? this.showPageNumbers,
      enableTextSelection: enableTextSelection ?? this.enableTextSelection,
      enableAnnotations: enableAnnotations ?? this.enableAnnotations,
      preloadPages: preloadPages ?? this.preloadPages,
      preloadCount: preloadCount ?? this.preloadCount,
      autoSaveProgress: autoSaveProgress ?? this.autoSaveProgress,
      autoSaveInterval: autoSaveInterval ?? this.autoSaveInterval,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReaderSettings &&
        other.readingMode == readingMode &&
        other.pageFitMode == pageFitMode &&
        other.theme == theme &&
        other.brightness == brightness &&
        other.zoom == zoom &&
        other.showPageNumbers == showPageNumbers &&
        other.enableTextSelection == enableTextSelection &&
        other.enableAnnotations == enableAnnotations &&
        other.preloadPages == preloadPages &&
        other.preloadCount == preloadCount &&
        other.autoSaveProgress == autoSaveProgress &&
        other.autoSaveInterval == autoSaveInterval;
  }

  @override
  int get hashCode {
    return Object.hash(
      readingMode,
      pageFitMode,
      theme,
      brightness,
      zoom,
      showPageNumbers,
      enableTextSelection,
      enableAnnotations,
      preloadPages,
      preloadCount,
      autoSaveProgress,
      autoSaveInterval,
    );
  }

  @override
  String toString() {
    return 'ReaderSettings(readingMode: $readingMode, pageFitMode: $pageFitMode, theme: $theme, brightness: $brightness, zoom: $zoom, showPageNumbers: $showPageNumbers, enableTextSelection: $enableTextSelection, enableAnnotations: $enableAnnotations, preloadPages: $preloadPages, preloadCount: $preloadCount, autoSaveProgress: $autoSaveProgress, autoSaveInterval: $autoSaveInterval)';
  }
}


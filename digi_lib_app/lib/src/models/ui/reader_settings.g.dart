// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reader_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReaderSettings _$ReaderSettingsFromJson(Map<String, dynamic> json) =>
    ReaderSettings(
      readingMode:
          $enumDecodeNullable(_$ReadingModeEnumMap, json['readingMode']) ??
              ReadingMode.scroll,
      pageFitMode:
          $enumDecodeNullable(_$PageFitModeEnumMap, json['pageFitMode']) ??
              PageFitMode.fitWidth,
      theme: $enumDecodeNullable(_$ReaderThemeEnumMap, json['theme']) ??
          ReaderTheme.system,
      brightness: (json['brightness'] as num?)?.toDouble() ?? 1.0,
      zoom: (json['zoom'] as num?)?.toDouble() ?? 1.0,
      showPageNumbers: json['showPageNumbers'] as bool? ?? true,
      enableTextSelection: json['enableTextSelection'] as bool? ?? true,
      enableAnnotations: json['enableAnnotations'] as bool? ?? true,
      preloadPages: json['preloadPages'] as bool? ?? true,
      preloadCount: (json['preloadCount'] as num?)?.toInt() ?? 3,
      autoSaveProgress: json['autoSaveProgress'] as bool? ?? true,
      autoSaveInterval: json['autoSaveInterval'] == null
          ? const Duration(seconds: 2)
          : Duration(microseconds: (json['autoSaveInterval'] as num).toInt()),
    );

Map<String, dynamic> _$ReaderSettingsToJson(ReaderSettings instance) =>
    <String, dynamic>{
      'readingMode': _$ReadingModeEnumMap[instance.readingMode]!,
      'pageFitMode': _$PageFitModeEnumMap[instance.pageFitMode]!,
      'theme': _$ReaderThemeEnumMap[instance.theme]!,
      'brightness': instance.brightness,
      'zoom': instance.zoom,
      'showPageNumbers': instance.showPageNumbers,
      'enableTextSelection': instance.enableTextSelection,
      'enableAnnotations': instance.enableAnnotations,
      'preloadPages': instance.preloadPages,
      'preloadCount': instance.preloadCount,
      'autoSaveProgress': instance.autoSaveProgress,
      'autoSaveInterval': instance.autoSaveInterval.inMicroseconds,
    };

const _$ReadingModeEnumMap = {
  ReadingMode.scroll: 'scroll',
  ReadingMode.paginated: 'paginated',
};

const _$PageFitModeEnumMap = {
  PageFitMode.fitWidth: 'fit_width',
  PageFitMode.fitHeight: 'fit_height',
  PageFitMode.fitPage: 'fit_page',
  PageFitMode.actualSize: 'actual_size',
};

const _$ReaderThemeEnumMap = {
  ReaderTheme.light: 'light',
  ReaderTheme.dark: 'dark',
  ReaderTheme.sepia: 'sepia',
  ReaderTheme.system: 'system',
};

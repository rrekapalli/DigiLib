import '../models/entities/tag.dart';

/// Utility class for tag-based filtering and organization
class TagFilterUtils {
  /// Filter tags based on search query with fuzzy matching
  static List<Tag> filterTagsByQuery(List<Tag> tags, String query) {
    if (query.isEmpty) return tags;
    
    final queryLower = query.toLowerCase();
    
    // Exact matches first, then partial matches
    final exactMatches = <Tag>[];
    final partialMatches = <Tag>[];
    
    for (final tag in tags) {
      final tagNameLower = tag.name.toLowerCase();
      
      if (tagNameLower == queryLower) {
        exactMatches.add(tag);
      } else if (tagNameLower.contains(queryLower)) {
        partialMatches.add(tag);
      }
    }
    
    // Sort partial matches by relevance (how early the query appears)
    partialMatches.sort((a, b) {
      final aIndex = a.name.toLowerCase().indexOf(queryLower);
      final bIndex = b.name.toLowerCase().indexOf(queryLower);
      return aIndex.compareTo(bIndex);
    });
    
    return [...exactMatches, ...partialMatches];
  }

  /// Group tags by first letter for alphabetical organization
  static Map<String, List<Tag>> groupTagsAlphabetically(List<Tag> tags) {
    final grouped = <String, List<Tag>>{};
    
    for (final tag in tags) {
      final firstLetter = tag.name.isNotEmpty 
          ? tag.name[0].toUpperCase()
          : '#';
      
      grouped.putIfAbsent(firstLetter, () => <Tag>[]).add(tag);
    }
    
    // Sort tags within each group
    for (final group in grouped.values) {
      group.sort((a, b) => a.name.compareTo(b.name));
    }
    
    return grouped;
  }

  /// Create tag hierarchy based on naming conventions (e.g., "category:subcategory")
  static Map<String, List<Tag>> createTagHierarchy(List<Tag> tags, {String separator = ':'}) {
    final hierarchy = <String, List<Tag>>{};
    
    for (final tag in tags) {
      if (tag.name.contains(separator)) {
        final parts = tag.name.split(separator);
        final category = parts[0].trim();
        hierarchy.putIfAbsent(category, () => <Tag>[]).add(tag);
      } else {
        hierarchy.putIfAbsent('Uncategorized', () => <Tag>[]).add(tag);
      }
    }
    
    // Sort tags within each category
    for (final group in hierarchy.values) {
      group.sort((a, b) => a.name.compareTo(b.name));
    }
    
    return hierarchy;
  }

  /// Get tag suggestions based on existing tags and partial input
  static List<Tag> getTagSuggestions(List<Tag> existingTags, String partialInput, {int maxSuggestions = 10}) {
    if (partialInput.isEmpty) return [];
    
    final suggestions = filterTagsByQuery(existingTags, partialInput);
    return suggestions.take(maxSuggestions).toList();
  }

  /// Calculate tag similarity score (0.0 to 1.0) based on name similarity
  static double calculateTagSimilarity(String tag1, String tag2) {
    if (tag1 == tag2) return 1.0;
    
    final tag1Lower = tag1.toLowerCase();
    final tag2Lower = tag2.toLowerCase();
    
    // Simple Levenshtein distance-based similarity
    final distance = _levenshteinDistance(tag1Lower, tag2Lower);
    final maxLength = tag1Lower.length > tag2Lower.length ? tag1Lower.length : tag2Lower.length;
    
    if (maxLength == 0) return 1.0;
    
    return 1.0 - (distance / maxLength);
  }

  /// Find similar tags based on name similarity
  static List<Tag> findSimilarTags(List<Tag> tags, String targetTagName, {double threshold = 0.7, int maxResults = 5}) {
    final similarities = <TagSimilarity>[];
    
    for (final tag in tags) {
      if (tag.name != targetTagName) {
        final similarity = calculateTagSimilarity(tag.name, targetTagName);
        if (similarity >= threshold) {
          similarities.add(TagSimilarity(tag: tag, similarity: similarity));
        }
      }
    }
    
    // Sort by similarity (highest first)
    similarities.sort((a, b) => b.similarity.compareTo(a.similarity));
    
    return similarities
        .take(maxResults)
        .map((ts) => ts.tag)
        .toList();
  }

  /// Generate tag color based on tag name (for consistent UI coloring)
  static int generateTagColor(String tagName) {
    // Simple hash-based color generation
    int hash = 0;
    for (int i = 0; i < tagName.length; i++) {
      hash = tagName.codeUnitAt(i) + ((hash << 5) - hash);
    }
    
    // Convert to a color value (avoiding very light or very dark colors)
    final hue = (hash % 360).abs();
    final saturation = 70 + (hash % 30); // 70-100%
    final lightness = 40 + (hash % 20);  // 40-60%
    
    return _hslToRgb(hue / 360, saturation / 100, lightness / 100);
  }

  /// Validate tag name according to business rules
  static TagValidationResult validateTagName(String tagName) {
    if (tagName.isEmpty) {
      return TagValidationResult(isValid: false, error: 'Tag name cannot be empty');
    }
    
    if (tagName.length > 50) {
      return TagValidationResult(isValid: false, error: 'Tag name cannot exceed 50 characters');
    }
    
    if (tagName.trim() != tagName) {
      return TagValidationResult(isValid: false, error: 'Tag name cannot have leading or trailing spaces');
    }
    
    // Check for invalid characters
    final invalidChars = RegExp(r'[<>"/\\|?*]');
    if (invalidChars.hasMatch(tagName)) {
      return TagValidationResult(isValid: false, error: 'Tag name contains invalid characters');
    }
    
    return TagValidationResult(isValid: true);
  }

  /// Calculate Levenshtein distance between two strings
  static int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final matrix = List.generate(
      s1.length + 1,
      (i) => List.filled(s2.length + 1, 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,      // deletion
          matrix[i][j - 1] + 1,      // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }

  /// Convert HSL to RGB color value
  static int _hslToRgb(double h, double s, double l) {
    double r, g, b;

    if (s == 0) {
      r = g = b = l; // achromatic
    } else {
      double hue2rgb(double p, double q, double t) {
        if (t < 0) t += 1;
        if (t > 1) t -= 1;
        if (t < 1/6) return p + (q - p) * 6 * t;
        if (t < 1/2) return q;
        if (t < 2/3) return p + (q - p) * (2/3 - t) * 6;
        return p;
      }

      final q = l < 0.5 ? l * (1 + s) : l + s - l * s;
      final p = 2 * l - q;
      r = hue2rgb(p, q, h + 1/3);
      g = hue2rgb(p, q, h);
      b = hue2rgb(p, q, h - 1/3);
    }

    return (0xFF << 24) | 
           ((r * 255).round() << 16) | 
           ((g * 255).round() << 8) | 
           (b * 255).round();
  }
}

/// Model for tag similarity calculation
class TagSimilarity {
  final Tag tag;
  final double similarity;

  const TagSimilarity({
    required this.tag,
    required this.similarity,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TagSimilarity &&
        other.tag == tag &&
        other.similarity == similarity;
  }

  @override
  int get hashCode => Object.hash(tag, similarity);

  @override
  String toString() => 'TagSimilarity(tag: $tag, similarity: $similarity)';
}

/// Result of tag name validation
class TagValidationResult {
  final bool isValid;
  final String? error;

  const TagValidationResult({
    required this.isValid,
    this.error,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TagValidationResult &&
        other.isValid == isValid &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(isValid, error);

  @override
  String toString() => 'TagValidationResult(isValid: $isValid, error: $error)';
}
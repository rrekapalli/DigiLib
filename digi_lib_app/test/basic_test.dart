import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Basic Tests', () {
    test('should run basic test', () {
      expect(1 + 1, equals(2));
    });

    test('should handle string operations', () {
      const testString = 'Digital Library App';
      expect(testString.contains('Library'), isTrue);
      expect(testString.length, equals(19));
    });

    test('should handle list operations', () {
      final testList = [1, 2, 3, 4, 5];
      expect(testList.length, equals(5));
      expect(testList.first, equals(1));
      expect(testList.last, equals(5));
    });

    test('should handle map operations', () {
      final testMap = {'key1': 'value1', 'key2': 'value2'};
      expect(testMap.length, equals(2));
      expect(testMap['key1'], equals('value1'));
      expect(testMap.containsKey('key2'), isTrue);
    });

    test('should handle DateTime operations', () {
      final now = DateTime.now();
      final future = now.add(const Duration(days: 1));
      expect(future.isAfter(now), isTrue);
    });
  });
}
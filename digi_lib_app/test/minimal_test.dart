import 'package:test/test.dart';

void main() {
  group('Minimal Tests', () {
    test('should run basic arithmetic test', () {
      expect(2 + 2, equals(4));
      expect(10 - 5, equals(5));
      expect(3 * 4, equals(12));
      expect(8 / 2, equals(4));
    });

    test('should handle string operations', () {
      const testString = 'Digital Library App';
      expect(testString.contains('Library'), isTrue);
      expect(testString.length, equals(19));
      expect(testString.toLowerCase(), equals('digital library app'));
      expect(testString.split(' ').length, equals(3));
    });

    test('should handle list operations', () {
      final testList = [1, 2, 3, 4, 5];
      expect(testList.length, equals(5));
      expect(testList.first, equals(1));
      expect(testList.last, equals(5));
      expect(testList.contains(3), isTrue);
      expect(testList.where((x) => x > 3).toList(), equals([4, 5]));
    });

    test('should handle map operations', () {
      final testMap = {'key1': 'value1', 'key2': 'value2', 'key3': 'value3'};
      expect(testMap.length, equals(3));
      expect(testMap['key1'], equals('value1'));
      expect(testMap.containsKey('key2'), isTrue);
      expect(testMap.values.toList(), contains('value3'));
    });

    test('should handle DateTime operations', () {
      final now = DateTime.now();
      final future = now.add(const Duration(days: 1));
      final past = now.subtract(const Duration(hours: 2));
      
      expect(future.isAfter(now), isTrue);
      expect(past.isBefore(now), isTrue);
      expect(future.difference(now).inDays, equals(1));
    });

    test('should handle async operations', () async {
      final result = await Future.delayed(
        const Duration(milliseconds: 10),
        () => 'async result',
      );
      expect(result, equals('async result'));
    });

    test('should handle exceptions', () {
      expect(() => throw Exception('test error'), throwsException);
      expect(() => int.parse('invalid'), throwsFormatException);
    });
  });
}
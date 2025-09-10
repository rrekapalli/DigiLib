import 'package:flutter_test/flutter_test.dart';
import 'package:digi_lib_app/src/network/connectivity_service.dart';
import '../test_helpers.dart';

void main() {
  group('MockConnectivityService', () {
    late MockConnectivityService connectivityService;

    setUp(() {
      connectivityService = MockConnectivityService();
    });

    tearDown(() {
      connectivityService.dispose();
    });

    test('should initialize with correct state', () async {
      expect(connectivityService.hasConnectivity(), true);
      expect(await connectivityService.checkConnectivity(), true);
    });

    test('should initialize with false state', () async {
      final service = MockConnectivityService();
      service.setConnected(false);
      expect(service.hasConnectivity(), false);
      expect(await service.checkConnectivity(), false);
      service.dispose();
    });

    test('should change connectivity state', () async {
      expect(connectivityService.hasConnectivity(), true);

      connectivityService.setConnected(false);
      expect(connectivityService.hasConnectivity(), false);

      connectivityService.setConnected(true);
      expect(connectivityService.hasConnectivity(), true);
    });

    test('should emit connectivity changes', () async {
      final states = <bool>[];
      final subscription = connectivityService.connectivityStream.listen(
        states.add,
      );

      connectivityService.setConnected(false);
      connectivityService.setConnected(true);

      // Wait for stream events
      await Future.delayed(const Duration(milliseconds: 10));

      expect(states.length, greaterThan(0));

      await subscription.cancel();
    });
  });

  group('ConnectivityService', () {
    test('should provide connectivity stream', () {
      final service = ConnectivityService.instance;
      expect(service.connectivityStream, isA<Stream<bool>>());
    });

    // Note: Real connectivity tests would require network access
    // and are better suited for integration tests
  });
}

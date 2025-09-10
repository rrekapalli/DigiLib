import 'package:flutter_test/flutter_test.dart';
import 'package:digi_lib_app/src/network/connectivity_service.dart';

void main() {
  group('MockConnectivityService', () {
    late MockConnectivityService connectivityService;

    setUp(() {
      connectivityService = MockConnectivityService(initialState: true);
    });

    tearDown(() {
      connectivityService.dispose();
    });

    test('should initialize with correct state', () async {
      expect(await connectivityService.hasConnectivity(), true);
      expect(await connectivityService.canReachHost('example.com'), true);
    });

    test('should initialize with false state', () async {
      final service = MockConnectivityService(initialState: false);
      expect(await service.hasConnectivity(), false);
      expect(await service.canReachHost('example.com'), false);
      service.dispose();
    });

    test('should change connectivity state', () async {
      expect(await connectivityService.hasConnectivity(), true);
      
      connectivityService.setConnectivity(false);
      expect(await connectivityService.hasConnectivity(), false);
      
      connectivityService.setConnectivity(true);
      expect(await connectivityService.hasConnectivity(), true);
    });

    test('should emit connectivity changes', () async {
      final states = <bool>[];
      final subscription = connectivityService.connectivityStream.listen(states.add);
      
      connectivityService.setConnectivity(false);
      connectivityService.setConnectivity(true);
      connectivityService.setConnectivity(false);
      
      // Wait for stream events
      await Future.delayed(const Duration(milliseconds: 10));
      
      expect(states, [false, true, false]);
      
      await subscription.cancel();
    });

    test('should not emit duplicate states', () async {
      final states = <bool>[];
      final subscription = connectivityService.connectivityStream.listen(states.add);
      
      connectivityService.setConnectivity(true); // Same as initial
      connectivityService.setConnectivity(true); // Duplicate
      connectivityService.setConnectivity(false); // Change
      connectivityService.setConnectivity(false); // Duplicate
      
      // Wait for stream events
      await Future.delayed(const Duration(milliseconds: 10));
      
      expect(states, [false]); // Only the actual change
      
      await subscription.cancel();
    });
  });

  group('ConnectivityServiceImpl', () {
    test('should create with default parameters', () {
      final service = ConnectivityServiceImpl();
      expect(service, isA<ConnectivityService>());
      service.dispose();
    });

    test('should create with custom parameters', () {
      final service = ConnectivityServiceImpl(
        testHost: 'example.com',
        testPort: 443,
        checkInterval: const Duration(seconds: 10),
      );
      expect(service, isA<ConnectivityService>());
      service.dispose();
    });

    test('should provide connectivity stream', () {
      final service = ConnectivityServiceImpl();
      expect(service.connectivityStream, isA<Stream<bool>>());
      service.dispose();
    });

    // Note: Real connectivity tests would require network access
    // and are better suited for integration tests
  });
}
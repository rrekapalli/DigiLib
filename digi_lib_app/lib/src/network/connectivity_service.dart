import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Connectivity state model
@immutable
class ConnectivityState {
  final bool isConnected;
  final DateTime lastChecked;

  const ConnectivityState({
    required this.isConnected,
    required this.lastChecked,
  });

  ConnectivityState copyWith({
    bool? isConnected,
    DateTime? lastChecked,
  }) {
    return ConnectivityState(
      isConnected: isConnected ?? this.isConnected,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConnectivityState &&
        other.isConnected == isConnected &&
        other.lastChecked == lastChecked;
  }

  @override
  int get hashCode => Object.hash(isConnected, lastChecked);
}

/// Provider for connectivity service
final connectivityServiceProvider = StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
  return ConnectivityNotifier();
});

/// Notifier for connectivity state
class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  Timer? _connectivityTimer;

  ConnectivityNotifier() : super(ConnectivityState(
    isConnected: true,
    lastChecked: DateTime.now(),
  )) {
    _initialize();
  }

  /// Initialize connectivity monitoring
  void _initialize() async {
    // Check initial connectivity
    await _checkConnectivity();
    
    // Start periodic connectivity checks
    _connectivityTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      await _checkConnectivity();
    });
    
    debugPrint('ConnectivityService initialized');
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    bool connected = false;
    
    try {
      if (kIsWeb) {
        // For web, assume connected (browser handles connectivity)
        connected = true;
      } else {
        // Try to connect to a reliable host
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 5));
        connected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      }
    } catch (e) {
      connected = false;
    }
    
    if (connected != state.isConnected) {
      state = ConnectivityState(
        isConnected: connected,
        lastChecked: DateTime.now(),
      );
      debugPrint('Connectivity changed: ${connected ? 'connected' : 'disconnected'}');
    }
  }

  /// Force connectivity check
  Future<bool> checkConnectivity() async {
    await _checkConnectivity();
    return state.isConnected;
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    super.dispose();
  }
}

/// Service for monitoring network connectivity
class ConnectivityService {
  static ConnectivityService? _instance;
  static ConnectivityService get instance => _instance ??= ConnectivityService._();
  
  ConnectivityService._();

  bool _isConnected = true;
  Timer? _connectivityTimer;
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();

  /// Stream of connectivity changes
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Current connectivity status
  bool get isConnected => _isConnected;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial connectivity
    await _checkConnectivity();
    
    // Start periodic connectivity checks
    _connectivityTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      await _checkConnectivity();
    });
    
    debugPrint('ConnectivityService initialized');
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    bool connected = false;
    
    try {
      if (kIsWeb) {
        // For web, assume connected (browser handles connectivity)
        connected = true;
      } else {
        // Try to connect to a reliable host
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 5));
        connected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      }
    } catch (e) {
      connected = false;
    }
    
    if (connected != _isConnected) {
      _isConnected = connected;
      _connectivityController.add(_isConnected);
      debugPrint('Connectivity changed: ${_isConnected ? 'connected' : 'disconnected'}');
    }
  }

  /// Force connectivity check
  Future<bool> checkConnectivity() async {
    await _checkConnectivity();
    return _isConnected;
  }

  /// Check if device has connectivity (synchronous version)
  bool hasConnectivity() {
    return _isConnected;
  }

  /// Dispose resources
  void dispose() {
    _connectivityTimer?.cancel();
    _connectivityController.close();
  }
}
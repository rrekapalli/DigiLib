import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/native_rendering_provider.dart';
import '../../services/native_library_loader.dart';
import '../../services/native_rendering_factory.dart';

/// Screen for diagnosing native rendering issues
class NativeRenderingDiagnosticsScreen extends ConsumerStatefulWidget {
  const NativeRenderingDiagnosticsScreen({super.key});

  @override
  ConsumerState<NativeRenderingDiagnosticsScreen> createState() => _NativeRenderingDiagnosticsScreenState();
}

class _NativeRenderingDiagnosticsScreenState extends ConsumerState<NativeRenderingDiagnosticsScreen> {
  LibraryAvailabilityInfo? _availabilityInfo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDiagnostics();
  }

  Future<void> _loadDiagnostics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final info = NativeLibraryLoader.getAvailabilityInfo();
      setState(() {
        _availabilityInfo = info;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load diagnostics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final renderingInfo = ref.watch(nativeRenderingInfoProvider);
    final config = ref.watch(nativeRenderingConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Native Rendering Diagnostics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadDiagnostics,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'copy_report',
                child: ListTile(
                  leading: Icon(Icons.copy),
                  title: Text('Copy Report'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'reset_factory',
                child: ListTile(
                  leading: Icon(Icons.restore),
                  title: Text('Reset Factory'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingSpinner())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentStatusCard(context, renderingInfo),
                  const SizedBox(height: 16),
                  _buildConfigurationCard(context, config),
                  const SizedBox(height: 16),
                  _buildLibraryAvailabilityCard(context),
                  const SizedBox(height: 16),
                  _buildImplementationTestCard(context),
                  const SizedBox(height: 16),
                  _buildTroubleshootingCard(context),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentStatusCard(BuildContext context, NativeRenderingInfo info) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Status',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildStatusRow('Implementation', info.implementationName, 
                info.currentImplementation != NativeRenderingImplementation.mock),
            _buildStatusRow('FFI Available', info.isFFIAvailable ? 'Yes' : 'No', info.isFFIAvailable),
            _buildStatusRow('Platform Channel Available', info.isPlatformChannelAvailable ? 'Yes' : 'No', info.isPlatformChannelAvailable),
            _buildStatusRow('Mock Mode', info.isMockMode ? 'Yes' : 'No', !info.isMockMode),
            _buildStatusRow('Native Rendering Available', info.isNativeRenderingAvailable ? 'Yes' : 'No', info.isNativeRenderingAvailable),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationCard(BuildContext context, NativeRenderingConfig config) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildConfigRow('Preferred Implementation', _getImplementationName(config.preferredImplementation)),
            _buildConfigRow('Native Fallback', config.nativeFallbackEnabled ? 'Enabled' : 'Disabled'),
            _buildConfigRow('Default DPI', '${config.defaultDpi}'),
            _buildConfigRow('Default Format', config.defaultFormat.toUpperCase()),
            _buildConfigRow('Performance Monitoring', config.performanceMonitoringEnabled ? 'Enabled' : 'Disabled'),
            
            const SizedBox(height: 16),
            
            // Configuration controls
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildImplementationChip(NativeRenderingImplementation.auto, config),
                _buildImplementationChip(NativeRenderingImplementation.ffi, config),
                _buildImplementationChip(NativeRenderingImplementation.platformChannel, config),
                _buildImplementationChip(NativeRenderingImplementation.mock, config),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryAvailabilityCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Library Availability',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            if (_availabilityInfo != null) ...[
              _buildInfoRow('Library Name', _availabilityInfo!.libraryName),
              _buildInfoRow('Available', _availabilityInfo!.isAvailable ? 'Yes' : 'No'),
              _buildInfoRow('Available Paths', '${_availabilityInfo!.availablePaths.length}'),
              _buildInfoRow('Errors', '${_availabilityInfo!.errors.length}'),
              
              if (_availabilityInfo!.availablePaths.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Available Paths:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                ..._availabilityInfo!.availablePaths.map((path) => 
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            path,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              if (_availabilityInfo!.errors.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Errors:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                ..._availabilityInfo!.errors.entries.map((entry) => 
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 24),
                          child: Text(
                            entry.value,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.red,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ] else ...[
              const Text('Loading availability information...'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImplementationTestCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Implementation Tests',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            const Text('Test each implementation to verify functionality:'),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _testImplementation(NativeRenderingImplementation.ffi),
                  icon: const Icon(Icons.speed),
                  label: const Text('Test FFI'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _testImplementation(NativeRenderingImplementation.platformChannel),
                  icon: const Icon(Icons.phone_android),
                  label: const Text('Test Platform Channel'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _testImplementation(NativeRenderingImplementation.mock),
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Test Mock'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Troubleshooting',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            const Text('Common issues and solutions:'),
            const SizedBox(height: 8),
            
            _buildTroubleshootingItem(
              'Native library not found',
              'Ensure the native library is installed and accessible. Check the available paths above.',
            ),
            _buildTroubleshootingItem(
              'FFI initialization failed',
              'The native library may be incompatible or corrupted. Try reinstalling or use platform channel fallback.',
            ),
            _buildTroubleshootingItem(
              'Platform channel not available',
              'Platform-specific code may not be implemented. This is expected on some platforms.',
            ),
            _buildTroubleshootingItem(
              'All implementations failing',
              'Check system requirements and ensure the app has necessary permissions.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, bool isGood) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isGood ? Icons.check_circle : Icons.warning,
            color: isGood ? Colors.green : Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildImplementationChip(NativeRenderingImplementation implementation, NativeRenderingConfig config) {
    final isSelected = config.preferredImplementation == implementation;
    
    return FilterChip(
      label: Text(_getImplementationName(implementation)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          ref.read(nativeRenderingConfigProvider.notifier).setPreferredImplementation(implementation);
        }
      },
    );
  }

  Widget _buildTroubleshootingItem(String title, String description) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _getImplementationName(NativeRenderingImplementation implementation) {
    switch (implementation) {
      case NativeRenderingImplementation.auto:
        return 'Auto';
      case NativeRenderingImplementation.ffi:
        return 'FFI';
      case NativeRenderingImplementation.platformChannel:
        return 'Platform Channel';
      case NativeRenderingImplementation.mock:
        return 'Mock';
    }
  }

  Future<void> _testImplementation(NativeRenderingImplementation implementation) async {
    try {
      // Force the implementation
      NativeRenderingFactory.reset();
      
      final worker = switch (implementation) {
        NativeRenderingImplementation.ffi => NativeRenderingFactory.getInstance(),
        NativeRenderingImplementation.platformChannel => NativeRenderingFactory.getInstance(forcePlatformChannel: true),
        NativeRenderingImplementation.mock => NativeRenderingFactory.getInstance(testMode: true),
        NativeRenderingImplementation.auto => NativeRenderingFactory.getInstance(),
      };

      if (!worker.isAvailable) {
        throw Exception('Implementation not available');
      }

      // Test basic functionality
      final pageCount = await worker.getPageCount('/test/path.pdf');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getImplementationName(implementation)} test successful (mock page count: $pageCount)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getImplementationName(implementation)} test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'copy_report':
        _copyDiagnosticsReport();
        break;
      case 'reset_factory':
        _resetFactory();
        break;
    }
  }

  void _copyDiagnosticsReport() {
    if (_availabilityInfo == null) return;
    
    final report = _availabilityInfo!.getDetailedReport();
    Clipboard.setData(ClipboardData(text: report));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Diagnostics report copied to clipboard'),
      ),
    );
  }

  void _resetFactory() {
    NativeRenderingFactory.reset();
    _loadDiagnostics();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Native rendering factory reset'),
      ),
    );
  }
}
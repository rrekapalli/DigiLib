#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

/// Test runner script for the Digital Library App
/// 
/// This script provides a comprehensive test execution framework with
/// support for different test categories, environments, and reporting.
class TestRunner {
  static const String version = '1.0.0';
  
  // Test categories
  static const Map<String, List<String>> testCategories = {
    'unit': [
      'test/auth_provider_test.dart',
      'test/auth_state_test.dart',
      'test/cache_test.dart',
      'test/database_test.dart',
      'test/fts_test.dart',
      'test/models_test.dart',
      'test/secure_storage_test.dart',
      'test/services/',
    ],
    'widget': [
      'test/widgets/',
    ],
    'integration': [
      'test/integration/',
    ],
    'e2e': [
      'test/e2e/',
    ],
    'network': [
      'test/network/',
    ],
  };

  static Future<void> main(List<String> args) async {
    print('🧪 Digital Library App Test Runner v$version\n');

    final config = _parseArguments(args);
    
    if (config['help'] == true) {
      _printHelp();
      return;
    }

    if (config['version'] == true) {
      print('Version: $version');
      return;
    }

    try {
      await _runTests(config);
    } catch (e) {
      print('❌ Test execution failed: $e');
      exit(1);
    }
  }

  static Map<String, dynamic> _parseArguments(List<String> args) {
    final config = <String, dynamic>{
      'category': 'all',
      'coverage': false,
      'verbose': false,
      'parallel': false,
      'help': false,
      'version': false,
      'environment': 'development',
      'output': 'console',
      'timeout': 300,
    };

    for (int i = 0; i < args.length; i++) {
      switch (args[i]) {
        case '--help':
        case '-h':
          config['help'] = true;
          break;
        case '--version':
        case '-v':
          config['version'] = true;
          break;
        case '--category':
        case '-c':
          if (i + 1 < args.length) {
            config['category'] = args[++i];
          }
          break;
        case '--coverage':
          config['coverage'] = true;
          break;
        case '--verbose':
          config['verbose'] = true;
          break;
        case '--parallel':
          config['parallel'] = true;
          break;
        case '--environment':
        case '-e':
          if (i + 1 < args.length) {
            config['environment'] = args[++i];
          }
          break;
        case '--output':
        case '-o':
          if (i + 1 < args.length) {
            config['output'] = args[++i];
          }
          break;
        case '--timeout':
        case '-t':
          if (i + 1 < args.length) {
            config['timeout'] = int.tryParse(args[++i]) ?? 300;
          }
          break;
      }
    }

    return config;
  }

  static void _printHelp() {
    print('''
Digital Library App Test Runner

Usage: dart scripts/run_tests.dart [options]

Options:
  -h, --help              Show this help message
  -v, --version           Show version information
  -c, --category <type>   Run specific test category (unit, widget, integration, e2e, network, all)
  --coverage              Generate code coverage report
  --verbose               Enable verbose output
  --parallel              Run tests in parallel
  -e, --environment <env> Set test environment (development, testing, production)
  -o, --output <format>   Output format (console, json, junit)
  -t, --timeout <seconds> Test timeout in seconds (default: 300)

Examples:
  dart scripts/run_tests.dart                           # Run all tests
  dart scripts/run_tests.dart -c unit                   # Run only unit tests
  dart scripts/run_tests.dart --coverage --verbose      # Run with coverage and verbose output
  dart scripts/run_tests.dart -c e2e -e testing         # Run e2e tests in testing environment
''');
  }

  static Future<void> _runTests(Map<String, dynamic> config) async {
    print('📋 Test Configuration:');
    print('   Category: ${config['category']}');
    print('   Environment: ${config['environment']}');
    print('   Coverage: ${config['coverage']}');
    print('   Verbose: ${config['verbose']}');
    print('   Parallel: ${config['parallel']}');
    print('   Timeout: ${config['timeout']}s\n');

    // Setup test environment
    await _setupTestEnvironment(config);

    // Run tests based on category
    final category = config['category'] as String;
    if (category == 'all') {
      await _runAllTests(config);
    } else {
      await _runCategoryTests(category, config);
    }

    // Generate reports
    await _generateReports(config);

    print('\n✅ Test execution completed successfully!');
  }

  static Future<void> _setupTestEnvironment(Map<String, dynamic> config) async {
    print('🔧 Setting up test environment...');

    // Create test directories
    await _createDirectory('test_reports');
    await _createDirectory('coverage');
    await _createDirectory('screenshots');

    // Set environment variables
    final env = config['environment'] as String;
    switch (env) {
      case 'development':
        Platform.environment['API_BASE_URL'] = 'http://localhost:8080';
        Platform.environment['MOCK_SERVICES'] = 'true';
        break;
      case 'testing':
        Platform.environment['API_BASE_URL'] = 'https://api-test.example.com';
        Platform.environment['MOCK_SERVICES'] = 'false';
        break;
      case 'production':
        Platform.environment['API_BASE_URL'] = 'https://api.example.com';
        Platform.environment['MOCK_SERVICES'] = 'false';
        break;
    }

    print('   ✓ Environment configured for: $env');
  }

  static Future<void> _runAllTests(Map<String, dynamic> config) async {
    print('🚀 Running all test categories...\n');

    final results = <String, bool>{};
    
    for (final category in testCategories.keys) {
      print('📂 Running $category tests...');
      try {
        await _runCategoryTests(category, config);
        results[category] = true;
        print('   ✅ $category tests passed\n');
      } catch (e) {
        results[category] = false;
        print('   ❌ $category tests failed: $e\n');
      }
    }

    // Print summary
    print('📊 Test Results Summary:');
    for (final entry in results.entries) {
      final status = entry.value ? '✅' : '❌';
      print('   $status ${entry.key} tests');
    }

    final failedCount = results.values.where((passed) => !passed).length;
    if (failedCount > 0) {
      throw Exception('$failedCount test categories failed');
    }
  }

  static Future<void> _runCategoryTests(String category, Map<String, dynamic> config) async {
    final testPaths = testCategories[category];
    if (testPaths == null) {
      throw ArgumentError('Unknown test category: $category');
    }

    final commands = <String>[];
    
    for (final path in testPaths) {
      if (path.endsWith('/')) {
        // Directory - find all test files
        final testFiles = await _findTestFiles(path);
        commands.addAll(testFiles);
      } else {
        // Single file
        commands.add(path);
      }
    }

    if (commands.isEmpty) {
      print('   ⚠️  No test files found for category: $category');
      return;
    }

    // Build flutter test command
    final flutterArgs = ['test'];
    
    if (config['coverage'] == true) {
      flutterArgs.addAll(['--coverage']);
    }
    
    if (config['verbose'] == true) {
      flutterArgs.add('--verbose');
    }

    // Add timeout
    flutterArgs.addAll(['--timeout', '${config['timeout']}s']);

    // Add test files
    flutterArgs.addAll(commands);

    // Run tests
    final result = await Process.run('flutter', flutterArgs);
    
    if (result.exitCode != 0) {
      print('STDOUT: ${result.stdout}');
      print('STDERR: ${result.stderr}');
      throw Exception('Tests failed with exit code: ${result.exitCode}');
    }

    if (config['verbose'] == true) {
      print('STDOUT: ${result.stdout}');
    }
  }

  static Future<List<String>> _findTestFiles(String directory) async {
    final testFiles = <String>[];
    final dir = Directory(directory);
    
    if (!await dir.exists()) {
      return testFiles;
    }

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('_test.dart')) {
        testFiles.add(entity.path);
      }
    }

    return testFiles;
  }

  static Future<void> _generateReports(Map<String, dynamic> config) async {
    print('📄 Generating test reports...');

    // Generate coverage report if enabled
    if (config['coverage'] == true) {
      await _generateCoverageReport();
    }

    // Generate test report in requested format
    final outputFormat = config['output'] as String;
    switch (outputFormat) {
      case 'json':
        await _generateJsonReport();
        break;
      case 'junit':
        await _generateJunitReport();
        break;
      case 'console':
      default:
        // Console output is already handled
        break;
    }

    print('   ✓ Reports generated in test_reports/ directory');
  }

  static Future<void> _generateCoverageReport() async {
    print('   📊 Generating coverage report...');
    
    // Convert coverage to LCOV format
    final result = await Process.run('flutter', [
      'test',
      '--coverage',
    ]);

    if (result.exitCode == 0) {
      // Generate HTML coverage report
      await Process.run('genhtml', [
        'coverage/lcov.info',
        '-o',
        'coverage/html',
      ]);
      
      print('   ✓ Coverage report available at coverage/html/index.html');
    }
  }

  static Future<void> _generateJsonReport() async {
    final report = {
      'timestamp': DateTime.now().toIso8601String(),
      'version': version,
      'summary': {
        'total_tests': 0,
        'passed_tests': 0,
        'failed_tests': 0,
        'skipped_tests': 0,
      },
      'categories': testCategories.keys.toList(),
    };

    final file = File('test_reports/test_report.json');
    await file.writeAsString(jsonEncode(report));
  }

  static Future<void> _generateJunitReport() async {
    final xml = '''<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
  <testsuite name="Digital Library App Tests" tests="0" failures="0" errors="0" time="0">
    <!-- Test results will be populated here -->
  </testsuite>
</testsuites>''';

    final file = File('test_reports/junit_report.xml');
    await file.writeAsString(xml);
  }

  static Future<void> _createDirectory(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }
}

void main(List<String> args) async {
  await TestRunner.main(args);
}
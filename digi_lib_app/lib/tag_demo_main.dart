import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/screens/tags/tag_management_screen.dart';

void main() {
  runApp(const ProviderScope(child: TagDemoApp()));
}

class TagDemoApp extends StatelessWidget {
  const TagDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tag Management Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TagDemoHome(),
    );
  }
}

class TagDemoHome extends StatelessWidget {
  const TagDemoHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Tag Management Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Digital Library Tag Management System',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            const Text(
              'This demo showcases the tag management UI components:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text('• Tag creation, editing, and deletion'),
            const Text('• Tag analytics and usage statistics'),
            const Text('• Tag import/export functionality'),
            const Text('• Document tagging interface'),
            const Text('• Bulk tagging operations'),
            const Text('• Tag-based filtering'),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TagManagementScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.label),
              label: const Text('Open Tag Management'),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: DigiLibWebApp()));
}

class DigiLibWebApp extends StatelessWidget {
  const DigiLibWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DigiLib - Web Version',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const WebHomePage(),
    );
  }
}

class WebHomePage extends ConsumerStatefulWidget {
  const WebHomePage({super.key});

  @override
  ConsumerState<WebHomePage> createState() => _WebHomePageState();
}

class _WebHomePageState extends ConsumerState<WebHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const WelcomeTab(),
    const LibraryTab(),
    const SearchTab(),
    const SettingsTab(),
  ];

  final List<String> _titles = [
    'Welcome to DigiLib',
    'My Library',
    'Search Books',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_titles[_selectedIndex]),
        actions: [
          if (kIsWeb) ...[
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Chip(
                label: const Text('Web Version'),
                backgroundColor: Colors.green.withValues(alpha: 0.2),
              ),
            ),
          ],
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class WelcomeTab extends StatelessWidget {
  const WelcomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books,
              size: 120,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 32),
            Text(
              'Welcome to DigiLib',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your Digital Library Management System',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Web Version Features:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('• Browse and search your digital library'),
                    const Text('• Manage your book collection'),
                    const Text('• Cross-platform accessibility'),
                    const Text('• Real-time synchronization'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('DigiLib Web is working correctly!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Test Web Features'),
            ),
          ],
        ),
      ),
    );
  }
}

class LibraryTab extends StatelessWidget {
  const LibraryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'My Books',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...List.generate(5, (index) => Card(
          child: ListTile(
            leading: const Icon(Icons.book, size: 48),
            title: Text('Sample Book ${index + 1}'),
            subtitle: Text('Author ${index + 1}'),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {},
            ),
          ),
        )),
      ],
    );
  }
}

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search for books...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Searching for: $value')),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          const Expanded(
            child: Center(
              child: Text(
                'Enter a search term to find books',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'Settings',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const ListTile(
          leading: Icon(Icons.palette),
          title: Text('Theme'),
          subtitle: Text('Light mode'),
          trailing: Switch(value: false, onChanged: null),
        ),
        const ListTile(
          leading: Icon(Icons.language),
          title: Text('Language'),
          subtitle: Text('English'),
        ),
        const ListTile(
          leading: Icon(Icons.sync),
          title: Text('Sync Settings'),
          subtitle: Text('Auto-sync enabled'),
          trailing: Switch(value: true, onChanged: null),
        ),
        const SizedBox(height: 32),
        Card(
          color: Colors.blue.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Platform Information',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Platform: ${kIsWeb ? 'Web' : 'Native'}'),
                Text('Debug Mode: ${kDebugMode ? 'Yes' : 'No'}'),
                if (kIsWeb) ...[
                  const Text('Browser: Web Browser'),
                  const Text('Responsive: Yes'),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

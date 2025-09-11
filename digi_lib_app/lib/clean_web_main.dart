import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Application providers
final booksProvider = StateProvider<List<Book>>((ref) => []);
final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedBookProvider = StateProvider<Book?>((ref) => null);

class Book {
  final String id;
  final String title;
  final String author;
  final String isbn;
  final String genre;
  final DateTime? publishDate;
  final String description;
  final String? coverUrl;
  final bool isRead;
  final double? rating;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.isbn = '',
    this.genre = '',
    this.publishDate,
    this.description = '',
    this.coverUrl,
    this.isRead = false,
    this.rating,
  });

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? isbn,
    String? genre,
    DateTime? publishDate,
    String? description,
    String? coverUrl,
    bool? isRead,
    double? rating,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      isbn: isbn ?? this.isbn,
      genre: genre ?? this.genre,
      publishDate: publishDate ?? this.publishDate,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      isRead: isRead ?? this.isRead,
      rating: rating ?? this.rating,
    );
  }
}

void main() {
  debugPrint('Starting DigiLib Web Application');
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
            Container(
              margin: const EdgeInsets.only(right: 16.0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'WEB VERSION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ],
      ),
      body: _buildCurrentPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.library_books),
            label: 'Library',
          ),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return const WelcomeTab();
      case 1:
        return const LibraryTab();
      case 2:
        return const SearchTab();
      case 3:
        return const SettingsTab();
      default:
        return const WelcomeTab();
    }
  }
}

class WelcomeTab extends ConsumerWidget {
  const WelcomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(booksProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
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
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Your Digital Library Management System',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard(
                  context,
                  'Total Books',
                  '${books.length}',
                  Icons.library_books,
                  Colors.blue,
                ),
                _buildStatCard(
                  context,
                  'Read Books',
                  '${books.where((book) => book.isRead).length}',
                  Icons.done_all,
                  Colors.green,
                ),
                _buildStatCard(
                  context,
                  'To Read',
                  '${books.where((book) => !book.isRead).length}',
                  Icons.schedule,
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _addNewBook(context, ref),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Book'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _importBooks(context, ref),
                          icon: const Icon(Icons.upload),
                          label: const Text('Import'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _exportLibrary(context, ref),
                          icon: const Icon(Icons.download),
                          label: const Text('Export'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (books.isNotEmpty) ...[
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Activity',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...books
                          .take(3)
                          .map(
                            (book) => ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: book.isRead
                                    ? Colors.green
                                    : Colors.grey,
                                child: Icon(
                                  book.isRead ? Icons.check : Icons.book,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                book.title,
                                style: const TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                'by ${book.author}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _addNewBook(BuildContext context, WidgetRef ref) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add Book functionality coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _importBooks(BuildContext context, WidgetRef ref) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Import functionality coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _exportLibrary(BuildContext context, WidgetRef ref) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class LibraryTab extends ConsumerWidget {
  const LibraryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(booksProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Library (${books.length} books)',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _addSampleBooks(ref),
                icon: const Icon(Icons.add),
                label: const Text('Add Sample Books'),
              ),
            ],
          ),
        ),
        Expanded(
          child: books.isEmpty
              ? _buildEmptyLibrary(context, ref)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: book.isRead
                              ? Colors.green
                              : Theme.of(context).colorScheme.primary,
                          child: Icon(
                            book.isRead ? Icons.done : Icons.book,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          book.title,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('by ${book.author}'),
                            if (book.genre.isNotEmpty)
                              Text(
                                book.genre,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'toggle_read',
                              child: ListTile(
                                leading: Icon(
                                  book.isRead ? Icons.remove_done : Icons.done,
                                ),
                                title: Text(
                                  book.isRead
                                      ? 'Mark as Unread'
                                      : 'Mark as Read',
                                ),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete),
                                title: Text('Delete Book'),
                              ),
                            ),
                          ],
                          onSelected: (value) =>
                              _handleMenuAction(context, ref, value, book),
                        ),
                        isThreeLine: book.genre.isNotEmpty,
                        onTap: () => _showBookDetails(context, book),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyLibrary(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Your library is empty',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first book to get started',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _addSampleBooks(ref),
            icon: const Icon(Icons.add),
            label: const Text('Add Sample Books'),
          ),
        ],
      ),
    );
  }

  void _addSampleBooks(WidgetRef ref) {
    final sampleBooks = [
      Book(
        id: '1',
        title: '1984',
        author: 'George Orwell',
        genre: 'Dystopian Fiction',
        isbn: '978-0-452-28423-4',
        description:
            'A dystopian social science fiction novel about totalitarianism.',
        rating: 4.5,
        publishDate: DateTime(1949, 6, 8),
      ),
      Book(
        id: '2',
        title: 'To Kill a Mockingbird',
        author: 'Harper Lee',
        genre: 'Southern Gothic',
        isbn: '978-0-06-112008-4',
        description:
            'A novel about racial injustice and childhood in the American South.',
        rating: 4.3,
        isRead: true,
        publishDate: DateTime(1960, 7, 11),
      ),
      Book(
        id: '3',
        title: 'The Great Gatsby',
        author: 'F. Scott Fitzgerald',
        genre: 'American Literature',
        isbn: '978-0-7432-7356-5',
        description:
            'A classic novel about the Jazz Age and the American Dream.',
        rating: 4.1,
        publishDate: DateTime(1925, 4, 10),
      ),
    ];

    ref.read(booksProvider.notifier).state = [
      ...ref.read(booksProvider),
      ...sampleBooks,
    ];
  }

  void _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    Book book,
  ) {
    switch (action) {
      case 'toggle_read':
        final updatedBooks = ref.read(booksProvider).map((b) {
          if (b.id == book.id) {
            return b.copyWith(isRead: !b.isRead);
          }
          return b;
        }).toList();
        ref.read(booksProvider.notifier).state = updatedBooks;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              book.isRead
                  ? '${book.title} marked as unread'
                  : '${book.title} marked as read',
            ),
          ),
        );
        break;
      case 'delete':
        final updatedBooks = ref
            .read(booksProvider)
            .where((b) => b.id != book.id)
            .toList();
        ref.read(booksProvider.notifier).state = updatedBooks;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${book.title} removed from library'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                ref.read(booksProvider.notifier).state = [
                  ...ref.read(booksProvider),
                  book,
                ];
              },
            ),
          ),
        );
        break;
    }
  }

  void _showBookDetails(BuildContext context, Book book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(book.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Author: ${book.author}'),
            if (book.genre.isNotEmpty) Text('Genre: ${book.genre}'),
            if (book.isbn.isNotEmpty) Text('ISBN: ${book.isbn}'),
            if (book.rating != null)
              Text('Rating: ${book.rating!.toStringAsFixed(1)}/5'),
            if (book.publishDate != null)
              Text('Published: ${book.publishDate!.year}'),
            const SizedBox(height: 8),
            Text('Status: ${book.isRead ? "Read" : "To Read"}'),
            if (book.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(book.description),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class SearchTab extends ConsumerStatefulWidget {
  const SearchTab({super.key});

  @override
  ConsumerState<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<SearchTab> {
  final _searchController = TextEditingController();
  List<Book> _searchResults = [];
  String _selectedFilter = 'All';

  final List<String> _filterOptions = [
    'All',
    'Read',
    'Unread',
    'Fiction',
    'Non-Fiction',
  ];

  void _performSearch(String query) {
    final allBooks = ref.read(booksProvider);
    setState(() {
      if (query.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = allBooks.where((book) {
          final matchesQuery =
              book.title.toLowerCase().contains(query.toLowerCase()) ||
              book.author.toLowerCase().contains(query.toLowerCase()) ||
              book.genre.toLowerCase().contains(query.toLowerCase());

          final matchesFilter =
              _selectedFilter == 'All' ||
              (_selectedFilter == 'Read' && book.isRead) ||
              (_selectedFilter == 'Unread' && !book.isRead) ||
              (_selectedFilter == 'Fiction' &&
                  book.genre.toLowerCase().contains('fiction')) ||
              (_selectedFilter == 'Non-Fiction' &&
                  !book.genre.toLowerCase().contains('fiction'));

          return matchesQuery && matchesFilter;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(booksProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search for books, authors, genres...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch('');
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: _performSearch,
                  onSubmitted: _performSearch,
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _selectedFilter,
                items: _filterOptions.map((filter) {
                  return DropdownMenuItem(value: filter, child: Text(filter));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value ?? 'All';
                    _performSearch(_searchController.text);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (books.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.library_books_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No books in your library yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add some books to start searching',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: _searchResults.isEmpty && _searchController.text.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No books found matching "${_searchController.text}"',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : _searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Search your library',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You have ${books.length} books to search through',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final book = _searchResults[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: book.isRead
                                  ? Colors.green
                                  : Theme.of(context).colorScheme.primary,
                              child: Icon(
                                book.isRead ? Icons.done : Icons.book,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              book.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              'by ${book.author}${book.genre.isNotEmpty ? " • ${book.genre}" : ""}',
                            ),
                            trailing: book.rating != null
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          size: 14,
                                          color: Colors.amber,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          book.rating!.toStringAsFixed(1),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  )
                                : null,
                            onTap: () => _showBookDetails(context, book),
                          ),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }

  void _showBookDetails(BuildContext context, Book book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(book.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Author: ${book.author}'),
            if (book.genre.isNotEmpty) Text('Genre: ${book.genre}'),
            if (book.isbn.isNotEmpty) Text('ISBN: ${book.isbn}'),
            if (book.rating != null)
              Text('Rating: ${book.rating!.toStringAsFixed(1)}/5'),
            if (book.publishDate != null)
              Text('Published: ${book.publishDate!.year}'),
            const SizedBox(height: 8),
            Text('Status: ${book.isRead ? "Read" : "To Read"}'),
            if (book.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(book.description),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
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
        Text(
          'Settings',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.palette),
                title: Text('Theme'),
                subtitle: Text('Light mode'),
                trailing: Switch(value: false, onChanged: null),
              ),
              ListTile(
                leading: Icon(Icons.language),
                title: Text('Language'),
                subtitle: Text('English'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
              ListTile(
                leading: Icon(Icons.sync),
                title: Text('Auto-sync'),
                subtitle: Text('Sync with cloud storage'),
                trailing: Switch(value: true, onChanged: null),
              ),
              ListTile(
                leading: Icon(Icons.notifications),
                title: Text('Notifications'),
                subtitle: Text('Enable push notifications'),
                trailing: Switch(value: true, onChanged: null),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: Colors.blue.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Platform Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Platform',
                  kIsWeb ? 'Web Browser' : 'Native App',
                ),
                _buildInfoRow('Last Updated', 'September 2025'),
                _buildInfoRow('Responsive', 'Yes'),
                _buildInfoRow('Version', '1.0.0'),
                if (kIsWeb) ...[
                  _buildInfoRow('PWA Ready', 'Yes'),
                  _buildInfoRow('Offline Support', 'Coming Soon'),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

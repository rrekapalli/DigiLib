import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/models/entities/book.dart';
import 'src/services/book_to_document_service.dart';

// Web-compatible document reader screen for demo
class DocumentReaderScreen extends StatefulWidget {
  final String documentId;

  const DocumentReaderScreen({super.key, required this.documentId});

  @override
  State<DocumentReaderScreen> createState() => _DocumentReaderScreenState();
}

class _DocumentReaderScreenState extends State<DocumentReaderScreen> {
  int _currentPage = 1;
  final int _totalPages = 150;
  double _zoom = 1.0;
  bool _showControls = true;

  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() => _currentPage++);
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() => _currentPage--);
    }
  }

  void _zoomIn() {
    setState(() => _zoom = (_zoom * 1.2).clamp(0.5, 3.0));
  }

  void _zoomOut() {
    setState(() => _zoom = (_zoom / 1.2).clamp(0.5, 3.0));
  }

  Widget _buildDocumentContent() {
    // Simulate different document types based on document ID
    String content = _getDocumentContent();

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 800),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Transform.scale(
        scale: _zoom,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document header
            Text(
              'Page $_currentPage',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Document content
            Text(
              content,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.6, fontSize: 16),
            ),

            const SizedBox(height: 40),

            // Page footer
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text(
              'Document ID: ${widget.documentId} | Page $_currentPage of $_totalPages',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  String _getDocumentContent() {
    // Generate different content for each page to simulate real document
    final baseContent = {
      1: '''
Introduction to Digital Libraries

Digital libraries have revolutionized how we access, store, and manage information in the modern era. They represent a paradigm shift from traditional physical libraries to sophisticated digital repositories that can be accessed from anywhere in the world.

The concept of digital libraries emerged in the 1990s as computing technology advanced and the internet became more widespread. These systems combine traditional library science principles with cutting-edge information technology to create powerful knowledge management tools.

Key characteristics of digital libraries include:

• Universal access regardless of geographical location
• 24/7 availability for users worldwide  
• Advanced search capabilities across multiple documents
• Multimedia content support (text, images, video, audio)
• Preservation of digital heritage and rare materials
• Cost-effective storage and distribution
• Integration with modern research workflows

This document explores the fundamental concepts, technologies, and applications that make digital libraries an essential component of today's information landscape.
''',
      2: '''
Historical Development

The evolution of digital libraries can be traced through several key phases:

Early Development (1990s)
The first digital library initiatives began in the early 1990s with projects like the Digital Library Initiative funded by NSF, DARPA, and NASA. These pioneering efforts established the foundational technologies and standards that continue to influence modern systems.

Expansion Phase (2000s)  
The widespread adoption of the internet led to rapid expansion of digital library services. Major institutions began digitizing their collections, and new standards like Dublin Core emerged for metadata management.

Modern Era (2010s-Present)
Today's digital libraries leverage cloud computing, artificial intelligence, and advanced user interfaces to provide seamless access to vast collections of digital resources. Integration with mobile devices and social platforms has further enhanced accessibility.

The journey from simple text repositories to today's sophisticated multimedia platforms demonstrates the remarkable progress in this field.
''',
    };

    // Return content for current page or generate generic content
    return baseContent[_currentPage] ??
        '''
Content for Page $_currentPage

This page contains sample content to demonstrate the document reader functionality. In a real implementation, this would display the actual content from PDF, EPUB, DOCX, or MOBI files.

The digital library application supports multiple document formats and provides features like:

• Full-text search across documents
• Bookmarks and annotations  
• Zoom and navigation controls
• Responsive design for various screen sizes
• Offline reading capabilities
• Document sharing and collaboration

Each page would contain the actual extracted text and images from the source document, properly formatted and displayed with consistent styling throughout the reading experience.

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.

Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Document Reader'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.fullscreen),
            onPressed: () {
              setState(() => _showControls = !_showControls);
            },
            tooltip: 'Toggle fullscreen',
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_add),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Bookmark added for page $_currentPage'),
                ),
              );
            },
            tooltip: 'Add bookmark',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Settings functionality could be added here
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          if (_showControls)
            Container(
              width: double.infinity,
              height: 4,
              color: Colors.grey[200],
              child: FractionallySizedBox(
                widthFactor: _currentPage / _totalPages,
                alignment: Alignment.centerLeft,
                child: Container(color: Theme.of(context).primaryColor),
              ),
            ),

          // Main content area
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: _buildDocumentContent(),
              ),
            ),
          ),

          // Navigation controls
          if (_showControls)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Zoom controls
                  IconButton(
                    onPressed: _zoomOut,
                    icon: const Icon(Icons.zoom_out),
                    tooltip: 'Zoom out',
                  ),
                  Text('${(_zoom * 100).round()}%'),
                  IconButton(
                    onPressed: _zoomIn,
                    icon: const Icon(Icons.zoom_in),
                    tooltip: 'Zoom in',
                  ),

                  const Spacer(),

                  // Page navigation
                  IconButton(
                    onPressed: _currentPage > 1 ? _previousPage : null,
                    icon: const Icon(Icons.navigate_before),
                    tooltip: 'Previous page',
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$_currentPage / $_totalPages',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  IconButton(
                    onPressed: _currentPage < _totalPages ? _nextPage : null,
                    icon: const Icon(Icons.navigate_next),
                    tooltip: 'Next page',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// Application providers
final booksProvider = StateProvider<List<Book>>((ref) => []);
final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedBookProvider = StateProvider<Book?>((ref) => null);

void main() {
  runApp(const ProviderScope(child: DigiLibApp()));
}

class DigiLibApp extends StatelessWidget {
  const DigiLibApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DigiLib - Web Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });

    // Add sample books on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addSampleBooks(ref);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('Starting DigiLib Web Application');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('DigiLib'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.library_books), text: 'Library'),
            Tab(icon: Icon(Icons.search), text: 'Search'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [LibraryTab(), SearchTab(), SettingsTab()],
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
              : _buildBooksList(context, books),
        ),
      ],
    );
  }

  Widget _buildBooksList(BuildContext context, List<Book> books) {
    return ListView.builder(
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
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
            trailing: Consumer(
              builder: (context, ref, child) => PopupMenuButton<String>(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'read',
                    child: ListTile(
                      leading: const Icon(Icons.book),
                      title: const Text('Read Book'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_read',
                    child: ListTile(
                      leading: Icon(
                        book.isRead ? Icons.remove_done : Icons.done,
                      ),
                      title: Text(
                        book.isRead ? 'Mark as Unread' : 'Mark as Read',
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete),
                      title: Text('Delete Book'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                onSelected: (value) =>
                    _handleMenuAction(context, ref, value, book),
              ),
            ),
            isThreeLine: book.genre.isNotEmpty,
            onTap: () => _showBookDetails(context, book),
          ),
        );
      },
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
        id: '4',
        title: 'Pride and Prejudice',
        author: 'Jane Austen',
        genre: 'Romance',
        isbn: '978-0-14-143951-8',
        description: 'A romantic novel of manners.',
        rating: 4.2,
        publishDate: DateTime(1813, 1, 28),
      ),
      Book(
        id: '5',
        title: 'The Catcher in the Rye',
        author: 'J.D. Salinger',
        genre: 'Coming-of-age',
        isbn: '978-0-316-76948-0',
        description: 'A controversial novel about teenage rebellion.',
        rating: 3.8,
        publishDate: DateTime(1951, 7, 16),
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
      case 'read':
        _openBookReader(context, book);
        break;
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
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog first
              _openBookReader(context, book);
            },
            icon: Icon(
              BookToDocumentService.getFormatIcon(
                BookToDocumentService.inferFormatFromTitle(book.title),
              ),
            ),
            label: const Text('Read'),
          ),
        ],
      ),
    );
  }

  void _openBookReader(BuildContext context, Book book) {
    final document = BookToDocumentService.convertBookToDocument(book);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DocumentReaderScreen(documentId: document.id),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    final allBooks = ref.read(booksProvider);

    setState(() {
      if (query.isEmpty) {
        _searchResults = allBooks;
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
                    hintText: 'Search books...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _performSearch('');
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  onChanged: _performSearch,
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _selectedFilter,
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All')),
                  DropdownMenuItem(value: 'Read', child: Text('Read')),
                  DropdownMenuItem(value: 'Unread', child: Text('Unread')),
                  DropdownMenuItem(value: 'Fiction', child: Text('Fiction')),
                  DropdownMenuItem(
                    value: 'Non-Fiction',
                    child: Text('Non-Fiction'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedFilter = value;
                    });
                    _performSearch(_searchController.text);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _searchResults.isEmpty && books.isNotEmpty
                ? const Center(
                    child: Text(
                      'No books match your search criteria.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchResults.isEmpty
                        ? books.length
                        : _searchResults.length,
                    itemBuilder: (context, index) {
                      final book = _searchResults.isEmpty
                          ? books[index]
                          : _searchResults[index];
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
                                    color: Colors.amber.withValues(alpha: 0.2),
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
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog first
              _openBookReader(context, book);
            },
            icon: Icon(
              BookToDocumentService.getFormatIcon(
                BookToDocumentService.inferFormatFromTitle(book.title),
              ),
            ),
            label: const Text('Read'),
          ),
        ],
      ),
    );
  }

  void _openBookReader(BuildContext context, Book book) {
    final document = BookToDocumentService.convertBookToDocument(book);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DocumentReaderScreen(documentId: document.id),
      ),
    );
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
        const Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.storage),
                title: Text('Storage'),
                subtitle: Text('Manage downloaded books'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
              ListTile(
                leading: Icon(Icons.backup),
                title: Text('Backup & Sync'),
                subtitle: Text('Cloud backup settings'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
              ListTile(
                leading: Icon(Icons.security),
                title: Text('Privacy & Security'),
                subtitle: Text('Control your data'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.help),
                title: Text('Help & Support'),
                subtitle: Text('Get help with the app'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
              ListTile(
                leading: Icon(Icons.info),
                title: Text('About'),
                subtitle: Text('App version and information'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

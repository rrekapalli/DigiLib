/// Simple Book model for web demo
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

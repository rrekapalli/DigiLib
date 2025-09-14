import 'package:flutter/material.dart';
import '../models/entities/document.dart';
import '../models/entities/book.dart';

/// Service for converting Book model to Document model for reader compatibility
class BookToDocumentService {
  /// Converts a Book instance to a Document instance for use with the document reader
  static Document convertBookToDocument(Book book) {
    // Create a synthetic document ID based on book ID
    final documentId = 'book-${book.id}';

    // Map book format to document format based on common file extensions
    String? format = inferFormatFromTitle(book.title);

    // Create synthetic file path - in a real implementation, this would be actual file paths
    final filename = _sanitizeFilename(book.title);
    final extension = _getExtensionFromFormat(format);
    final fullFilename = '$filename.$extension';

    return Document(
      id: documentId,
      libraryId: 'web-library', // Synthetic library ID for web books
      title: book.title,
      author: book.author,
      filename: fullFilename,
      relativePath: 'books/$fullFilename',
      fullPath: '/synthetic/books/$fullFilename', // Synthetic path
      extension: extension,
      renamedName: null,
      isbn: book.isbn.isNotEmpty ? book.isbn : null,
      yearPublished: book.publishDate?.year,
      status: 'available',
      cloudId: null,
      sha256: _generateSyntheticHash(book.id),
      sizeBytes: _estimateBookSize(book.title, book.description),
      pageCount: _estimatePageCount(book.description),
      format: format,
      imageUrl: book.coverUrl,
      amazonUrl: null,
      reviewUrl: null,
      metadataJson: {
        'genre': book.genre,
        'rating': book.rating,
        'isRead': book.isRead,
        'description': book.description,
        'sourceType': 'web-book', // Mark this as coming from web book data
        'originalBookId': book.id,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Infers document format from book title or metadata
  static String? inferFormatFromTitle(String title) {
    // In a real implementation, this would check actual file associations
    // For now, we'll default to PDF as it's the most common format
    final titleLower = title.toLowerCase();

    if (titleLower.contains('epub') || titleLower.contains('ebook')) {
      return 'epub';
    } else if (titleLower.contains('docx') || titleLower.contains('word')) {
      return 'docx';
    } else if (titleLower.contains('mobi') || titleLower.contains('kindle')) {
      return 'mobi';
    }

    // Default to PDF
    return 'pdf';
  }

  /// Gets file extension from format
  static String _getExtensionFromFormat(String? format) {
    switch (format?.toLowerCase()) {
      case 'epub':
        return 'epub';
      case 'docx':
        return 'docx';
      case 'mobi':
        return 'mobi';
      case 'pdf':
      default:
        return 'pdf';
    }
  }

  /// Sanitizes book title for use as filename
  static String _sanitizeFilename(String title) {
    return title
        .replaceAll(
          RegExp(r'[<>:"/\\|?*]'),
          '',
        ) // Remove invalid filename characters
        .replaceAll(RegExp(r'\s+'), '_') // Replace spaces with underscores
        .toLowerCase();
  }

  /// Generates a synthetic hash for the book
  static String _generateSyntheticHash(String bookId) {
    // Create a consistent hash based on book ID
    return 'synthetic_${bookId}_hash';
  }

  /// Estimates book file size based on content
  static int _estimateBookSize(String title, String description) {
    // Rough estimate: longer titles and descriptions = larger books
    final baseSize = 1024 * 1024; // 1MB base size
    final titleFactor = title.length * 1000;
    final descFactor = description.length * 500;
    return baseSize + titleFactor + descFactor;
  }

  /// Estimates page count based on description length and typical book standards
  static int _estimatePageCount(String description) {
    if (description.isEmpty) return 200; // Default page count

    // Rough estimate: 250-300 words per page, ~5 chars per word
    final estimatedWords = description.length ~/ 5;
    final estimatedPages = (estimatedWords ~/ 275).clamp(50, 800);

    return estimatedPages;
  }

  /// Checks if a book can be opened in the reader
  static bool canOpenInReader(Book book) {
    // In a real implementation, this would check if the actual file exists
    // For demo purposes, allow all books to be "opened"
    return true;
  }

  /// Gets the appropriate icon for the book format
  static IconData getFormatIcon(String? format) {
    switch (format?.toLowerCase()) {
      case 'epub':
        return Icons.book;
      case 'docx':
        return Icons.description;
      case 'mobi':
        return Icons.import_contacts;
      case 'pdf':
      default:
        return Icons.picture_as_pdf;
    }
  }
}

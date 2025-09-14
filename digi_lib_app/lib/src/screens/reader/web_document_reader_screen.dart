import 'package:flutter/material.dart';

/// Web-compatible document reader screen with continuous scrolling
class WebDocumentReaderScreen extends StatefulWidget {
  final String documentId;
  final String? initialPage;

  const WebDocumentReaderScreen({
    super.key,
    required this.documentId,
    this.initialPage,
  });

  @override
  State<WebDocumentReaderScreen> createState() =>
      _WebDocumentReaderScreenState();
}

class _WebDocumentReaderScreenState extends State<WebDocumentReaderScreen> {
  double _zoom = 1.0;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    setState(() => _zoom = (_zoom * 1.2).clamp(0.5, 3.0));
  }

  void _zoomOut() {
    setState(() => _zoom = (_zoom / 1.2).clamp(0.5, 3.0));
  }

  void _resetZoom() {
    setState(() => _zoom = 1.0);
  }

  List<String> _getAllContent() {
    return [
      '''Introduction to Digital Libraries

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

This document explores the fundamental concepts, technologies, and applications that make digital libraries an essential component of today's information landscape.''',

      '''Historical Development

The evolution of digital libraries can be traced through several key phases:

Early Development (1990s)
The first digital library initiatives began in the early 1990s with projects like the Digital Library Initiative funded by NSF, DARPA, and NASA. These pioneering efforts established the foundational technologies and standards that continue to influence modern systems.

Expansion Phase (2000s)  
The widespread adoption of the internet led to rapid expansion of digital library services. Major institutions began digitizing their collections, and new standards like Dublin Core emerged for metadata management.

Modern Era (2010s-Present)
Today's digital libraries leverage cloud computing, artificial intelligence, and advanced user interfaces to provide seamless access to vast collections of digital resources. Integration with mobile devices and social platforms has further enhanced accessibility.

The journey from simple text repositories to today's sophisticated multimedia platforms demonstrates the remarkable progress in this field.''',

      '''Technical Architecture

The technical foundation of modern digital libraries consists of several interconnected layers:

Storage Layer
- Distributed file systems for scalable document storage
- Database systems for metadata and indexing
- Backup and redundancy systems for data preservation
- Content delivery networks for global distribution

Processing Layer  
- Document conversion and format standardization
- Full-text indexing and search capabilities
- Image processing and OCR for scanned documents
- Metadata extraction and enrichment

Presentation Layer
- Web-based user interfaces for document access
- Mobile applications for on-the-go reading
- API endpoints for third-party integrations
- Accessibility features for inclusive design

Security Layer
- Authentication and authorization systems
- Encryption for data in transit and at rest
- Digital rights management for protected content
- Audit logging for compliance and monitoring

This multi-layered approach ensures robust, scalable, and secure document management across diverse use cases.''',

      '''User Experience Design

Modern digital libraries prioritize user experience through intuitive design and responsive interfaces:

Interface Design Principles
- Clean, uncluttered layouts that focus on content
- Consistent navigation patterns across all sections
- Mobile-first responsive design for all devices
- Accessibility compliance for inclusive access
- Fast loading times and smooth interactions

Search and Discovery
- Advanced search with filtering and faceting
- Auto-complete suggestions and spell checking
- Visual search results with thumbnails and previews
- Personalized recommendations based on usage
- Integration with external discovery services

Reading Experience
- Full-screen reading mode for immersive experience
- Adjustable text size and contrast settings
- Note-taking and highlighting capabilities
- Bookmark management for easy reference
- Cross-device synchronization of reading progress

These design considerations ensure that users can efficiently find, access, and interact with digital content in meaningful ways.''',

      '''Content Management Systems

Digital libraries rely on sophisticated content management systems to organize and deliver resources:

Metadata Standards
- Dublin Core for basic bibliographic information
- MODS (Metadata Object Description Schema) for detailed records
- PREMIS for preservation metadata
- Custom schemas for specialized collections
- Linked data integration with external vocabularies

Digital Asset Management
- High-resolution master file preservation
- Multiple derivative formats for different uses
- Automated quality control and validation
- Version control for edited content
- Rights management and access controls

Workflow Systems
- Automated ingest processes for bulk content
- Quality assurance checkpoints and approvals
- Collaborative editing and review tools
- Publishing workflows with scheduling
- Integration with external systems and APIs

These systems ensure that digital content is properly managed, preserved, and made accessible to users while maintaining quality and consistency across the entire collection.''',

      '''Future Trends and Technologies

The digital library landscape continues to evolve with emerging technologies:

Artificial Intelligence and Machine Learning
- Automated metadata generation and enhancement
- Content analysis and subject classification
- Personalized content recommendations
- Natural language processing for full-text search
- Image recognition for visual content analysis

Cloud Computing and Scalability
- Elastic infrastructure that scales with demand
- Global content delivery networks
- Serverless architectures for cost efficiency
- Multi-cloud strategies for resilience
- Edge computing for improved performance

Emerging Standards and Protocols
- IIIF (International Image Interoperability Framework)
- Linked Open Data for semantic web integration
- Blockchain for provenance and authenticity
- API-first architectures for integration
- Progressive Web Apps for mobile experience

These technological advances promise to make digital libraries more intelligent, accessible, and valuable to users worldwide, while reducing operational costs and improving sustainability.''',
    ];
  }

  Widget _buildContinuousContent() {
    final content = _getAllContent();

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 900),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Transform.scale(
        scale: _zoom,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document title
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.only(bottom: 20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Digital Libraries: A Comprehensive Guide',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Document ID: ${widget.documentId}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A comprehensive exploration of digital library systems, architecture, and future trends.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            // Continuous content sections
            ...content.asMap().entries.map((entry) {
              final index = entry.key;
              final sectionContent = entry.value;

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(bottom: 20),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section number
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Chapter ${index + 1}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section content
                    Text(
                      sectionContent,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.8,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }),

            // End of document
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.only(bottom: 40),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.check_circle, size: 48, color: Colors.green[600]),
                  const SizedBox(height: 12),
                  Text(
                    'End of Document',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You have reached the end of this document.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Top toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Back to library',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Document Reader',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Zoom controls
                IconButton(
                  onPressed: _zoomOut,
                  icon: const Icon(Icons.zoom_out),
                  tooltip: 'Zoom out',
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${(_zoom * 100).round()}%',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  onPressed: _zoomIn,
                  icon: const Icon(Icons.zoom_in),
                  tooltip: 'Zoom in',
                ),

                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'reset_zoom':
                        _resetZoom();
                        break;
                      case 'scroll_to_top':
                        _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                        break;
                      case 'scroll_to_bottom':
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'reset_zoom',
                      child: ListTile(
                        leading: Icon(Icons.center_focus_strong),
                        title: Text('Reset Zoom'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'scroll_to_top',
                      child: ListTile(
                        leading: Icon(Icons.vertical_align_top),
                        title: Text('Go to Top'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'scroll_to_bottom',
                      child: ListTile(
                        leading: Icon(Icons.vertical_align_bottom),
                        title: Text('Go to Bottom'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main scrolling content - full height
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(child: _buildContinuousContent()),
            ),
          ),
        ],
      ),
    );
  }
}

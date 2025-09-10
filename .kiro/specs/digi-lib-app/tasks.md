# Implementation Plan

- [x] 1. Set up project structure and core dependencies





  - Create Flutter project with multi-platform support (desktop, mobile)
  - Add core dependencies: sqflite, flutter_secure_storage, http/dio, provider/riverpod, ffi
  - Configure platform-specific settings for Windows, macOS, Linux, Android, iOS
  - Set up project directory structure with lib/src folders for screens, services, models, database
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6_

- [x] 2. Implement core data models and serialization





  - [x] 2.1 Create base entity models


    - Implement User, Library, Document, Page, Tag, Bookmark, Comment, Share, ReadingProgress models
    - Add JSON serialization/deserialization methods for all models
    - Include proper UUID handling and DateTime conversion
    - _Requirements: 2.1, 2.2, 2.3, 6.1, 6.2_

  - [x] 2.2 Create API request/response models


    - Implement AuthResult, DocumentListResponse, SearchResponse, RenderResponse models
    - Add CreateLibraryRequest, UpdateDocumentRequest, CreateBookmarkRequest models
    - Implement SyncManifest, SyncChange, SyncPushRequest/Response models
    - Create Pagination and error handling models
    - _Requirements: 5.1, 5.2, 6.1, 6.2, 6.3_

- [x] 3. Set up local database and caching infrastructure




  - [x] 3.1 Implement SQLite database schema


    - Create database helper class with table creation scripts
    - Implement all tables from design: users, libraries, documents, pages, tags, etc.
    - Add proper indexes for performance optimization
    - Create database migration system for schema updates
    - _Requirements: 7.1, 7.2, 10.1, 10.5_

  - [x] 3.2 Implement FTS5 full-text search


    - Set up FTS5 virtual table for documents_fts
    - Create search indexing methods for document content
    - Implement local search functionality with ranking
    - Add search result highlighting and pagination
    - _Requirements: 5.1, 5.3, 7.1_

  - [x] 3.3 Create cache management system


    - Implement file cache for rendered pages and thumbnails
    - Create LRU cache eviction policy with configurable size limits
    - Add cache metadata tracking in SQLite
    - Implement cache warming and preloading strategies
    - _Requirements: 4.6, 7.4, 10.3, 10.5_

- [x] 4. Implement secure storage and authentication foundation




  - [x] 4.1 Set up secure storage for tokens


    - Implement SecureStorageService using flutter_secure_storage
    - Add methods for storing/retrieving refresh tokens and sensitive config
    - Implement platform-specific keystore integration
    - Add proper error handling for storage operations
    - _Requirements: 1.4, 1.5, 9.1, 9.4_

  - [x] 4.2 Create authentication state management


    - Implement AuthState model and AuthNotifier with Riverpod
    - Add authentication status tracking (authenticated, unauthenticated, loading)
    - Create token expiration handling and automatic refresh logic
    - Implement logout and session cleanup functionality
    - _Requirements: 1.1, 1.2, 1.5, 1.6_

- [x] 5. Build API client and network layer





  - [x] 5.1 Create base API client


    - Implement ApiClient with HTTP methods (GET, POST, PUT, DELETE)
    - Add JWT Bearer token authentication header management
    - Implement request/response interceptors for logging and error handling
    - Add network connectivity checking and retry logic
    - _Requirements: 1.1, 1.5, 6.1, 9.2_

  - [x] 5.2 Implement authentication API service


    - Create AuthApiService with OAuth2 flow methods
    - Implement signInWithOAuth2, refreshToken, getCurrentUser methods
    - Add proper error handling for authentication failures
    - Integrate with secure storage for token management
    - _Requirements: 1.1, 1.2, 1.3, 1.5, 1.6_

  - [x] 5.3 Create library management API service


    - Implement LibraryApiService with CRUD operations
    - Add getLibraries, addLibrary, scanLibrary, deleteLibrary methods
    - Implement scan job status polling and progress tracking
    - Add proper error handling and offline queue support
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

- [x] 6. Implement document management services





  - [x] 6.1 Create document API service


    - Implement DocumentApiService with full CRUD operations
    - Add getDocuments with pagination, filtering, and search
    - Implement getDocument, updateDocument, deleteDocument methods
    - Add getDocumentPages and getPageText methods
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

  - [x] 6.2 Build page rendering service


    - Create PageRenderingService combining API and native rendering
    - Implement getPageRenderUrl for server-side rendering
    - Add fallback to native rendering when API fails
    - Implement page caching and preloading logic
    - _Requirements: 4.1, 4.2, 4.4, 4.5, 4.6, 8.1, 8.2, 8.3_

- [x] 7. Implement native worker integration





  - [x] 7.1 Set up FFI bindings for native rendering


    - Create NativeRenderingWorker interface and implementation
    - Set up dart:ffi bindings for Rust/C++ native library
    - Implement renderPage, extractText, getPageCount methods
    - Add proper error handling and memory management
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

  - [x] 7.2 Create platform channel fallback


    - Implement platform channel communication as fallback
    - Add method channel for renderPage, extractText operations
    - Implement proper platform-specific error handling
    - Add performance monitoring and logging
    - _Requirements: 8.1, 8.2, 8.4_

- [x] 8. Build reader functionality and annotations





  - [x] 8.1 Implement bookmark management


    - Create BookmarkService with API integration
    - Add addBookmark, getBookmarks, updateBookmark, deleteBookmark methods
    - Implement local caching and offline queue for bookmarks
    - Add sync conflict resolution for bookmark changes
    - _Requirements: 4.3, 6.2, 6.4, 7.3_

  - [x] 8.2 Create comment system


    - Implement CommentService with full CRUD operations
    - Add addComment, getComments, updateComment, deleteComment methods
    - Implement anchor positioning for text selection comments
    - Add local caching and offline sync for comments
    - _Requirements: 4.3, 6.2, 6.4, 7.3_

  - [x] 8.3 Build reading progress tracking


    - Create ReadingProgressService with API integration
    - Implement updateReadingProgress and getReadingProgress methods
    - Add automatic progress saving during reading sessions
    - Implement cross-device progress synchronization
    - _Requirements: 6.1, 6.2, 6.4, 6.5_

- [x] 9. Implement search functionality





  - [x] 9.1 Create local search service


    - Implement LocalSearchService using SQLite FTS5
    - Add searchLocal method with filters and ranking
    - Implement search result highlighting and snippets
    - Add search history and suggestions
    - _Requirements: 5.1, 5.4, 7.1_

  - [x] 9.2 Build global search integration


    - Create GlobalSearchService with API integration
    - Implement searchGlobal method with backend API calls
    - Add search result aggregation and deduplication
    - Implement fallback to local search when API fails
    - _Requirements: 5.2, 5.3, 5.4, 5.5_

- [x] 10. Create tag management system





  - [x] 10.1 Implement tag service


    - Create TagService with full CRUD operations
    - Add getTags, createTag, deleteTag methods
    - Implement addTagToDocument and removeTagFromDocument
    - Add local caching and offline sync for tag operations
    - _Requirements: 3.5, 6.2, 6.4_

  - [x] 10.2 Build tag-based filtering and organization


    - Implement getDocumentTags and getDocumentsByTag methods
    - Add tag-based document filtering in UI
    - Create tag suggestion and auto-completion
    - Implement tag usage analytics and popular tags
    - _Requirements: 3.1, 3.4, 3.5_

- [x] 11. Implement sharing and collaboration




  - [x] 11.1 Create share management service


    - Implement ShareService with full CRUD operations
    - Add createShare, getShares, getSharedWithMe methods
    - Implement updateSharePermission and deleteShare
    - Add permission validation and access control
    - _Requirements: 6.2, 6.4_

  - [x] 11.2 Build collaborative features


    - Implement shared document access and viewing
    - Add permission-based feature restrictions (view/comment/full)
    - Create share invitation and notification system
    - Implement shared annotation visibility
    - _Requirements: 6.2, 6.4_

- [x] 12. Build synchronization system




  - [x] 12.1 Implement delta sync service


    - Create SyncService with delta synchronization
    - Implement getSyncManifest and pushLocalChanges methods
    - Add conflict detection and resolution strategies
    - Create sync status tracking and progress reporting
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

  - [x] 12.2 Create offline action queue


    - Implement offline action queuing in SQLite jobs_queue table
    - Add automatic retry logic with exponential backoff
    - Create background sync scheduling for mobile platforms
    - Implement sync conflict resolution UI
    - _Requirements: 6.3, 6.4, 7.3_

- [x] 13. Implement background services and job processing





  - [x] 13.1 Create background task orchestration


    - Implement BackgroundTaskService for isolate management
    - Add job queue processing with priority and scheduling
    - Create platform-specific background service integration
    - Implement proper lifecycle management and cleanup
    - _Requirements: 6.6, 10.4_

  - [x] 13.2 Build notification system


    - Add flutter_local_notifications for job completion alerts
    - Implement sync status and error notifications
    - Create scan progress and completion notifications
    - Add user preference management for notifications
    - _Requirements: 2.5, 6.5_

- [x] 14. Create authentication and onboarding UI





  - [x] 14.1 Build onboarding screens


    - Create welcome screen with app introduction
    - Implement OAuth2 sign-in screen with provider selection
    - Add webview integration for OAuth flow completion
    - Create loading states and error handling UI
    - _Requirements: 1.1, 1.2, 1.3_

  - [x] 14.2 Implement authentication flow


    - Create authentication state routing and navigation
    - Add automatic token refresh handling in UI
    - Implement logout confirmation and cleanup
    - Create session timeout and re-authentication prompts
    - _Requirements: 1.5, 1.6_

- [x] 15. Build library management UI





  - [x] 15.1 Create library list screen


    - Implement library list with cards showing counts and sync status
    - Add pull-to-refresh for library data updates
    - Create add library button with type selection dialog
    - Implement library settings and configuration UI
    - _Requirements: 2.1, 2.2, 2.6_

  - [x] 15.2 Build library configuration screens


    - Create local folder picker for desktop platforms
    - Implement cloud provider authentication flows
    - Add library scan progress UI with cancellation
    - Create library deletion confirmation dialog
    - _Requirements: 2.2, 2.3, 2.4, 2.5_

- [x] 16. Implement document browsing UI





  - [x] 16.1 Create folder browser screen


    - Implement tree/breadcrumb navigation for folder structure
    - Add lazy loading for folders with many children
    - Create multi-select mode for bulk operations
    - Implement folder and document context menus
    - _Requirements: 3.1, 3.2, 3.5, 3.6_

  - [x] 16.2 Build document list and grid views


    - Create document cards with thumbnails, metadata, and status
    - Implement list/grid view toggle with user preferences
    - Add sorting options (name, date, size, author)
    - Create document detail view with full metadata
    - _Requirements: 3.4, 3.5, 3.6_

- [x] 17. Build document reader UI





  - [x] 17.1 Create page viewer component


    - Implement page viewer with smooth scroll and paginated modes
    - Add zoom, rotate, and pan gestures for page interaction
    - Create page navigation controls and progress indicator
    - Implement page preloading and caching UI feedback
    - _Requirements: 4.1, 4.2, 4.6, 4.7_

  - [x] 17.2 Implement reader controls and features


    - Add text selection and find-in-document functionality
    - Create annotation toolbar for bookmarks, highlights, comments
    - Implement reading settings (brightness, theme, page mode)
    - Add reading progress saving and restoration
    - _Requirements: 4.2, 4.3, 4.7_

- [x] 18. Create annotation and bookmark UI





  - [x] 18.1 Build bookmark management


    - Create bookmark list screen with navigation to pages
    - Implement bookmark creation dialog with note input
    - Add bookmark editing and deletion functionality
    - Create bookmark sync status indicators
    - _Requirements: 4.3, 6.2, 6.4_

  - [x] 18.2 Implement comment system UI


    - Create comment overlay for page annotations
    - Implement comment creation with text selection anchoring
    - Add comment thread view with editing capabilities
    - Create comment sync and conflict resolution UI
    - _Requirements: 4.3, 6.2, 6.4_

- [x] 19. Build search interface





  - [x] 19.1 Create search screen


    - Implement search input with suggestions and history
    - Add search filters for library, tags, and content type
    - Create search results list with highlighting and snippets
    - Implement search result navigation to document pages
    - _Requirements: 5.1, 5.2, 5.4, 5.5_

  - [x] 19.2 Add advanced search features


    - Create saved search functionality
    - Implement search within document when viewing
    - Add search result export and sharing
    - Create search analytics and popular queries
    - _Requirements: 5.1, 5.2, 5.4_

- [x] 20. Implement tag management UI





  - [x] 20.1 Create tag management screen


    - Build tag list with usage statistics
    - Implement tag creation, editing, and deletion
    - Add tag color coding and organization
    - Create tag import/export functionality
    - _Requirements: 3.5, 6.2_

  - [x] 20.2 Build document tagging interface


    - Add tag selection dialog for documents
    - Implement tag autocomplete and suggestions
    - Create bulk tagging for multiple documents
    - Add tag-based filtering in document lists
    - _Requirements: 3.4, 3.5_

- [x] 21. Create sharing and collaboration UI





  - [x] 21.1 Build share management interface


    - Create share dialog with email input and permission selection
    - Implement share list with permission management
    - Add share link generation and copying
    - Create share revocation and expiration settings
    - _Requirements: 6.2, 6.4_

  - [x] 21.2 Implement collaborative viewing


    - Add shared document indicators in library views
    - Create permission-based UI restrictions
    - Implement shared annotation visibility toggles
    - Add collaboration activity feed
    - _Requirements: 6.2, 6.4_

- [x] 22. Build sync and offline management UI





  - [x] 22.1 Create sync status interface


    - Implement sync status indicators throughout the app
    - Add sync progress bars and completion notifications
    - Create offline mode indicators and limitations
    - Build sync conflict resolution dialogs
    - _Requirements: 6.1, 6.4, 6.5, 7.3_

  - [x] 22.2 Implement offline management


    - Create offline document availability indicators
    - Add download for offline access functionality
    - Implement offline storage management and cleanup
    - Create offline action queue status display
    - _Requirements: 7.1, 7.2, 7.3, 7.4_

- [x] 23. Add settings and preferences UI





  - [x] 23.1 Create app settings screen



    - Implement user preferences for UI, sync, and caching
    - Add storage management with cache size controls
    - Create notification preferences and scheduling
    - Implement theme selection and accessibility options
    - _Requirements: 7.4, 10.3, 10.5_

  - [x] 23.2 Build account and security settings


    - Create account information and profile management
    - Add security settings for token management
    - Implement data export and account deletion
    - Create privacy settings and data sharing controls
    - _Requirements: 9.1, 9.4, 9.5_

- [x] 24. Implement error handling and user feedback





  - [x] 24.1 Create global error handling UI


    - Implement error dialogs with contextual messages and actions
    - Add error reporting and feedback submission
    - Create network error handling with retry options
    - Implement graceful degradation for offline scenarios
    - _Requirements: 5.3, 7.3, 10.1, 10.2, 10.4_



  - [x] 24.2 Build user feedback systems











    - Add loading states and progress indicators throughout app
    - Implement success notifications and confirmations
    - Create help system with tutorials and documentation
    - Add user feedback collection and rating prompts
    - _Requirements: 10.1, 10.4_
-

- [x] 25. Fix compilation issues and model conflicts




  - [x] 25.1 Resolve model export conflicts


    - Fix DocumentViewMode conflict between app_settings.dart and document_view_settings.dart
    - Resolve connectivityServiceProvider conflict between search_provider.dart and library_provider.dart
    - Fix ThemeMode type conflicts between custom and Flutter ThemeMode
    - Add proper NotificationSettings class definition
    - _Requirements: 10.1, 10.4_

  - [x] 25.2 Complete missing provider integrations


    - Add missing providers to providers.dart export file
    - Integrate folder_browser_provider, reader_provider, bookmark_provider, comment_provider
    - Add sync_status_provider, share_provider, tag_provider to main exports
    - Ensure all providers are properly registered with Riverpod
    - _Requirements: 1.1, 2.1, 3.1, 4.1, 5.1, 6.1_

- [x] 26. Implement missing core functionality










  - [x] 26.1 Complete document detail and metadata editing


    - Create document detail view screen with full metadata display
    - Implement document metadata editing functionality
    - Add document rename and file management operations
    - Create document deletion with confirmation dialogs
    - _Requirements: 3.4, 3.5, 3.6_

  - [x] 26.2 Build native rendering integration


    - Complete FFI bindings setup for native document rendering
    - Implement platform-specific native library loading
    - Add fallback mechanisms for unsupported platforms
    - Create native rendering worker factory with proper error handling
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_
-

- [x] 27. Fix critical compilation issues








  - [x] 27.1 Implement performance monitoring



    - Add performance metrics collection for rendering and API calls
    - Implement memory usage monitoring and optimization
    - Create database query performance analysis
    - Add network request optimization and caching strategies
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

  - [x] 27.2 Resolve model and export conflicts


    - Fix ambiguous exports in models/api/api.dart (UpdateBookmarkRequest, UpdateCommentRequest)
    - Resolve CacheEntry conflict between cache_service.dart and network_cache_optimization_service.dart
    - Fix provider export conflicts (documentRepositoryProvider, pageRenderingServiceProvider, jobQueueServiceProvider)
    - Resolve model name conflicts (ReaderState, FolderBrowserState, TextSelectionAnchor, etc.)
    - Fix ThemeMode type conflicts and undefined class issues
    - _Requirements: 1.1, 2.1, 3.1, 4.1, 5.1, 6.1_

  - [x] 27.3 Complete missing implementations and dependencies


    - Add shared_preferences dependency to pubspec.yaml
    - Complete JSON serialization code generation (run build_runner)
    - Implement missing methods in ConnectivityService (hasConnectivity)
    - Complete SecureStorageService interface (read, write, deleteAll methods)
    - Fix NotificationService missing methods (showErrorNotification, showInfoNotification)
    - Resolve undefined provider references (secureStorageServiceProvider, currentUserProvider, etc.)
    - _Requirements: 1.4, 1.5, 6.1, 9.1, 10.1_

- [x] 28. Complete core functionality and testing





  - [x] 28.1 Fix service integration issues


    - Complete native rendering worker integration and error handling
    - Fix performance monitoring mixin implementation
    - Resolve sync service and job queue integration issues
    - Complete authentication and token management integration
    - Fix UI state management and provider integration issues
    - _Requirements: 1.1, 1.5, 6.1, 8.1, 8.2, 10.1_

  - [x] 28.2 Create comprehensive test suite


    - Write unit tests for all service classes and business logic
    - Implement widget tests for UI components and screens
    - Add integration tests for API communication and database operations
    - Create end-to-end tests for complete user workflows
    - _Requirements: All requirements validation_

- [x] 29. Fix critical compilation errors and complete integration







  - [x] 29.1 Resolve model and export conflicts


    - Fix ambiguous exports in models/api/api.dart (UpdateBookmarkRequest, UpdateCommentRequest)
    - Resolve CacheEntry conflict between cache_service.dart and network_cache_optimization_service.dart
    - Fix provider export conflicts (documentRepositoryProvider, pageRenderingServiceProvider, jobQueueServiceProvider)
    - Resolve model name conflicts (ReaderState, FolderBrowserState, TextSelectionAnchor, etc.)
    - Fix ThemeMode type conflicts and undefined class issues (NotificationSettings, DataSharingLevel)
    - _Requirements: 1.1, 2.1, 3.1, 4.1, 5.1, 6.1_

  - [x] 29.2 Complete missing implementations and dependencies




    - Fix undefined provider references (secureStorageServiceProvider, currentUserProvider, etc.)
    - Complete JSON serialization code generation (run build_runner)
    - Implement missing methods in ConnectivityService (hasConnectivity)
    - Complete SecureStorageService interface (read, write, deleteAll methods)
    - Fix NotificationService missing methods (showErrorNotification, showInfoNotification)
    - Resolve native rendering worker integration issues
    - _Requirements: 1.4, 1.5, 6.1, 9.1, 10.1_

  - [x] 29.3 Fix service integration and UI issues


    - Complete native rendering worker integration and error handling
    - Fix performance monitoring mixin implementation
    - Resolve sync service and job queue integration issues
    - Complete authentication and token management integration
    - Fix UI state management and provider integration issues
    - Resolve widget parameter conflicts and missing required arguments
    - _Requirements: 1.1, 1.5, 6.1, 8.1, 8.2, 10.1_

- [x] 30. Complete testing and validation




  - [x] 30.1 Fix test compilation errors


    - Resolve missing mock classes and test dependencies
    - Fix widget test parameter mismatches
    - Complete integration test setup
    - Fix provider test dependencies
    - _Requirements: All requirements validation_

  - [x] 30.2 Create comprehensive test coverage


    - Write unit tests for all service classes and business logic
    - Implement widget tests for UI components and screens
    - Add integration tests for API communication and database operations
    - Create end-to-end tests for complete user workflows
    - _Requirements: All requirements validation_

- [x] 31. Platform-specific optimizations and deployment





  - [x] 31.1 Optimize for desktop platforms


    - Implement desktop-specific UI patterns and window management
    - Add keyboard shortcuts and menu bar integration
    - Optimize file system access and native integrations
    - Create desktop installer and update mechanisms
    - _Requirements: 8.4, 10.4, 10.5_

  - [x] 31.2 Optimize for mobile platforms


    - Implement mobile-specific UI patterns and gestures
    - Add background app refresh and battery optimization
    - Optimize for different screen sizes and orientations
    - Create app store deployment and update handling
    - _Requirements: 6.6, 10.4, 10.5_
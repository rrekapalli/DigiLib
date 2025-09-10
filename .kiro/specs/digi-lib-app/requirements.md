# Requirements Document

## Introduction

The Digital Library App is a cross-platform Flutter application that provides users with a comprehensive digital library management and reading experience. The app serves as a client-side interface for browsing, organizing, and reading digital documents (PDF, EPUB, DOCX) across desktop (Windows, macOS, Linux) and mobile (Android, iOS) platforms. It integrates with a Java Spring Boot backend for synchronization, authentication, and cloud storage while providing robust offline capabilities through local caching and native rendering workers.

## Requirements

### Requirement 1

**User Story:** As a user, I want to authenticate securely with the application, so that I can access my personal digital library and sync my data across devices.

#### Acceptance Criteria

1. WHEN a user opens the app for the first time THEN the system SHALL display an onboarding screen with OAuth2 sign-in options
2. WHEN a user selects OAuth2 sign-in THEN the system SHALL open the backend OAuth flow in a webview or external browser
3. WHEN OAuth2 authentication succeeds THEN the system SHALL receive and store the access_token (JWT) and refresh_token securely
4. WHEN the refresh_token is received THEN the system SHALL store it in secure storage using platform-specific secure keystore
5. WHEN the access_token expires THEN the system SHALL automatically refresh it using the stored refresh_token
6. WHEN token refresh fails THEN the system SHALL prompt the user to re-authenticate

### Requirement 2

**User Story:** As a user, I want to manage multiple libraries from different sources, so that I can organize my documents from local storage, Google Drive, and OneDrive in one place.

#### Acceptance Criteria

1. WHEN a user accesses the Library List screen THEN the system SHALL display all configured libraries with document counts and sync status
2. WHEN a user selects "Add Library" THEN the system SHALL provide options for Local, Google Drive, and OneDrive sources
3. WHEN a user adds a local library THEN the system SHALL use file_picker to allow folder selection and validate access permissions
4. WHEN a user adds a cloud library THEN the system SHALL authenticate with the respective cloud provider and validate access
5. WHEN a user triggers "Rescan" THEN the system SHALL initiate a background scan job for the selected library
6. WHEN a library scan completes THEN the system SHALL update the document count and sync status indicators

### Requirement 3

**User Story:** As a user, I want to browse and navigate through my document collections efficiently, so that I can quickly find and access the documents I need.

#### Acceptance Criteria

1. WHEN a user enters a library THEN the system SHALL display a folder browser with tree or breadcrumb navigation
2. WHEN a folder contains many children THEN the system SHALL implement lazy loading to maintain performance
3. WHEN a user selects multiple documents THEN the system SHALL enable bulk operations (rename, tag, share, delete)
4. WHEN a user navigates to a document list THEN the system SHALL display document cards with thumbnail, title, author, tags, last-read status, and file size
5. WHEN a user performs a bulk operation THEN the system SHALL queue the actions for offline processing and sync when online
6. WHEN the user is offline THEN the system SHALL still allow browsing of cached document metadata

### Requirement 4

**User Story:** As a user, I want to read digital documents with a smooth and feature-rich reading experience, so that I can comfortably consume content with proper navigation and annotation capabilities.

#### Acceptance Criteria

1. WHEN a user opens a document THEN the system SHALL display a reader interface with page viewer supporting smooth scroll and paginated modes
2. WHEN a user interacts with the reader THEN the system SHALL provide zoom, rotate, text selection, and find-in-document functionality
3. WHEN a user creates annotations THEN the system SHALL support bookmarks, comments, and highlights that persist locally and sync to the backend
4. WHEN rendering a page THEN the system SHALL request rendered page images via native worker (FFI) or server-rendered tiles
5. WHEN displaying pages THEN the system SHALL render one page at a time and pre-render the next page in background
6. WHEN caching rendered content THEN the system SHALL store images as WebP format and maintain LRU cache policy
7. WHEN a user navigates between pages THEN the system SHALL provide smooth transitions and maintain reading position

### Requirement 5

**User Story:** As a user, I want to search through my document collection quickly and comprehensively, so that I can find specific content across all my documents.

#### Acceptance Criteria

1. WHEN a user performs a local search THEN the system SHALL use SQLite FTS5 for quick results from cached content
2. WHEN a user performs a global search THEN the system SHALL query the backend Postgres database for full corpus results
3. WHEN the backend search fails THEN the system SHALL fallback to local cache search results
4. WHEN search results are displayed THEN the system SHALL show document title, relevant text snippets, and page numbers
5. WHEN a user selects a search result THEN the system SHALL open the document at the relevant page with search terms highlighted

### Requirement 6

**User Story:** As a user, I want my reading progress, annotations, and library changes to sync across all my devices, so that I can seamlessly continue my work from any device.

#### Acceptance Criteria

1. WHEN the app starts THEN the system SHALL perform delta sync from server using `/api/sync/manifest?since=...` endpoint
2. WHEN a user makes changes offline THEN the system SHALL queue actions (bookmarks, comments, renames, tag changes) in local SQLite
3. WHEN the device comes online THEN the system SHALL push queued offline actions to the backend
4. WHEN sync conflicts occur THEN the system SHALL use last-write-wins for simple fields and append-only for comments
5. WHEN sync completes THEN the system SHALL update local cache with latest metadata and notify user of any conflicts
6. WHEN background sync runs THEN the system SHALL use appropriate background services (Android WorkManager, iOS background fetch)

### Requirement 7

**User Story:** As a user, I want the app to work efficiently offline with cached content, so that I can continue reading and browsing even without internet connectivity.

#### Acceptance Criteria

1. WHEN documents are accessed THEN the system SHALL cache metadata, thumbnails, and recently viewed pages in local SQLite database
2. WHEN the user is offline THEN the system SHALL provide access to cached documents and their metadata
3. WHEN offline actions are performed THEN the system SHALL store them in a jobs_queue table for later synchronization
4. WHEN cache storage reaches limits THEN the system SHALL implement LRU eviction policy to manage disk space
5. WHEN the app restarts offline THEN the system SHALL restore the user's last session state from local storage

### Requirement 8

**User Story:** As a user, I want the app to leverage native rendering capabilities for optimal performance, so that I can view documents quickly with high quality rendering.

#### Acceptance Criteria

1. WHEN rendering documents THEN the system SHALL use dart:ffi to call native dynamic library (Rust) for PDF/EPUB/DOCX processing
2. WHEN calling native functions THEN the system SHALL provide `render_page`, `extract_text`, and `get_page_count` methods
3. WHEN native rendering fails THEN the system SHALL fallback to server-side rendering via signed URLs
4. WHEN processing large documents THEN the system SHALL use memory-mapped files in native worker when available
5. WHEN rendering completes THEN the system SHALL cache results locally and notify UI thread without blocking

### Requirement 9

**User Story:** As a user, I want my sensitive data and authentication tokens to be stored securely, so that my personal information and library access remain protected.

#### Acceptance Criteria

1. WHEN storing authentication tokens THEN the system SHALL use flutter_secure_storage or platform-specific secure keystore
2. WHEN communicating with backend THEN the system SHALL validate server TLS certificates
3. WHEN passing file paths to native worker THEN the system SHALL sanitize paths to prevent traversal attacks
4. WHEN storing refresh tokens THEN the system SHALL avoid storing access tokens permanently on disk
5. WHEN handling sensitive operations THEN the system SHALL implement proper error handling without exposing sensitive information

### Requirement 10

**User Story:** As a user, I want the app to perform efficiently with smooth UI interactions, so that I can have a responsive experience even with large document collections.

#### Acceptance Criteria

1. WHEN uploading or downloading files THEN the system SHALL use streaming with range requests for large files
2. WHEN updating UI THEN the system SHALL batch updates to avoid jank and keep rendering minimal on UI thread
3. WHEN managing cache THEN the system SHALL limit cache size and implement LRU eviction policy
4. WHEN performing background tasks THEN the system SHALL use isolates or background services without blocking UI
5. WHEN loading large folders THEN the system SHALL implement pagination and lazy loading for optimal performance
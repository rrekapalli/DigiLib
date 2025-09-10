# Flutter UI App Specification — Digital Library App

## Purpose
This document describes the Flutter client-side specification for the Digital Library App.  
The Flutter app is responsible for UI, local caching, invoking native rendering workers (via FFI/platform channels), and calling the Java + Spring Boot backend APIs for sync, auth, and shared features.

## Platforms
- Desktop: Windows, macOS, Linux
- Mobile: Android, iOS

## Key Responsibilities
- Render library browsing UI and reader UI
- Manage local cache (SQLite + FTS5) for offline usage
- Communicate with backend APIs (Java Spring Boot) over HTTPS (JWT Bearer auth)
- Call native worker for PDF/EPUB/DOCX rendering and heavy parsing (FFI / platform channels)
- Background scans, thumbnail generation, and upload/download orchestration via isolates or background services

## Main Screens & Flows
1. **Onboarding / Auth**
   - Screen: Sign in via OAuth2 -> opens backend OAuth flow (webview or external browser)
   - After success: backend returns access_token (JWT) and refresh_token; store refresh_token in secure storage.

2. **Library List**
   - Shows configured libraries with counts and sync status
   - Buttons: Add Library (Local / Google Drive / OneDrive), Rescan, Settings

3. **Folder Browser**
   - Tree or breadcrumb navigation for local/cloud library
   - Lazy loading for folders with many children
   - Multi-select for bulk operations (rename, tag, share)

4. **Document List / Detail**
   - Document card: thumbnail, title, author, tags, last-read, size
   - Actions: Open, Share, Add Tag, Rename, Delete, Bookmark page

5. **Reader**
   - Page viewer with:
     - Smooth scroll / paginated mode
     - Zoom, rotate, text selection, find-in-document
     - Annotations: bookmarks, comments, highlights (persisted locally and synced)
   - Rendering strategy:
     - Request rendered page image via local worker (FFI) OR request signed URL to server-rendered tile (backend)
     - Always render one page at a time, pre-render next page in background
     - Cache rendered images on disk (WebP), maintain LRU cache

6. **Search**
   - Local search: uses SQLite FTS5 for quick results
   - Global search: queries backend (Postgres) for full corpus and aggregated results; fallbacks to local cache

7. **Sync & Offline**
   - Local SQLite holds recently used metadata, bookmarks, comments, tags and small thumbnails
   - Delta sync from server via `/api/sync/manifest?since=...`
   - Queue offline actions (bookmarks, comments, renames, tag changes) and push when online
   - Conflict handling: last-write-wins for simple fields; comments are append-only

## Data Storage (on device)
- SQLite (sqflite) with FTS5 virtual tables:
  - Tables: `documents`, `pages`, `tags`, `document_tags`, `bookmarks`, `comments`, `jobs_queue`
- Secure storage:
  - Use `flutter_secure_storage` or platform secure keystore to store refresh tokens and sensitive config
- Cache layout:
  - `cache/tiles/<doc_id>/<page_number>.webp`
  - `cache/thumbnails/<doc_id>.jpg`

## Backend API Integration (Java Spring Boot)
- Base URL: `https://api.example.com`
- Auth: JWT Bearer tokens in `Authorization: Bearer <token>`
- Important endpoints the UI calls:
  - `POST /auth/oauth2/{provider}` — complete OAuth2 exchange
  - `POST /auth/refresh` — refresh tokens
  - `GET /api/libraries` — list libraries
  - `POST /api/libraries` — create library
  - `POST /api/libraries/{id}/scan` — trigger scan
  - `GET /api/documents` — paginated listing
  - `GET /api/documents/{id}` — metadata
  - `POST /api/documents/{id}/render?page=..&dpi=..` — get signed URL to render or proxy stream
  - `GET /api/documents/{id}/pages/{pageNumber}/text` — page text
  - `GET /api/sync/manifest?since=...` — delta sync
  - `POST /api/progress` — update reading progress
  - Tags/Bookmarks/Comments endpoints as per OpenAPI

## Native Worker Integration (FFI / Platform Channels)
- Use `dart:ffi` to call a native dynamic library (Rust) for:
  - `render_page(file_path, page, dpi) -> bytes` OR `render_page_to_cache(file_path, page, dpi) -> cache_path`
  - `extract_text(file_path, page) -> text`
  - `get_page_count(file_path) -> int`
- Alternatively use platform channels if worker is a separate process/service:
  - `MethodChannel('digi_lib/worker')` with methods `renderPage`, `extractText`, `getPageCount`

## Packages & Plugins (recommended)
- `sqflite` / `drift` for SQLite
- `flutter_secure_storage` for tokens
- `http` or `dio` for network
- `file_picker` for local folder selection (desktop plugins)
- `path_provider` for cache and app folders
- `flutter_local_notifications` for job complete notifications
- `ffi` for native worker integration
- `flutter_riverpod` or `provider` for state management

## Background Tasks & Scheduling
- Desktop: spawn background isolate or local worker process; ensure process lifecycle management
- Mobile: use background services (Android WorkManager, iOS background fetch) for periodic sync and scanning
- Jobs architecture:
  - UI enqueues jobs into local `jobs_queue` (SQLite)
  - Worker picks up and processes; updates job status; notifies UI via events or polling `/api/jobs/{id}`

## Security Considerations
- Always validate server TLS certificate
- Store refresh tokens in secure storage; avoid storing access token on disk permanently
- Sanitize paths when passing to native worker to avoid path traversal or command injection

## Performance Tips
- Stream files when uploading/downloading (use range requests)
- Use memory-mapped files in native worker when available
- Limit cache size and evict using LRU policy
- Batch UI updates to avoid jank; keep rendering on UI thread minimal

## Example Project Structure
```
/flutter-app
  /lib
    /src
      /screens
      /widgets
      /services  # api_service, auth_service, sync_service
      /native    # ffi bindings
      /db        # sqlite migrations & adapters
  /android
  /ios
  /windows
  /linux
  /macos
  pubspec.yaml
```

## Developer Handoff Notes
- Provide the backend OpenAPI YAML to frontend team to generate API client stubs (or use simple HTTP helper)
- Define response payloads and error codes clearly; use consistent pagination and rate limiting headers
- Provide sample signed URL flow and token expiry policies to coordinate token refresh before long-running reads

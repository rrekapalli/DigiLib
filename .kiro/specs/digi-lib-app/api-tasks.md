# Spring Boot API Implementation Plan

## Overview
Implementation plan for Java 21 Spring Boot 3.5.5 backend API for Digital Library App with Microsoft Entra ID OAuth2 authentication, based on the OpenAPI specification.

## Prerequisites
- Java 21
- Spring Boot 3.5.5
- PostgreSQL 17+
- Microsoft Entra ID application registration

# Implementation Tasks

- [ ] 1. Set up Spring Boot project structure and dependencies
  - Create Spring Boot 3.5.5 project with Java 21
  - Add core dependencies: spring-boot-starter-web, spring-boot-starter-security, spring-boot-starter-data-jpa
  - Add PostgreSQL driver, Flyway migration, Spring Boot OAuth2 resource server
  - Configure Maven/Gradle build with proper Java 21 settings
  - Set up project package structure: controllers, services, repositories, models, config, security
  - _OpenAPI Endpoints: Foundation for all endpoints_

- [ ] 2. Configure database and migration setup
  - [ ] 2.1 Set up PostgreSQL connection and configuration
    - Configure application.yml with PostgreSQL connection properties
    - Add HikariCP connection pool configuration
    - Set up database connection validation and health checks
    - Configure JPA/Hibernate properties for PostgreSQL
    - _Database Schema: All tables_

  - [ ] 2.2 Implement Flyway database migrations
    - Create Flyway migration scripts from digi-lib-postgres-schema.sql
    - Add migration for creating extensions (pgcrypto, pg_trgm)
    - Implement table creation migrations with proper constraints and indexes
    - Add trigger creation for tsvector updates
    - Create initial data seeding migrations if needed
    - _Database Schema: users, libraries, documents, pages, tags, bookmarks, comments, shares, reading_progress_

- [ ] 3. Create JPA entity models
  - [ ] 3.1 Implement core entity classes
    - Create User entity with JPA annotations and UUID primary key
    - Implement Library entity with owner relationship and JSON config field
    - Create Document entity with library relationship and metadata fields
    - Add Page entity with document relationship and text content
    - _Database Schema: users, libraries, documents, pages_

  - [ ] 3.2 Create annotation and relationship entities
    - Implement Tag entity with owner relationship
    - Create DocumentTag junction entity for many-to-many relationship
    - Add Bookmark entity with user and document relationships
    - Implement Comment entity with anchor JSON field and relationships
    - Create Share entity with subject polymorphism and permission enum
    - Add ReadingProgress entity with composite primary key
    - _Database Schema: tags, document_tags, bookmarks, comments, shares, reading_progress_

- [ ] 4. Set up Microsoft Entra ID OAuth2 integration
  - [ ] 4.1 Configure OAuth2 resource server
    - Add spring-boot-starter-oauth2-resource-server dependency
    - Configure application.yml with Entra ID issuer URI and JWK set URI
    - Set up JWT decoder with proper validation
    - Configure CORS settings for frontend integration
    - _OpenAPI Endpoints: Security configuration for all protected endpoints_

  - [ ] 4.2 Implement custom JWT authentication
    - Create JwtAuthenticationConverter for extracting user claims
    - Implement UserPrincipal class for authenticated user context
    - Add JWT token validation and user extraction logic
    - Create authentication failure handlers and error responses
    - _OpenAPI Endpoints: /auth/oauth2/{provider}, /auth/refresh_

- [ ] 5. Implement authentication controllers and services
  - [ ] 5.1 Create authentication controller
    - Implement OAuth2Controller with POST /auth/oauth2/{provider} endpoint
    - Add token refresh endpoint POST /auth/refresh
    - Create user profile endpoint GET /api/users/me
    - Implement proper error handling and response formatting
    - _OpenAPI Endpoints: /auth/oauth2/{provider}, /auth/refresh, /api/users/me_

  - [ ] 5.2 Build authentication service layer
    - Create AuthService for handling OAuth2 token exchange
    - Implement token validation and user creation/update logic
    - Add refresh token management and storage
    - Create user profile service with Entra ID integration
    - _OpenAPI Endpoints: Authentication flow support_

- [ ] 6. Create repository layer with Spring Data JPA
  - [ ] 6.1 Implement core repositories
    - Create UserRepository with findByEmail and OAuth provider queries
    - Implement LibraryRepository with owner-based filtering
    - Add DocumentRepository with library filtering and search capabilities
    - Create PageRepository with document relationship queries
    - _Database Operations: CRUD operations for core entities_

  - [ ] 6.2 Build annotation and metadata repositories
    - Implement TagRepository with owner-based queries
    - Create BookmarkRepository with user and document filtering
    - Add CommentRepository with document and page filtering
    - Implement ShareRepository with owner and grantee queries
    - Create ReadingProgressRepository with composite key operations
    - _Database Operations: CRUD operations for annotation entities_

- [ ] 7. Implement library management services and controllers
  - [ ] 7.1 Create library service layer
    - Implement LibraryService with CRUD operations
    - Add library ownership validation and access control
    - Create library scanning job management
    - Implement library configuration validation for different types
    - _OpenAPI Endpoints: /api/libraries, /api/libraries/{libraryId}_

  - [ ] 7.2 Build library controller
    - Create LibraryController with GET /api/libraries endpoint
    - Implement POST /api/libraries for library creation
    - Add GET /api/libraries/{libraryId} for library details
    - Create DELETE /api/libraries/{libraryId} with ownership validation
    - Implement POST /api/libraries/{libraryId}/scan for scan job initiation
    - _OpenAPI Endpoints: /api/libraries/*, /api/libraries/{libraryId}/*_

- [ ] 8. Implement document management services and controllers
  - [ ] 8.1 Create document service layer
    - Implement DocumentService with paginated queries
    - Add document search functionality with PostgreSQL full-text search
    - Create document metadata update and validation logic
    - Implement document access control based on library ownership
    - _OpenAPI Endpoints: /api/documents, /api/documents/{documentId}_

  - [ ] 8.2 Build document controller
    - Create DocumentController with GET /api/documents endpoint
    - Implement pagination, filtering, and search query parameters
    - Add GET /api/documents/{documentId} for document details
    - Create PUT /api/documents/{documentId} for metadata updates
    - Implement DELETE /api/documents/{documentId} with proper cleanup
    - _OpenAPI Endpoints: /api/documents, /api/documents/{documentId}_

- [ ] 9. Implement page management and rendering services
  - [ ] 9.1 Create page service layer
    - Implement PageService for document page management
    - Add page text extraction and storage logic
    - Create thumbnail generation and storage service
    - Implement page rendering URL generation with signed URLs
    - _OpenAPI Endpoints: /api/documents/{documentId}/pages, /api/documents/{documentId}/render_

  - [ ] 9.2 Build page controller
    - Create PageController with GET /api/documents/{documentId}/pages
    - Implement GET /api/documents/{documentId}/pages/{pageNumber}
    - Add GET /api/documents/{documentId}/pages/{pageNumber}/text
    - Create POST /api/documents/{documentId}/render with signed URL generation
    - _OpenAPI Endpoints: /api/documents/{documentId}/pages/*, /api/documents/{documentId}/render_

- [ ] 10. Implement tag management system
  - [ ] 10.1 Create tag service layer
    - Implement TagService with CRUD operations and ownership validation
    - Add document tagging and untagging functionality
    - Create tag usage analytics and popular tag queries
    - Implement tag-based document filtering and search
    - _OpenAPI Endpoints: /api/tags, /api/documents/{documentId}/tags_

  - [ ] 10.2 Build tag controller
    - Create TagController with GET /api/tags and POST /api/tags
    - Implement DELETE /api/tags/{tagId} with usage validation
    - Add GET /api/documents/{documentId}/tags for document tags
    - Create POST /api/documents/{documentId}/tags for tag assignment
    - Implement DELETE /api/documents/{documentId}/tags/{tagId}
    - _OpenAPI Endpoints: /api/tags/*, /api/documents/{documentId}/tags/*_

- [ ] 11. Implement bookmark management system
  - [ ] 11.1 Create bookmark service layer
    - Implement BookmarkService with CRUD operations
    - Add bookmark validation and duplicate prevention
    - Create user-specific bookmark queries and filtering
    - Implement bookmark synchronization conflict resolution
    - _OpenAPI Endpoints: /api/documents/{documentId}/bookmarks, /api/bookmarks/{bookmarkId}_

  - [ ] 11.2 Build bookmark controller
    - Create BookmarkController with document-specific bookmark endpoints
    - Implement GET /api/documents/{documentId}/bookmarks
    - Add POST /api/documents/{documentId}/bookmarks for creation
    - Create PUT /api/bookmarks/{bookmarkId} for updates
    - Implement DELETE /api/bookmarks/{bookmarkId}
    - _OpenAPI Endpoints: /api/documents/{documentId}/bookmarks, /api/bookmarks/{bookmarkId}_

- [ ] 12. Implement comment system
  - [ ] 12.1 Create comment service layer
    - Implement CommentService with CRUD operations
    - Add comment anchor validation and positioning logic
    - Create page-specific comment queries and filtering
    - Implement comment threading and reply functionality
    - _OpenAPI Endpoints: /api/documents/{documentId}/comments, /api/comments/{commentId}_

  - [ ] 12.2 Build comment controller
    - Create CommentController with document and page filtering
    - Implement GET /api/documents/{documentId}/comments
    - Add POST /api/documents/{documentId}/comments for creation
    - Create PUT /api/comments/{commentId} for updates
    - Implement DELETE /api/comments/{commentId}
    - _OpenAPI Endpoints: /api/documents/{documentId}/comments, /api/comments/{commentId}_

- [ ] 13. Implement reading progress tracking
  - [ ] 13.1 Create reading progress service
    - Implement ReadingProgressService with upsert operations
    - Add progress validation and page number verification
    - Create user-specific progress queries and analytics
    - Implement cross-device progress synchronization
    - _OpenAPI Endpoints: /api/documents/{documentId}/progress_

  - [ ] 13.2 Build reading progress controller
    - Create ReadingProgressController for progress management
    - Implement GET /api/documents/{documentId}/progress
    - Add PUT /api/documents/{documentId}/progress for updates
    - Create batch progress update endpoints if needed
    - _OpenAPI Endpoints: /api/documents/{documentId}/progress_

- [ ] 14. Implement sharing and collaboration system
  - [ ] 14.1 Create share service layer
    - Implement ShareService with permission-based access control
    - Add share creation with email validation and notification
    - Create share permission validation and enforcement
    - Implement share expiration and revocation logic
    - _OpenAPI Endpoints: /api/shares, /api/shares/shared-with-me_

  - [ ] 14.2 Build share controller
    - Create ShareController with user-specific share management
    - Implement GET /api/shares for user's created shares
    - Add GET /api/shares/shared-with-me for received shares
    - Create POST /api/shares for share creation
    - Implement PUT /api/shares/{shareId} for permission updates
    - Add DELETE /api/shares/{shareId} for share revocation
    - _OpenAPI Endpoints: /api/shares/*, /api/shares/{shareId}_

- [ ] 15. Implement search functionality
  - [ ] 15.1 Create search service layer
    - Implement SearchService with PostgreSQL full-text search
    - Add search indexing for documents, pages, and metadata
    - Create search result ranking and relevance scoring
    - Implement search filters for library, tags, and content type
    - _OpenAPI Endpoints: /api/search_

  - [ ] 15.2 Build search controller
    - Create SearchController with comprehensive search capabilities
    - Implement GET /api/search with query parameters
    - Add search result highlighting and snippet generation
    - Create search analytics and popular query tracking
    - _OpenAPI Endpoints: /api/search_

- [ ] 16. Implement synchronization system
  - [ ] 16.1 Create sync service layer
    - Implement SyncService with delta synchronization logic
    - Add change tracking and manifest generation
    - Create conflict detection and resolution strategies
    - Implement sync checksum validation and integrity checks
    - _OpenAPI Endpoints: /api/sync/manifest, /api/sync/push_

  - [ ] 16.2 Build sync controller
    - Create SyncController for client synchronization
    - Implement GET /api/sync/manifest with timestamp filtering
    - Add POST /api/sync/push for client change submission
    - Create sync conflict resolution and response formatting
    - _OpenAPI Endpoints: /api/sync/manifest, /api/sync/push_

- [ ] 17. Implement file storage and rendering services
  - [ ] 17.1 Create file storage service
    - Implement FileStorageService for document file management
    - Add support for local, S3, Google Drive, and OneDrive storage
    - Create file upload, download, and streaming capabilities
    - Implement file integrity validation and virus scanning
    - _File Operations: Document storage and retrieval_

  - [ ] 17.2 Build document rendering service
    - Create DocumentRenderingService for PDF/EPUB/DOCX processing
    - Implement page rendering with configurable DPI and format
    - Add thumbnail generation and caching
    - Create signed URL generation for secure file access
    - _OpenAPI Endpoints: /api/documents/{documentId}/render_

- [ ] 18. Implement background job processing
  - [ ] 18.1 Create job processing framework
    - Implement JobService with Spring's @Async capabilities
    - Add job queue management with priority and scheduling
    - Create job status tracking and progress reporting
    - Implement job retry logic with exponential backoff
    - _Background Processing: Library scanning, file processing_

  - [ ] 18.2 Build library scanning jobs
    - Create LibraryScanJob for automated document discovery
    - Implement file system scanning with metadata extraction
    - Add cloud storage integration for remote libraries
    - Create scan progress reporting and completion notifications
    - _OpenAPI Endpoints: /api/libraries/{libraryId}/scan_

- [ ] 19. Implement security and access control
  - [ ] 19.1 Create security configuration
    - Implement SecurityConfig with method-level security
    - Add role-based access control for admin functions
    - Create resource-level permissions for documents and libraries
    - Implement rate limiting and request throttling
    - _Security: All protected endpoints_

  - [ ] 19.2 Build audit and logging system
    - Create AuditService for tracking user actions
    - Implement security event logging and monitoring
    - Add request/response logging with sensitive data filtering
    - Create security metrics and alerting
    - _Security: Audit trail for all operations_

- [ ] 20. Implement caching and performance optimization
  - [ ] 20.1 Create caching layer
    - Implement Redis caching for frequently accessed data
    - Add cache invalidation strategies for data consistency
    - Create cache warming for popular documents and searches
    - Implement cache metrics and monitoring
    - _Performance: Response time optimization_

  - [ ] 20.2 Optimize database queries and indexing
    - Add database query optimization and explain plan analysis
    - Implement proper indexing strategies for search and filtering
    - Create database connection pooling optimization
    - Add query performance monitoring and alerting
    - _Performance: Database optimization_

- [ ] 21. Implement API documentation and validation
  - [ ] 21.1 Set up OpenAPI documentation
    - Add springdoc-openapi dependency for automatic documentation
    - Configure OpenAPI documentation generation from code annotations
    - Implement API versioning and backward compatibility
    - Create comprehensive API documentation with examples
    - _Documentation: OpenAPI specification compliance_

  - [ ] 21.2 Add request/response validation
    - Implement Bean Validation (JSR-303) for request DTOs
    - Add custom validators for business logic constraints
    - Create comprehensive error handling and response formatting
    - Implement API rate limiting and abuse prevention
    - _Validation: All API endpoints_

- [ ] 22. Implement monitoring and health checks
  - [ ] 22.1 Create application monitoring
    - Add Spring Boot Actuator for health checks and metrics
    - Implement custom health indicators for database and external services
    - Create application metrics collection and reporting
    - Add distributed tracing with Spring Cloud Sleuth
    - _Monitoring: Application health and performance_

  - [ ] 22.2 Build logging and error tracking
    - Implement structured logging with Logback and JSON format
    - Add error tracking and exception monitoring
    - Create log aggregation and analysis setup
    - Implement alerting for critical errors and performance issues
    - _Monitoring: Error tracking and alerting_

- [ ] 23. Create integration tests and API testing
  - [ ] 23.1 Implement integration test suite
    - Create @SpringBootTest integration tests for all controllers
    - Add TestContainers for PostgreSQL integration testing
    - Implement test data fixtures and cleanup strategies
    - Create OAuth2 mock authentication for testing
    - _Testing: All API endpoints_

  - [ ] 23.2 Build performance and load testing
    - Create JMeter or Gatling performance test scripts
    - Implement load testing for high-traffic scenarios
    - Add database performance testing and optimization
    - Create continuous performance monitoring in CI/CD
    - _Testing: Performance validation_

- [ ] 24. Implement deployment and configuration management
  - [ ] 24.1 Create Docker containerization
    - Create Dockerfile with multi-stage build for production
    - Add docker-compose setup for local development
    - Implement container health checks and resource limits
    - Create container registry and deployment automation
    - _Deployment: Containerized application_

  - [ ] 24.2 Set up environment configuration
    - Implement Spring Profiles for different environments
    - Add externalized configuration with environment variables
    - Create secrets management for sensitive configuration
    - Implement configuration validation and startup checks
    - _Configuration: Environment-specific settings_

- [ ] 25. Create API client generation and SDK
  - [ ] 25.1 Generate client libraries
    - Use OpenAPI Generator to create client SDKs for multiple languages
    - Create Java client library for internal services
    - Generate TypeScript/JavaScript client for frontend integration
    - Add client library documentation and usage examples
    - _Client Generation: API client libraries_

  - [ ] 25.2 Build API testing tools
    - Create Postman collection for API testing
    - Implement automated API contract testing
    - Add API mocking capabilities for frontend development
    - Create API usage analytics and monitoring
    - _Testing: API contract validation_

- [ ] 26. Final integration and deployment preparation
  - [ ] 26.1 Complete end-to-end testing
    - Create comprehensive end-to-end test scenarios
    - Test OAuth2 integration with Microsoft Entra ID
    - Validate all API endpoints with real data scenarios
    - Perform security testing and vulnerability assessment
    - _Testing: Complete system validation_

  - [ ] 26.2 Prepare production deployment
    - Create production deployment scripts and documentation
    - Implement database migration strategies for production
    - Add monitoring and alerting setup for production
    - Create backup and disaster recovery procedures
    - _Deployment: Production readiness_
# Screens

This directory contains UI screens for the Digital Library App:

- Authentication and onboarding screens
- Library management screens
- Document browsing and reading screens
- Search and settings screens

## Structure

- `auth/` - Authentication and onboarding
  - `welcome_screen.dart` - Welcome screen with app introduction
  - `oauth_sign_in_screen.dart` - OAuth2 provider selection
  - `oauth_webview_screen.dart` - OAuth2 webview flow
  - `auth_loading_screen.dart` - Loading states during authentication
  - `auth_wrapper.dart` - Authentication state routing wrapper
- `library/` - Library management
- `document/` - Document browsing and details
- `reader/` - Document reading interface
- `search/` - Search functionality
- `settings/` - App settings and preferences

## Authentication Flow

The authentication flow is handled by the following components:

1. **AuthWrapper** - Main routing component that switches between authenticated and unauthenticated states
2. **WelcomeScreen** - Initial onboarding screen with app introduction
3. **OAuthSignInScreen** - Provider selection (Google, Microsoft, GitHub)
4. **OAuthWebViewScreen** - WebView-based OAuth2 flow completion
5. **AuthLoadingScreen** - Loading states during authentication processes
6. **SessionTimeoutHandler** - Handles session expiration and re-authentication prompts
7. **TokenRefreshService** - Automatic token refresh management
# Mobile — Flutter Admin App

A Flutter mobile client for the **Real** project backend.

## Features

| Screen | Description |
|---|---|
| Login | Phone + password auth with JWT |
| Dashboard | Stats overview (total, active, inactive users, roles) |
| Users | Full CRUD — create, edit, delete, toggle status |

## Project Structure

```
lib/
├── main.dart
├── router/
│   └── app_router.dart          # go_router with auth redirect
├── core/
│   ├── constants/
│   │   └── api_constants.dart   # Base URL + endpoint paths
│   └── network/
│       ├── dio_client.dart      # Dio + auto token refresh interceptor
│       └── api_exception.dart   # Unified error wrapper
└── features/
    ├── auth/
    │   ├── data/auth_repository.dart
    │   ├── models/admin_model.dart
    │   ├── providers/auth_provider.dart
    │   └── screens/login_screen.dart
    ├── dashboard/
    │   └── screens/dashboard_screen.dart
    └── users/
        ├── data/users_repository.dart
        ├── models/user_model.dart
        ├── providers/users_provider.dart
        ├── screens/users_screen.dart
        └── widgets/
            ├── user_tile.dart
            └── user_form_dialog.dart
```

## Setup

1. **Install Flutter** — https://docs.flutter.dev/get-started/install

2. **Set the backend URL** in `lib/core/constants/api_constants.dart`:
   ```dart
   static const String baseUrl = 'https://yonas-backend.onrender.com/api';

   // Physical device → use your machine's local IP e.g.
   // static const String baseUrl = 'http://192.168.1.x:5000/api';
   ```

3. **Get dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run**:
   ```bash
   flutter run
   ```

## State Management

- **Riverpod** (`flutter_riverpod`) — providers for auth and users
- **go_router** — declarative routing with auth redirect guard
- **Dio** — HTTP client with JWT interceptor (auto-refresh on 401)
- **flutter_secure_storage** — stores access & refresh tokens securely

# Jom Kuiz

A modern Malaysian education platform for parents and children, built with
Flutter (Dart).

> **Note on this workspace:** this Replit project cannot run the Flutter
> toolchain. This directory is generated Flutter source code only — open it
> in a real Flutter environment (Android Studio, VS Code + Flutter SDK, or
> `flutter` CLI) to build and run it.

## Status

Foundation (Prompt 01), Authentication module (Prompt 02), and Parent module
(Prompt 03) are implemented. No other feature logic (child module, quiz,
wallet, referral, payment, admin, analytics, AI, OCR, notifications) is
implemented yet.

## Stack

- **Framework:** Flutter (stable channel), Dart
- **Architecture:** Clean Architecture (presentation / domain / data / core)
- **State management:** Riverpod (`AsyncNotifier`, hand-written -- no
  `riverpod_generator` codegen, so this compiles without `build_runner`)
- **Routing:** go_router, with `RouteGuard` enforcing auth redirects based on
  session state
- **Networking:** Dio, REST-API-ready, with `AuthInterceptor` attaching the
  bearer access token to outgoing requests
- **Auth:** JWT + refresh-token, `AuthService` / `TokenManager` /
  `SessionManager` implemented for login, register, logout, forgot/reset
  password, and silent session refresh
- **Persistence:** `flutter_secure_storage` (tokens, via the `TokenStorage`
  abstraction), `shared_preferences` (settings) -- PostgreSQL is the target
  backend database, accessed only via the REST API, never directly from the
  app
- **Localization:** English + Bahasa Melayu, ARB-based (`lib/l10n`)

## Getting started (in a real Flutter environment)

```sh
flutter pub get
flutter create --platforms=android,ios,web .   # generates full platform projects
flutter run
```

## Project structure

```text
lib/
├── core/           # config, constants, DI, error handling, logger,
│                   # network client, routing, storage, theme, utils, validators
├── data/           # models (DTOs), datasources, services, repository impls
├── domain/         # entities, repository interfaces
├── presentation/   # controllers, providers, screens, reusable widgets
└── l10n/           # ARB translation source files
```

See each layer's `README.md` (under `data/`, `domain/`, `presentation/`) for
conventions on what belongs where.

## Authentication module (Prompt 02)

- **Screens:** Splash (session check + auto-redirect), Login (email,
  password, remember me), Register Parent (full name, email, password,
  confirm password, agree terms), Forgot Password, Reset Password.
- **Flow:** `AuthController` (Riverpod) drives form submission state;
  `AuthService` orchestrates `AuthRepository` (REST calls) + `TokenManager` /
  `SessionManager` (local session persistence); `SessionController` exposes
  `SessionStatus` to `RouteGuard`, which redirects between Login and
  Dashboard automatically.
- **API prepared (no backend logic):** `POST /auth/login`,
  `/auth/register`, `/auth/logout`, `/auth/refresh`,
  `/auth/forgot-password`, `/auth/reset-password`.
- **Error codes:** `AUTH-001` invalid credentials, `AUTH-002` email already
  exists, `AUTH-003` token expired, `AUTH-004` unauthorized, `AUTH-005`
  network error (see `core/error/auth_error_codes.dart`).
- **Not included:** Parent/Child/Education modules, Quiz, Wallet, Referral,
  Payment, Admin, Analytics, Notifications, AI, OCR.

## Parent module (Prompt 03)

- **Screens:** Parent Dashboard (welcome + profile cards, placeholder cards
  for Children/Subscription/Wallet/Referral/Latest Activity, quick actions),
  Edit Profile (full name, phone, country/state/city, gender, date of
  birth, language, bio, avatar upload placeholder; email is read-only),
  Security (change password + logout), Settings (language, dark mode
  placeholder, notifications, privacy placeholder, delete account).
- **Flow:** `ParentController` (Riverpod) loads/mutates the profile via
  `ParentService` -> `ParentRepository` -> `ParentRemoteDataSource` (REST).
  Deleting the account also clears the local session so `RouteGuard`
  redirects to Login.
- **API prepared (no backend logic):** `GET /parent/profile`,
  `PUT /parent/profile`, `PUT /parent/avatar`, `PUT /parent/password`,
  `PUT /parent/settings`, `DELETE /parent/account`.
- **Error codes:** `PARENT-001` profile not found, `PARENT-002` invalid
  phone number, `PARENT-003` profile update failed, `PARENT-004` avatar
  upload failed, `PARENT-005` password update failed (see
  `core/error/parent_error_codes.dart`).
- **Extension points:** `core/extension_points/module_placeholders.dart`
  lists the future modules (Children, Subscription, Wallet, Referral,
  Analytics, Subjects, Quiz, Leaderboard, Payment, Admin) the Dashboard
  reserves placeholder cards for -- no business logic for any of them yet.

## Scope (cumulative)

Included: project skeleton, Clean Architecture layers, theme (light + dark
placeholder), routing with guarded auth redirects, the Authentication and
Parent modules described above, localization structure (en/ms), reusable
widgets, logging, global error/exception handling.

Explicitly **not** included yet: child module, education/quiz module,
wallet, referral, payment, admin dashboard, analytics, AI, OCR,
notifications. These arrive in future prompts.

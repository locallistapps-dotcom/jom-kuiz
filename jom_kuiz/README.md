# Jom Kuiz

A modern Malaysian education platform for parents and children, built with
Flutter (Dart).

> **Note on this workspace:** this Replit project cannot run the Flutter
> toolchain. This directory is generated Flutter source code only — open it
> in a real Flutter environment (Android Studio, VS Code + Flutter SDK, or
> `flutter` CLI) to build and run it.

## Status

Foundation only (Prompt 01). No feature logic (login, quiz, wallet, etc.) is
implemented yet — see "Scope" below.

## Stack

- **Framework:** Flutter (stable channel), Dart
- **Architecture:** Clean Architecture (presentation / domain / data / core)
- **State management:** Riverpod
- **Routing:** go_router, with a `RouteGuard` hook prepared (not yet enforcing
  auth redirects)
- **Networking:** Dio, REST-API-ready, with an `AuthInterceptor` hook prepared
- **Auth:** JWT + refresh-token ready (`AuthService`, `TokenManager`,
  `SessionManager` are scaffolded, not implemented)
- **Persistence:** `flutter_secure_storage` (tokens), `shared_preferences`
  (settings) -- PostgreSQL is the target backend database, accessed only via
  the REST API, never directly from the app
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
│                   # network client, routing, theme, utils, validators
├── data/           # models (DTOs), datasources, services, repository impls
├── domain/         # entities, repository interfaces, use cases
├── presentation/   # controllers, providers, screens, reusable widgets
└── l10n/           # ARB translation source files
```

See `.local` conventions inline as doc comments in each layer's `README.md`
(under `data/`, `domain/`, `presentation/`) for what belongs where.

## Scope (this prompt)

Included: project skeleton, Clean Architecture layers, theme (light + dark
placeholder), routing with placeholder screens (Splash, Login, Register,
Dashboard, Settings, 404), auth scaffolding (no login logic), localization
structure (en/ms), reusable widgets, logging, global error/exception
handling.

Explicitly **not** included yet: login/register logic, parent module, child
module, education/quiz module, wallet, referral, payment, admin dashboard,
analytics, AI, OCR, notifications. These arrive in future prompts.

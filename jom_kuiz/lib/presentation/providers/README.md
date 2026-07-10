# Providers

Riverpod provider declarations that wire concrete implementations to their
abstract types for a given feature (data source -> repository -> use case ->
controller). Root/infrastructure providers (Dio, secure storage) live in
`core/di/providers.dart`; feature-specific providers belong here once those
features exist.

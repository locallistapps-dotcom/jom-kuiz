# Data sources

Lowest-level data access: remote (REST API calls via the shared `Dio`
instance from `core/network/api_client.dart`) and local (secure storage /
shared preferences / SQLite if added later).

Convention:

- `<name>_remote_data_source.dart` — talks to the API, throws `AppException`
  subtypes on failure.
- `<name>_local_data_source.dart` — talks to local storage/cache.

No data sources are implemented yet — this directory is prepared for future
feature modules.

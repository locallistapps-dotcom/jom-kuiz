/// Abstraction over connectivity checks so repositories can decide whether
/// to hit the network or fall back to cache without depending on a specific
/// connectivity package.
///
/// No implementation yet -- add a `connectivity_plus`-backed implementation
/// when offline support is implemented.
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

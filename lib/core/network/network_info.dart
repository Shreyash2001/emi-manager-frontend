import 'package:connectivity_plus/connectivity_plus.dart';

/// Checks device network connectivity.
///
/// Note: Connectivity does NOT guarantee the API is reachable.
/// Always handle API errors regardless of connectivity status.
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity;

  NetworkInfoImpl({required Connectivity connectivity})
      : _connectivity = connectivity;

  @override
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }
}

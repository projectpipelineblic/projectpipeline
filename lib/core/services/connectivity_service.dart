import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamController<bool> _connectivityController = StreamController<bool>.broadcast();

  Stream<bool> get connectivityStream => _connectivityController.stream;
  bool _isConnected = true;

  bool get isConnected => _isConnected;

  Future<void> initialize() async {
    // Check initial connectivity status
    final results = await _connectivity.checkConnectivity();
    _isConnected = results.isNotEmpty && results.first != ConnectivityResult.none;
    _connectivityController.add(_isConnected);

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _isConnected = results.isNotEmpty && results.first != ConnectivityResult.none;
      _connectivityController.add(_isConnected);
    });
  }

  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _isConnected = results.isNotEmpty && results.first != ConnectivityResult.none;
    return _isConnected;
  }

  void dispose() {
    _connectivityController.close();
  }
}

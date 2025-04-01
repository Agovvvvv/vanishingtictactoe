import 'dart:async';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';

class ConnectionManager {
  Timer? _connectionCheckTimer;
  DateTime? _lastUpdateTime;
  bool _isConnected = false;
  bool _shouldMonitor = true;
  
  final Function(bool isConnected)? onConnectionStatusChanged;
  final Function() onReconnectAttempt;
  
  ConnectionManager({
    required this.onConnectionStatusChanged,
    required this.onReconnectAttempt,
  });
  
  bool get isConnected => _isConnected;
  
  /// Set to false when the game has ended to prevent unnecessary reconnection attempts
  set shouldMonitor(bool value) {
    _shouldMonitor = value;
    if (!value && _connectionCheckTimer != null) {
      AppLogger.info('Stopping connection monitoring due to game end');
      _connectionCheckTimer?.cancel();
      _connectionCheckTimer = null;
    }
  }
  
  void startMonitoring() {
    _connectionCheckTimer?.cancel();
    _lastUpdateTime = DateTime.now();
    _isConnected = true;
    _shouldMonitor = true;
    onConnectionStatusChanged?.call(true);

    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      // Skip connection check if monitoring has been disabled
      if (!_shouldMonitor) {
        AppLogger.debug('Skipping connection check - monitoring disabled');
        return;
      }
      
      final timeSinceLastUpdate = DateTime.now().difference(_lastUpdateTime!);
      if (timeSinceLastUpdate.inSeconds > 15) {
        if (_isConnected) {
          _isConnected = false;
          onConnectionStatusChanged?.call(false);
          AppLogger.warning('Connection appears to be lost');
          // Only attempt reconnect if we should still be monitoring
          if (_shouldMonitor) {
            onReconnectAttempt();
          }
        }
      } else if (!_isConnected) {
        _isConnected = true;
        onConnectionStatusChanged?.call(true);
        AppLogger.info('Connection restored');
      }
    });
  }
  
  void updateLastActivityTime() {
    _lastUpdateTime = DateTime.now();
  }
  
  void dispose() {
    _shouldMonitor = false;
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = null;
    _isConnected = false;
    AppLogger.debug('ConnectionManager disposed');
  }
}
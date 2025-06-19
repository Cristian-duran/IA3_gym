import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'webrtc_optimizations.dart';

class PerformanceMonitor {
  Timer? _monitoringTimer;
  RTCPeerConnection? _peerConnection;
  Function(PerformanceMetrics)? onMetricsUpdate;
  
  PerformanceMetrics? _lastMetrics;
  bool _isMonitoring = false;

  void startMonitoring(RTCPeerConnection peerConnection) {
    _peerConnection = peerConnection;
    _isMonitoring = true;
    
    _monitoringTimer = Timer.periodic(
      Duration(seconds: WebRTCOptimizations.qualityCheckInterval),
      (timer) => _collectMetrics(timer),
    );
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _peerConnection = null;
  }

  Future<void> _collectMetrics(Timer timer) async {
    if (!_isMonitoring || _peerConnection == null) return;

    try {
      final stats = await _peerConnection!.getStats();
      final metrics = _parseStats(stats);
      
      if (metrics != null) {
        _lastMetrics = metrics;
        onMetricsUpdate?.call(metrics);
        
        // Tomar acciones automáticas basadas en métricas
        _handleMetrics(metrics);
      }
    } catch (e) {
      print('Error collecting performance metrics: $e');
    }
  }

  PerformanceMetrics? _parseStats(List<StatsReport> stats) {
    double frameRate = 0.0;
    int latency = 0;
    double packetLoss = 0.0;
    int bitrate = 0;

    for (final report in stats) {
      final values = report.values;
      
      // Buscar métricas de video inbound
      if (report.type == 'inbound-rtp' && values['mediaType'] == 'video') {
        frameRate = (values['framesPerSecond'] as num?)?.toDouble() ?? 0.0;
        bitrate = (values['bytesReceived'] as int?) ?? 0;
        packetLoss = (values['packetsLost'] as num?)?.toDouble() ?? 0.0;
      }
      
      // Buscar métricas de conexión
      if (report.type == 'candidate-pair' && values['state'] == 'succeeded') {
        latency = (values['currentRoundTripTime'] as num?)?.round() ?? 0;
      }
    }

    if (frameRate > 0 || latency > 0) {
      return PerformanceMetrics(
        frameRate: frameRate,
        latencyMs: latency,
        packetLoss: packetLoss,
        bitrate: bitrate,
        timestamp: DateTime.now(),
      );
    }

    return null;
  }

  void _handleMetrics(PerformanceMetrics metrics) {
    // Si la latencia es muy alta, podríamos reducir la calidad
    if (metrics.latencyMs > WebRTCOptimizations.maxLatencyMs) {
      print('High latency detected: ${metrics.latencyMs}ms');
    }

    // Si el frame rate es muy bajo, podríamos ajustar configuraciones
    if (metrics.frameRate < WebRTCOptimizations.minFrameRate) {
      print('Low frame rate detected: ${metrics.frameRate}fps');
    }

    // Si hay mucha pérdida de paquetes, podríamos reconectar
    if (metrics.packetLoss > 0.1) { // 10% de pérdida
      print('High packet loss detected: ${(metrics.packetLoss * 100).toStringAsFixed(1)}%');
    }
  }

  PerformanceMetrics? get lastMetrics => _lastMetrics;
  bool get isMonitoring => _isMonitoring;
}

class ConnectionManager {
  static const int maxReconnectAttempts = 3;
  static const Duration reconnectDelay = Duration(seconds: 3);
  
  int _reconnectAttempts = 0;
  bool _isReconnecting = false;
  Timer? _reconnectTimer;
  
  Function()? onReconnectStart;
  Function()? onReconnectSuccess;
  Function(String error)? onReconnectFailed;

  Future<void> attemptReconnect(Future<void> Function() reconnectFunction) async {
    if (_isReconnecting || _reconnectAttempts >= maxReconnectAttempts) {
      return;
    }

    _isReconnecting = true;
    _reconnectAttempts++;
    
    onReconnectStart?.call();
    
    try {
      await Future.delayed(reconnectDelay);
      await reconnectFunction();
      
      // Si llegamos aquí, la reconexión fue exitosa
      _reconnectAttempts = 0;
      _isReconnecting = false;
      onReconnectSuccess?.call();
      
    } catch (e) {
      _isReconnecting = false;
      
      if (_reconnectAttempts >= maxReconnectAttempts) {
        onReconnectFailed?.call('Max reconnect attempts reached: $e');
      } else {
        // Intentar de nuevo
        _reconnectTimer = Timer(Duration(seconds: 2), () {
          attemptReconnect(reconnectFunction);
        });
      }
    }
  }

  void reset() {
    _reconnectAttempts = 0;
    _isReconnecting = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void dispose() {
    reset();
  }

  bool get isReconnecting => _isReconnecting;
  int get reconnectAttempts => _reconnectAttempts;
}

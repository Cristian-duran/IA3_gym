// Optimizaciones para WebRTC en Flutter
// Configuraciones optimizadas para mejor rendimiento y menor latencia

class WebRTCOptimizations {
  // Configuración optimizada de video constraints
  static const Map<String, dynamic> optimizedVideoConstraints = {
    'audio': false,
    'video': {
      'facingMode': 'user',
      'width': 320,     // Reducido para menor ancho de banda
      'height': 240,    // Reducido para menor ancho de banda
      'frameRate': 15,  // Reducido para menos procesamiento
      'maxBitrate': 500000, // 500 kbps máximo
      'maxFramerate': 15,
    },
  };

  // Configuración optimizada de ICE servers
  static const Map<String, dynamic> optimizedRTCConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ],
    'iceCandidatePoolSize': 10,
    'bundlePolicy': 'max-bundle',
    'rtcpMuxPolicy': 'require',
  };

  // Configuración para offer optimizada
  static const Map<String, dynamic> optimizedOfferOptions = {
    'offerToReceiveAudio': false,
    'offerToReceiveVideo': true,
    'voiceActivityDetection': false,
  };

  // Intervalos para optimización
  static const int frameSkipInterval = 2;       // Procesar 1 de cada 2 frames
  static const int memoryCleanupInterval = 120; // Limpiar memoria cada 2 minutos (segundos)
  static const int qualityCheckInterval = 5;    // Verificar calidad cada 5 segundos
  
  // Umbrales de calidad
  static const int maxLatencyMs = 200;          // Latencia máxima aceptable
  static const double minFrameRate = 10.0;      // FPS mínimo aceptable
  static const int reconnectDelayMs = 3000;     // Delay antes de reconectar
}

// Enum para estados de conexión optimizados
enum OptimizedConnectionState {
  initializing,
  connecting,
  connected,
  reconnecting,
  disconnected,
  failed,
}

// Clase para métricas de rendimiento
class PerformanceMetrics {
  final double frameRate;
  final int latencyMs;
  final double packetLoss;
  final int bitrate;
  final DateTime timestamp;

  const PerformanceMetrics({
    required this.frameRate,
    required this.latencyMs,
    required this.packetLoss,
    required this.bitrate,
    required this.timestamp,
  });

  bool get isOptimal => 
      frameRate >= WebRTCOptimizations.minFrameRate &&
      latencyMs <= WebRTCOptimizations.maxLatencyMs &&
      packetLoss < 0.05; // Menos del 5% de pérdida de paquetes

  @override
  String toString() {
    return 'PerformanceMetrics(fps: $frameRate, latency: ${latencyMs}ms, loss: ${(packetLoss * 100).toStringAsFixed(1)}%, bitrate: ${bitrate}bps)';
  }
}

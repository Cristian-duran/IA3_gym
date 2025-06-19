class Constants {
  static const String baseUrl = 'http://192.168.33.36:8000';
  static const Duration httpTimeout = Duration(seconds: 30);
  
  // Configuraciones optimizadas para WebRTC
  static const String signalingUrl = 'ws://192.168.33.36:8000/signaling';
  
  // Configuraciones de rendimiento
  static const bool debugMode = false; // Cambiar a true para desarrollo
  static const int maxReconnectAttempts = 3;
  static const Duration reconnectDelay = Duration(seconds: 3);
  
  // Configuraciones de video optimizadas
  static const int optimizedWidth = 320;
  static const int optimizedHeight = 240;
  static const int optimizedFrameRate = 15;
  static const int maxBitrate = 500000; // 500 kbps
}
/// Configuraciones optimizadas para TTS en ejercicios de gimnasia
class TTSConfig {
  // Configuraciones de velocidad según el tipo de mensaje
  static const double errorSpeechRate = 0.7;      // Más lento para errores (mayor claridad)
  static const double correctionSpeechRate = 0.8; // Velocidad normal para correcciones
  static const double successSpeechRate = 1.0;    // Más rápido para éxitos (mantenimiento de energía)
  static const double defaultSpeechRate = 0.8;    // Velocidad por defecto
  
  // Configuraciones de volumen
  static const double volume = 1.0; // Volumen máximo para ambiente de gimnasio
  
  // Configuraciones de tono
  static const double errorPitch = 0.9;      // Tono ligeramente más bajo para errores
  static const double correctionPitch = 1.0; // Tono normal para correcciones
  static const double successPitch = 1.1;    // Tono ligeramente más alto para éxitos
  static const double defaultPitch = 1.0;    // Tono por defecto
  
  // Configuraciones de idioma
  static const String primaryLanguage = "es-ES";  // Español de España
  static const String fallbackLanguage = "es-MX"; // Español de México como respaldo
  
  // Límites de procesamiento de texto
  static const int maxMessageLength = 200;        // Máximo caracteres por mensaje
  static const int maxLinesDisplayed = 4;         // Máximo líneas mostradas en UI
  static const int maxWordsPerLine = 15;          // Máximo palabras por línea para TTS
  
  // Configuraciones de timing
  static const int pauseBetweenMessages = 500;    // Pausa entre mensajes (ms)
  static const int maxSpeakingDuration = 10000;   // Máximo tiempo de habla (ms)
  
  // Palabras clave para clasificación de mensajes
  static const List<String> errorKeywords = [
    'error', 'incorrecto', 'mal', 'fallo', 'equivocado', 'wrong'
  ];
  
  static const List<String> successKeywords = [
    'correcto', 'excelente', 'perfecto', 'bien', 'bueno', 'great', 'perfect'
  ];
  
  static const List<String> correctionKeywords = [
    'correccion', 'corrección', 'ajusta', 'mejora', 'modifica'
  ];
}

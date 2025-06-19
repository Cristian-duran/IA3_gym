import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  late FlutterTts _flutterTts;
  bool _isInitialized = false;
  bool _isSpeaking = false;

  /// Inicializa el servicio TTS con configuraciones optimizadas para ejercicio
  Future<void> initialize() async {
    if (_isInitialized) return;

    _flutterTts = FlutterTts();    try {      // Configuración para español con fallback
      try {
        await _flutterTts.setLanguage("es-ES");
      } catch (e) {
        await _flutterTts.setLanguage("es-MX");
      }
        // Configuración optimizada para ejercicio usando velocidad normal
      await _flutterTts.setSpeechRate(0.9); // Velocidad normal para todos los mensajes
      await _flutterTts.setVolume(1.0);     // Volumen máximo
      await _flutterTts.setPitch(1.0);      // Tono normal para todos
      
      // Configuraciones específicas de plataforma
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _flutterTts.setEngine("com.google.android.tts");
      }

      // Callbacks para monitorear estado
      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        if (kDebugMode) {
          print('[TTS] Error: $msg');
        }
      });

      _isInitialized = true;
      if (kDebugMode) {
        print('[TTS] Servicio inicializado correctamente');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[TTS] Error al inicializar: $e');
      }
    }
  }

  /// Habla un mensaje de feedback procesando el tipo automáticamente
  Future<void> speakFeedback(String message) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (message.isEmpty) return;

    // Detener cualquier reproducción anterior para mensajes urgentes
    if (_isSpeaking) {
      await stop();
    }

    // Procesar el mensaje para hacerlo más natural
    String processedMessage = _processFeedbackMessage(message);
    
    if (processedMessage.isNotEmpty) {
      await _speak(processedMessage);
    }
  }  /// Procesa el mensaje de feedback para hacer el audio más natural
  String _processFeedbackMessage(String message) {
    // Truncar mensaje si es muy largo (máximo 150 caracteres)
    if (message.length > 150) {
      message = message.substring(0, 150) + "...";
    }
    
    // Dividir en líneas y procesar cada una
    List<String> lines = message.split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) => line.trim())
        .toList();

    if (lines.isEmpty) return '';

    // Tomar solo las primeras 2 líneas más importantes
    List<String> processedLines = [];
    
    for (String line in lines.take(2)) {
      String processed = _cleanMessageText(line);
      if (processed.isNotEmpty) {
        processedLines.add(processed);
      }
    }

    return processedLines.join('. ');
  }

  /// Limpia el texto del mensaje para hacerlo más natural al audio
  String _cleanMessageText(String text) {
    // Remover prefijos técnicos y limpiar texto
    text = text
        .replaceAll(RegExp(r'^error:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^correccion:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^correcto:\s*', caseSensitive: false), 'Perfecto! ')
        .replaceAll(RegExp(r'^conf:\s*[\d.]+\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'_', caseSensitive: false), ' ')
        .trim();

    // Capitalizar primera letra
    if (text.isNotEmpty) {
      text = text[0].toUpperCase() + text.substring(1);
    }

    return text;
  }  /// Habla un mensaje específico de error (con mayor urgencia)
  Future<void> speakError(String errorMessage) async {
    await stop(); // Interrumpir cualquier mensaje anterior
    
    String processed = _cleanMessageText(errorMessage);
    if (processed.isNotEmpty) {
      await _speak('Atención! $processed');
    }
  }  /// Habla un mensaje de corrección
  Future<void> speakCorrection(String correctionMessage) async {
    String processed = _cleanMessageText(correctionMessage);
    if (processed.isNotEmpty) {
      await _speak(processed);
    }
  }

  /// Habla un mensaje de éxito
  Future<void> speakSuccess(String successMessage) async {
    String processed = _cleanMessageText(successMessage);
    if (processed.isNotEmpty) {
      await _speak('Excelente! $processed');
    }
  }

  /// Función interna para reproducir audio
  Future<void> _speak(String text) async {
    try {
      _isSpeaking = true;
      await _flutterTts.speak(text);
      
      if (kDebugMode) {
        print('[TTS] Reproduciendo: $text');
      }
    } catch (e) {
      _isSpeaking = false;
      if (kDebugMode) {
        print('[TTS] Error al reproducir: $e');
      }
    }
  }

  /// Detiene la reproducción actual
  Future<void> stop() async {
    if (_isInitialized && _isSpeaking) {
      await _flutterTts.stop();
      _isSpeaking = false;
    }
  }

  /// Pausa la reproducción
  Future<void> pause() async {
    if (_isInitialized && _isSpeaking) {
      await _flutterTts.pause();
    }
  }

  /// Ajusta la velocidad de habla (0.5 - 2.0)
  Future<void> setSpeechRate(double rate) async {
    if (_isInitialized) {
      await _flutterTts.setSpeechRate(rate.clamp(0.5, 2.0));
    }
  }

  /// Verifica si está hablando actualmente
  bool get isSpeaking => _isSpeaking;

  /// Verifica si está inicializado
  bool get isInitialized => _isInitialized;

  /// Libera recursos
  Future<void> dispose() async {
    if (_isInitialized) {
      await stop();
      _isInitialized = false;
    }
  }
}

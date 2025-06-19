import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'services/signaling_service.dart';
import 'services/tts_service.dart';
import 'screens/home_screen.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Corrector de Ejercicios',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(cameras: cameras),
    );
  }
}

class WebRTCService {
  final SignalingService signaling;
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  bool _hasRemoteStream = false;

  // NUEVO: Callback para notificar cuando llega el stream remoto
  Function()? onRemoteStream;
  
  // Optimizaciones de rendimiento
  bool _isActive = true;
  
  WebRTCService(this.signaling);

  bool get hasRemoteStream => _hasRemoteStream;
  Future<void> initRenderers() async {
    if (!_isActive) return;
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }  Future<void> startLocalStream() async {
    if (!_isActive) return;
    final Map<String, dynamic> mediaConstraints = {
      'audio': false,
      'video': {
        'facingMode': 'user',
        'width': 320,     // Reducido de 640 para menor ancho de banda
        'height': 240,    // Reducido de 480 para menor ancho de banda
        'frameRate': 15,  // Reducido de 30 para menos datos a procesar
        'maxBitrate': 500000, // 500 kbps máximo
        'maxFramerate': 15,
      },
    };
    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    localRenderer.srcObject = _localStream;
  }
  Future<void> initializePeerConnection() async {
    final Map<String, dynamic> config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},  // Servidor de respaldo
        {'urls': 'stun:stun2.l.google.com:19302'},  // Servidor adicional
      ],
      'iceCandidatePoolSize': 10,  // Pre-generar candidates para mejor conectividad
      'bundlePolicy': 'max-bundle',
      'rtcpMuxPolicy': 'require',
    };
    _peerConnection = await createPeerConnection(config);
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });
    }
    _peerConnection!.onTrack = (event) {
      if (event.track.kind == 'video') {
        remoteRenderer.srcObject = event.streams[0];
        _hasRemoteStream = true;
        if (onRemoteStream != null) onRemoteStream!(); // Notifica al widget para actualizar UI
      }
    };    _peerConnection!.onIceCandidate = (candidate) {
      signaling.send({
        'type': 'ice',
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };
    
    // Manejo optimizado de estados de conexión
    _peerConnection!.onConnectionState = (state) {
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          print('[WebRTC] Conexión establecida correctamente');
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          print('[WebRTC] Conexión desconectada');
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          print('[WebRTC] Conexión falló - intentando reconectar');
          break;
        default:
          break;
      }
    };
  }

  Future<void> createOffer() async {
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    signaling.send({'type': 'offer', 'sdp': offer.sdp});
  }

  Future<void> setRemoteDescription(String sdp, String type) async {
    final desc = RTCSessionDescription(sdp, type);
    await _peerConnection?.setRemoteDescription(desc);
  }

  Future<void> addIceCandidate(Map<String, dynamic> candidate) async {
    final ice = RTCIceCandidate(
      candidate['candidate'],
      candidate['sdpMid'],
      candidate['sdpMLineIndex'],
    );
    await _peerConnection?.addCandidate(ice);
  }
  Future<void> disposePeerConnection() async {
    _isActive = false;
    await _peerConnection?.close();
    _peerConnection = null;
    _hasRemoteStream = false;
    remoteRenderer.srcObject = null;
  }

  Future<void> dispose() async {
    _isActive = false;
    await localRenderer.dispose();
    await remoteRenderer.dispose();
    await _localStream?.dispose();
    await disposePeerConnection();
  }
}

class WebRTCPage extends StatefulWidget {
  final String exercise;
  const WebRTCPage({Key? key, required this.exercise}) : super(key: key);

  @override
  State<WebRTCPage> createState() => _WebRTCPageState();
}

class _WebRTCPageState extends State<WebRTCPage> {
  late SignalingService signaling;
  late WebRTCService webrtc;
  late TTSService tts;

  bool _isExerciseStarted = false;
  bool _isInitDone = false;
  late String _selectedExercise;@override
  void initState() {
    super.initState();
    _selectedExercise = widget.exercise;
    signaling = SignalingService(Constants.signalingUrl);
    webrtc = WebRTCService(signaling);
    tts = TTSService();
    
    // Inicializar TTS
    tts.initialize();
    
    // Notifica a Flutter cuando llega el stream remoto
    webrtc.onRemoteStream = () {
      if (mounted) setState(() {});
    };
    _initLocalPreview();
  }

  Future<void> _initLocalPreview() async {
    await webrtc.initRenderers();
    await webrtc.startLocalStream();
    setState(() {
      _isInitDone = true;
    });
  }

  Future<void> _startExercise() async {
    setState(() {
      _isExerciseStarted = true;
    });
    await webrtc.initializePeerConnection();
    signaling.connect();    signaling.onMessage = (data) async {
      if (data['type'] == 'answer') {
        await webrtc.setRemoteDescription(data['sdp'], 'answer');
      } else if (data['type'] == 'ice') {
        // Evitar agregar candidatos nulos o duplicados
        if (data['candidate'] != null) {
          await webrtc.addIceCandidate(data['candidate']);
        }      } else if (data['type'] == 'feedback') {
        String message = data['message'] ?? '';
        
        // Reproducir feedback por audio automáticamente
        if (message.isNotEmpty) {
          await _handleFeedbackAudio(message);
        }
      }
    };    await _createOfferWithExercise();
  }  /// Maneja el feedback por audio automáticamente según el tipo de mensaje
  Future<void> _handleFeedbackAudio(String message) async {
    if (!mounted || message.isEmpty) return;
    
    try {
      // Limpiar el mensaje: eliminar la línea "Conf: [número]"
      String cleanMessage = message;
      List<String> lines = message.split('\n');
      
      // Filtrar líneas que no contengan "Conf:"
      List<String> filteredLines = lines.where((line) => 
        !line.trim().toLowerCase().startsWith('conf:')).toList();
      
      // Reconstruir el mensaje sin la línea de confianza
      cleanMessage = filteredLines.join('\n').trim();
      
      if (cleanMessage.isEmpty) return;
      
      String lowerMessage = cleanMessage.toLowerCase();
      
      // Clasificación simple de mensajes
      if (lowerMessage.contains('error') || lowerMessage.contains('incorrecto') || lowerMessage.contains('mal')) {
        await tts.speakError(cleanMessage);
      } else if (lowerMessage.contains('correcto') || lowerMessage.contains('excelente') || lowerMessage.contains('perfecto') || lowerMessage.contains('bien')) {
        await tts.speakSuccess(cleanMessage);
      } else if (lowerMessage.contains('corrección') || lowerMessage.contains('correccion') || lowerMessage.contains('ajusta') || lowerMessage.contains('mejora')) {
        await tts.speakCorrection(cleanMessage);
      } else {
        // Para cualquier otro tipo de feedback
        await tts.speakFeedback(cleanMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        print('[TTS] Error al procesar feedback: $e');
      }
    }
  }

  Future<void> _createOfferWithExercise() async {
    final offer = await webrtc._peerConnection!.createOffer({
      'offerToReceiveAudio': false,
      'offerToReceiveVideo': true,
      'voiceActivityDetection': false, // Desactivar VAD para video
    });
    await webrtc._peerConnection!.setLocalDescription(offer);
    signaling.send({
      'type': 'offer',
      'sdp': offer.sdp,
      'exercise': _selectedExercise,
      'optimized': true, // Indicar que es optimizada
    });
  }  Future<void> _stopExercise() async {
    // Detener cualquier audio en reproducción
    await tts.stop();
    
    setState(() {
      _isExerciseStarted = false;
    });await webrtc.disposePeerConnection();
    signaling.close();
    // Reiniciar señalización y renderizadores para permitir nueva sesión sin recargar
    signaling = SignalingService(Constants.signalingUrl);
    webrtc = WebRTCService(signaling);
    webrtc.onRemoteStream = () {
      if (mounted) setState(() {});
    };
    await webrtc.initRenderers();
    await webrtc.startLocalStream();
  }
  @override
  void dispose() {
    // Liberar recursos del TTS
    tts.dispose();
    webrtc.dispose();
    signaling.close();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Correccion en tiempo real')),
      body: _isInitDone
          ? Stack(              children: [
                // Video principal (remoto si está disponible, local si no)
                Positioned.fill(
                  child: webrtc.hasRemoteStream
                      ? RTCVideoView(
                          webrtc.remoteRenderer,
                          mirror: false,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                          placeholderBuilder: (context) => Container(
                            color: Colors.black,
                            child: const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          ),
                        )
                      : RTCVideoView(
                          webrtc.localRenderer,
                          mirror: true,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,                        ),
                ),
                
                // Botones optimizados
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 24,
                  child: Center(
                    child: _isExerciseStarted
                        ? ElevatedButton.icon(
                            onPressed: _stopExercise,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.stop),
                            label: const Text('Detener Ejercicio'),
                          )
                        : ElevatedButton.icon(
                            onPressed: _startExercise,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Iniciar Ejercicio'),
                          ),
                  ),
                ),
              ],
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Inicializando cámara...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
    );
  }
}

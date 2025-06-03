import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:image/image.dart' as img;
import '../widgets/video_controls.dart';

class DeadliftCamera extends StatefulWidget {
  final List<CameraDescription> cameras;
  const DeadliftCamera({super.key, required this.cameras});

  @override
  State<DeadliftCamera> createState() => _DeadliftCameraState();
}

class _DeadliftCameraState extends State<DeadliftCamera> {
  late CameraController _camCtrl;
  late Future<void> _init;
  VideoPlayerController? _vpCtrl;
  bool _recording = false;
  WebSocketChannel? _ws;
  bool _streaming = false;
  Image? _realtimeImage;

  @override
  void initState() {
    super.initState();
    _camCtrl = CameraController(
      widget.cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _init = _camCtrl.initialize();
  }

  Future<void> _start() async {
    await _init;
    _ws = WebSocketChannel.connect(Uri.parse('ws://192.168.52.36:8000/ws/peso_muerto'));
    _streaming = true;
    setState(() => _recording = true);
    _camCtrl.startImageStream((CameraImage image) async {
      if (!_streaming) return;
      try {
        final jpeg = await _convertYUV420toJpeg(image);
        if (jpeg != null) {
          _ws?.sink.add(jpeg);
        }
      } catch (_) {}
    });
    _ws?.stream.listen((data) {
      if (!_streaming) return;
      setState(() {
        _realtimeImage = Image.memory(data as Uint8List);
      });
    });
  }

  Future<void> _stop() async {
    _streaming = false;
    await _camCtrl.stopImageStream();
    _ws?.sink.close();
    setState(() {
      _recording = false;
      _realtimeImage = null;
    });
  }

  // Conversión de CameraImage YUV420 a JPEG usando el paquete image (Dart puro)
  Future<Uint8List?> _convertYUV420toJpeg(CameraImage image) async {
    try {
      if (image.format.group != ImageFormatGroup.yuv420) return null;
      final width = image.width;
      final height = image.height;
      final uvRowStride = image.planes[1].bytesPerRow;
      final uvPixelStride = image.planes[1].bytesPerPixel!;
      final imgData = img.Image(width: width, height: height);
      final plane0 = image.planes[0].bytes;
      final plane1 = image.planes[1].bytes;
      final plane2 = image.planes[2].bytes;
      int yp = 0;
      for (int y = 0; y < height; y++) {
        int uvp = uvRowStride * (y >> 1);
        int u = 0, v = 0;
        for (int x = 0; x < width; x++) {
          final ypVal = plane0[yp];
          if ((x & 1) == 0) {
            v = plane2[uvp];
            u = plane1[uvp];
            uvp += uvPixelStride;
          }
          int r = (ypVal + 1.370705 * (v - 128)).round();
          int g = (ypVal - 0.337633 * (u - 128) - 0.698001 * (v - 128)).round();
          int b = (ypVal + 1.732446 * (u - 128)).round();
          imgData.setPixelRgba(x, y, r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255), 255);
          yp++;
        }
      }
      final jpeg = img.encodeJpg(imgData, quality: 80);
      return Uint8List.fromList(jpeg);
    } catch (e) {
      debugPrint('Error al convertir imagen: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _camCtrl.dispose();
    _vpCtrl?.dispose();
    _ws?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Peso Muerto')),
      body: FutureBuilder<void>(
        future: _init,
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return Stack(
            children: [
              _realtimeImage != null
                  ? Positioned.fill(child: _realtimeImage!)
                  : CameraPreview(_camCtrl),
              Align(
                alignment: Alignment.bottomCenter,
                child: VideoControls(
                  isRecording: _recording,
                  isSending: false,
                  onRecord: _start,
                  onStop: _stop,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

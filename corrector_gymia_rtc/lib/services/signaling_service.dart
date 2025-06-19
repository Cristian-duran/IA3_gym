import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class SignalingService {
  final String serverUrl;
  late WebSocketChannel _channel;
  Function(Map<String, dynamic>)? onMessage;

  SignalingService(this.serverUrl);

  void connect() {
    _channel = WebSocketChannel.connect(Uri.parse(serverUrl));
    _channel.stream.listen((message) {
      final data = jsonDecode(message);
      if (onMessage != null) onMessage!(data);
    });
  }

  void send(Map<String, dynamic> data) {
    _channel.sink.add(jsonEncode(data));
  }

  void close() {
    _channel.sink.close();
  }
}

import 'package:flutter/material.dart';

class VideoControls extends StatelessWidget {
  final bool isRecording;
  final bool isSending;
  final VoidCallback onRecord;
  final VoidCallback onStop;

  const VideoControls({
    super.key,
    required this.isRecording,
    required this.isSending,
    required this.onRecord,
    required this.onStop,
  });

  @override
  Widget build(BuildContext c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FloatingActionButton(
          onPressed: isRecording ? onStop : onRecord,
          backgroundColor: isRecording ? Colors.red : Colors.blue,
          child: Icon(isRecording ? Icons.stop : Icons.videocam),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'rules_popup.dart';
import 'squat_camera.dart';
import 'deadlift_camera.dart';

class HomeScreen extends StatelessWidget {
  final List<CameraDescription> cameras;
  const HomeScreen({super.key, required this.cameras});

  static const List<String> squatRules = [
    'Mantén la espalda recta',
    'Rodillas alineadas con pies',
    'Descenso lento y controlado',
  ];
  static const List<String> deadliftRules = [
    'Espalda neutra en todo momento',
    'Hombros encima de la barra',
    'Empuje con piernas y caderas',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Corrector de Ejercicios')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text('Sentadilla'),
              onPressed: () async {
                final navigator = Navigator.of(context);
                await RulesPopup.show(context, squatRules);
                navigator.push(
                  MaterialPageRoute(
                    builder: (_) => SquatCamera(cameras: cameras),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Peso Muerto'),
              onPressed: () async {
                final navigator = Navigator.of(context);
                await RulesPopup.show(context, deadliftRules);
                navigator.push(
                  MaterialPageRoute(
                    builder: (_) => DeadliftCamera(cameras: cameras),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

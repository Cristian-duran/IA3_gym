import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'rules_popup.dart';
import '../main.dart';

class HomeScreen extends StatelessWidget {
  final List<CameraDescription> cameras;
  const HomeScreen({super.key, required this.cameras});

  static const List<String> squatRules = [
    'Angulos de uso (frontal y lateral izquierdo)',
    'Mantén la espalda recta',
    'Rodillas y pies a la altura de los hombros',
    'Descenso lento y controlado',
  ];
  static const List<String> deadliftRules = [
    'Angulo de uso (lateral izquierdo)',
    'Espalda neutra en todo momento',
    'Cabeza mirando hacia adelante',
    'Empuje con piernas y caderas',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 66, 170, 255),
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
                    builder: (_) => WebRTCPage(exercise: 'sentadilla'),
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
                    builder: (_) => WebRTCPage(exercise: 'peso_muerto'),
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

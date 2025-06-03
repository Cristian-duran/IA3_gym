import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:corrector_gymia/main.dart';

class TestWidgetsBindingWithCameras {
  static Future<List<CameraDescription>> getCameras() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    return await availableCameras();
  }
}

void main() {
  testWidgets('HomeScreen tiene dos botones', (tester) async {
    final cameras = await TestWidgetsBindingWithCameras.getCameras();
    await tester.pumpWidget(MyApp(cameras: cameras));
    expect(find.text('Sentadilla'), findsOneWidget);
    expect(find.text('Peso Muerto'), findsOneWidget);
  });
}

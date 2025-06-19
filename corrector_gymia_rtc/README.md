# 🏋️ Corrector Gym IA - Cliente Flutter

## Características Principales

- ✅ **Corrección en tiempo real** de ejercicios de gimnasio
- ✅ **Feedback por audio TTS** en español (sin distracciones visuales)
- ✅ **WebRTC** para streaming de video en tiempo real
- ✅ **Análisis de pose** con YOLO y modelos LSTM
- ✅ **Interfaz minimalista** solo con video y controles básicos
- ✅ **Ejercicios soportados**: Sentadilla y Peso Muerto

## Requisitos Previos

### Sistema Operativo
- **Windows**: 10 o superior
- **macOS**: 10.14 o superior  
- **Linux**: Ubuntu 18.04 o superior

### Software Necesario
1. **Flutter SDK** 3.29.3 o superior
2. **Dart SDK** (incluido con Flutter)
3. **Android Studio** 2024.3 o superior
4. **VS Code** (opcional pero recomendado)
5. **Git** para clonar el repositorio

### Dispositivos
- **Android**: API level 21 (Android 5.0) o superior
- **iOS**: iOS 12.0 o superior

## Instalación Paso a Paso

### 1. Clonar el Repositorio

```bash
https://github.com/Cristian-duran/IA3_gym
cd corrector_gymia_rtc
```

### 2. Verificar Instalación de Flutter

```bash
flutter doctor
```

**Asegúrate de que todos los componentes estén marcados con ✓**

### 3. Configurar Android (si vas a usar Android)

1. **Instalar Android Studio**
2. **Configurar Android SDK**:
   ```bash
   flutter config --android-studio-dir="C:\Program Files\Android\Android Studio"
   ```
3. **Aceptar licencias**:
   ```bash
   flutter doctor --android-licenses
   ```

### 4. Instalar Dependencias del Proyecto

```bash
# Navegar al directorio del proyecto
cd corrector_gymia_rtc

# Limpiar dependencias previas (opcional)
flutter clean

# Instalar todas las dependencias
flutter pub get
```

### 5. Verificar Dependencias Instaladas

El archivo `pubspec.yaml` debe contener estas dependencias:

```yaml
dependencies:
  flutter:
    sdk: flutter
  camera: ^0.11.1                    # Acceso a cámara del dispositivo
  video_player: ^2.6.0               # Reproductor de video
  http: ^1.4.0                       # Peticiones HTTP
  http_parser: ^4.0.2                # Parser de HTTP
  web_socket_channel: ^3.0.3         # WebSocket para señalización
  flutter_webrtc: ^0.14.1            # WebRTC para streaming
  flutter_tts: ^4.1.0                # Text-to-Speech
  image: ^4.1.7                      # Procesamiento de imágenes
  cupertino_icons: ^1.0.8            # Iconos iOS

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0              # Linting para código limpio
```

### 6. Configuración de Permisos

#### Android (`android/app/src/main/AndroidManifest.xml`)

Añadir estos permisos antes de `<application>`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

#### iOS (`ios/Runner/Info.plist`)

Añadir estas claves antes de `</dict>`:

```xml
<key>NSCameraUsageDescription</key>
<string>Esta app necesita acceso a la cámara para analizar ejercicios</string>
<key>NSMicrophoneUsageDescription</key>
<string>Esta app necesita acceso al micrófono para WebRTC</string>
```

### 7. Configurar Constantes del Servidor

Editar `lib/utils/constants.dart`:

```dart
class Constants {
  static const String signalingUrl = 'ws://TU_SERVIDOR_IP:8000/signaling';
  // Ejemplo: 'ws://192.168.1.100:8000/signaling'
  // Ejemplo: 'ws://localhost:8000/signaling' (para desarrollo local)
}
```

### 8. Verificar Configuración

```bash
# Verificar que no hay errores de configuración
flutter analyze

# Verificar dependencias específicas
flutter pub deps
```

## Ejecución de la Aplicación

### 1. Conectar Dispositivo o Iniciar Emulador

#### Para Android:
```bash
# Listar dispositivos disponibles
flutter devices

# Iniciar emulador (si tienes uno configurado)
flutter emulators
flutter emulators --launch EMULATOR_NAME
```

#### Para iOS (solo en macOS):
```bash
# Abrir simulador
open -a Simulator
```

### 2. Ejecutar la Aplicación

#### Modo Debug (Desarrollo):
```bash
flutter run
```

#### Modo Release (Producción):
```bash
flutter run --release
```

#### Especificar dispositivo:
```bash
flutter run -d DEVICE_ID
```

### 3. Hot Reload Durante Desarrollo

Una vez que la app está corriendo:
- **Presiona `r`** para hot reload
- **Presiona `R`** para hot restart
- **Presiona `q`** para salir

## Configuración del Sistema TTS

### Características del TTS Implementado

#### Audio Automático:
- ✅ Los mensajes se reproducen automáticamente
- ✅ Clasificación por tipo: errores, correcciones, éxitos
- ✅ Velocidad optimizada (0.9x) para ejercicio
- ✅ Volumen máximo para ambiente de gimnasio

#### Tipos de Mensajes:

1. **Errores** (`error`, `incorrecto`, `mal`):
   - Prefijo: "Atención! [mensaje]"
   - Interrumpe mensajes anteriores

2. **Éxitos** (`correcto`, `excelente`, `perfecto`, `bien`):
   - Prefijo: "Excelente! [mensaje]"

3. **Correcciones** (`corrección`, `ajusta`, `mejora`):
   - Mensaje directo sin prefijo

#### Configuración Técnica:
- **Idioma**: Español España (`es-ES`) con fallback a México (`es-MX`)
- **Velocidad**: 0.9x (optimizada para ejercicio)
- **Volumen**: 1.0 (máximo)
- **Límite**: 150 caracteres por mensaje

## Manual de Uso

### Inicio del Ejercicio:
1. **Abrir la aplicación**
2. **Seleccionar ejercicio** (Sentadilla o Peso Muerto)
3. **Leer las reglas** del ejercicio mostradas
4. **Presionar "Iniciar Ejercicio"**
   - El TTS se inicializa automáticamente
   - La cámara se activa
   - Sistema listo para feedback

### Durante el Ejercicio:
- ✅ **Audio automático**: Cada mensaje se reproduce inmediatamente
- ✅ **Sin intervención**: No tocar la pantalla
- ✅ **Solo escuchar**: Concentrarse en las instrucciones de audio
- ✅ **Continuar ejercitando**: El sistema trabaja en segundo plano

### Finalizar:
1. **Presionar "Detener Ejercicio"**
   - Audio se detiene inmediatamente
   - Sesión termina
   - Recursos se liberan automáticamente

## Estructura del Proyecto

```
lib/
├── main.dart                    # Punto de entrada y WebRTC
├── screens/
│   ├── home_screen.dart        # Pantalla principal con botones
│   └── rules_popup.dart        # Popup con reglas de ejercicios
├── services/
│   ├── api_service.dart        # Servicios de API
│   ├── signaling_service.dart  # Señalización WebSocket
│   └── tts_service.dart        # Servicio Text-to-Speech
├── utils/
│   ├── constants.dart          # Constantes (URL del servidor)
│   ├── performance_monitor.dart # Monitor de rendimiento
│   └── tts_config.dart         # Configuración TTS
└── widgets/                    # Widgets reutilizables
```

## Comandos de Build

### Android APK:
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# APK ubicación: build/app/outputs/flutter-apk/
```

### Android App Bundle (para Google Play):
```bash
flutter build appbundle --release
```

### iOS (solo en macOS):
```bash
flutter build ios --release
```

## Solución de Problemas Comunes

### Error: "Gradle build failed"
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Error: "CocoaPods not installed" (iOS)
```bash
sudo gem install cocoapods
cd ios
pod install
cd ..
flutter run
```

### Error: "WebRTC permission denied"
- Verificar permisos en `AndroidManifest.xml` e `Info.plist`
- Reiniciar la aplicación
- Aceptar permisos cuando la app los solicite

### Error: "TTS not working"
- Verificar que el dispositivo tenga motor TTS instalado
- En Android: Configuración > Idioma > Text-to-Speech
- Verificar conectividad de red para feedback del servidor

### Error: "Cannot connect to server"
- Verificar URL en `lib/utils/constants.dart`
- Verificar que el servidor esté corriendo
- Verificar conectividad de red
- Usar IP local en lugar de localhost para dispositivos físicos

## Dependencias Principales

| Paquete | Versión | Propósito |
|---------|---------|-----------|
| `flutter_webrtc` | ^0.14.1 | Streaming de video WebRTC |
| `flutter_tts` | ^4.1.0 | Text-to-Speech |
| `camera` | ^0.11.1 | Acceso a cámara |
| `web_socket_channel` | ^3.0.3 | Comunicación WebSocket |
| `http` | ^1.4.0 | Peticiones HTTP |

## Flujo de la Aplicación

1. **Usuario selecciona ejercicio** → Muestra reglas
2. **Usuario inicia ejercicio** → Inicializa TTS y WebRTC
3. **Cámara envía video** → Servidor analiza con IA
4. **Servidor detecta errores/aciertos** → Envía feedback por WebSocket
5. **Cliente recibe feedback** → TTS reproduce audio automáticamente
6. **Usuario escucha correcciones** → Continúa ejercitando
7. **Usuario detiene ejercicio** → Limpia recursos y vuelve al inicio

## Características de la Interfaz

### Pantalla Principal:
- ✅ Fondo azul personalizable
- ✅ Botones para "Sentadilla" y "Peso Muerto"
- ✅ Popup con reglas antes de iniciar

### Pantalla de Ejercicio:
- ✅ Video en pantalla completa (local/remoto)
- ✅ Solo botón "Detener Ejercicio"
- ✅ Sin elementos visuales de feedback (solo audio)
- ✅ Interfaz limpia y minimalista

## Soporte

Si encuentras problemas:

1. **Verifica la configuración** siguiendo este README
2. **Revisa los logs** con `flutter logs`
3. **Limpia el proyecto** con `flutter clean && flutter pub get`
4. **Verifica conectividad** del servidor
5. **Consulta la documentación** de Flutter WebRTC

## Resultado Final

Una aplicación móvil completamente funcional que:
- ✅ **Analiza ejercicios** en tiempo real con IA
- ✅ **Proporciona feedback** exclusivamente por audio TTS
- ✅ **Interfaz minimalista** sin distracciones
- ✅ **Audio optimizado** para ambiente de gimnasio
- ✅ **Fácil de usar** con un solo botón de control

#!/bin/bash
# Script de optimización para GymIA WebRTC Server
# Uso: ./optimize_server.sh [mode]
# Modos: development, production, debug

MODE=${1:-production}

echo "🚀 Configurando optimizaciones para modo: $MODE"

# Crear directorio de configuración si no existe
mkdir -p config

# Configurar variables de entorno según el modo
case $MODE in
  "development")
    cat > config/optimization.env << EOF
DEBUG_MODE=true
DETECTION_INTERVAL=2
PREDICTION_INTERVAL=3
GYMIA_EXERCISE=peso_muerto
MAX_WORKERS=2
CACHE_DURATION=0.05
TARGET_FPS=30
ENABLE_BATCH_PROCESSING=false
EOF
    echo "✅ Configuración para desarrollo aplicada"
    ;;
    
  "production")
    cat > config/optimization.env << EOF
DEBUG_MODE=false
DETECTION_INTERVAL=3
PREDICTION_INTERVAL=5
GYMIA_EXERCISE=peso_muerto
MAX_WORKERS=2
CACHE_DURATION=0.1
TARGET_FPS=20
ENABLE_BATCH_PROCESSING=false
EOF
    echo "✅ Configuración para producción aplicada"
    ;;
    
  "debug")
    cat > config/optimization.env << EOF
DEBUG_MODE=true
DETECTION_INTERVAL=1
PREDICTION_INTERVAL=1
GYMIA_EXERCISE=peso_muerto
MAX_WORKERS=1
CACHE_DURATION=0
TARGET_FPS=30
ENABLE_BATCH_PROCESSING=false
EOF
    echo "✅ Configuración para debug aplicada"
    ;;
    
  "high-performance")
    cat > config/optimization.env << EOF
DEBUG_MODE=false
DETECTION_INTERVAL=4
PREDICTION_INTERVAL=8
GYMIA_EXERCISE=peso_muerto
MAX_WORKERS=3
CACHE_DURATION=0.15
TARGET_FPS=15
ENABLE_BATCH_PROCESSING=false
EOF
    echo "✅ Configuración de alto rendimiento aplicada"
    ;;
    
  *)
    echo "❌ Modo no reconocido. Modos disponibles: development, production, debug, high-performance"
    exit 1
    ;;
esac

# Crear script de inicio optimizado
cat > start_optimized.sh << 'EOF'
#!/bin/bash
echo "🚀 Iniciando GymIA Server Optimizado..."

# Cargar configuración
if [ -f config/optimization.env ]; then
    export $(cat config/optimization.env | xargs)
    echo "✅ Configuración de optimización cargada"
fi

# Verificar dependencias
echo "📦 Verificando dependencias..."
python -c "import ultralytics, tensorflow, fastapi, aiortc" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Todas las dependencias están instaladas"
else
    echo "❌ Faltan dependencias. Ejecutando: pip install -r requirements.txt"
    pip install -r requirements.txt
fi

# Iniciar servidor optimizado
echo "🎯 Iniciando servidor con optimizaciones..."
if [ "$DEBUG_MODE" = "true" ]; then
    echo "🐛 Modo debug activado"
    python -m app.webrtc_server_optimized
else
    echo "🚀 Modo producción activado"
    python -m app.webrtc_server_optimized > logs/server.log 2>&1
fi
EOF

chmod +x start_optimized.sh

# Crear directorio de logs si no existe
mkdir -p logs

# Crear script de monitoreo
cat > monitor_performance.sh << 'EOF'
#!/bin/bash
echo "📊 Monitor de rendimiento GymIA"
echo "Presiona Ctrl+C para salir"

while true; do
    clear
    echo "=== MONITOR DE RENDIMIENTO GYMIA ==="
    echo "Hora: $(date)"
    echo ""
    
    # CPU y memoria del proceso Python
    if pgrep -f "webrtc_server" > /dev/null; then
        echo "🟢 Servidor activo"
        ps -p $(pgrep -f "webrtc_server") -o pid,ppid,%cpu,%mem,cmd --no-headers
    else
        echo "🔴 Servidor no está ejecutándose"
    fi
    
    echo ""
    echo "=== RECURSOS DEL SISTEMA ==="
    echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
    echo "RAM: $(free | grep Mem | awk '{printf "%.1f%%", $3/$2 * 100.0}')"
    echo "Disco: $(df -h / | awk 'NR==2{printf "%s", $5}')"
    
    echo ""
    echo "=== CONEXIONES DE RED ==="
    netstat -an | grep :8000 | wc -l | xargs echo "Conexiones WebSocket:"
    
    sleep 2
done
EOF

chmod +x monitor_performance.sh

# Crear archivo de benchmark
cat > benchmark.py << 'EOF'
#!/usr/bin/env python3
"""
Benchmark para medir el rendimiento de las optimizaciones
"""
import time
import statistics
import asyncio
import cv2
import numpy as np
from app.utils.processing_optimized import preprocess_frame, calculate_angle
from ultralytics import YOLO

async def benchmark_processing():
    print("🔬 Iniciando benchmark de procesamiento...")
    
    # Cargar modelo
    model = YOLO("models/yolo11n-pose.pt")
    
    # Generar frames de prueba
    test_frames = []
    for i in range(50):
        frame = np.random.randint(0, 255, (480, 640, 3), dtype=np.uint8)
        test_frames.append(frame)
    
    # Benchmark sin optimizaciones
    print("📊 Probando sin optimizaciones...")
    times_normal = []
    for frame in test_frames[:10]:  # Solo 10 para comparación
        start = time.time()
        proc = preprocess_frame(frame, model, use_cache=False)
        end = time.time()
        times_normal.append(end - start)
    
    # Benchmark con optimizaciones
    print("⚡ Probando con optimizaciones...")
    times_optimized = []
    for frame in test_frames[:10]:
        start = time.time()
        proc = preprocess_frame(frame, model, use_cache=True)
        end = time.time()
        times_optimized.append(end - start)
    
    # Resultados
    avg_normal = statistics.mean(times_normal) * 1000
    avg_optimized = statistics.mean(times_optimized) * 1000
    improvement = ((avg_normal - avg_optimized) / avg_normal) * 100
    
    print(f"\n📈 RESULTADOS DEL BENCHMARK:")
    print(f"Sin optimizaciones: {avg_normal:.2f}ms promedio")
    print(f"Con optimizaciones: {avg_optimized:.2f}ms promedio")
    print(f"Mejora: {improvement:.1f}%")
    
    if improvement > 10:
        print("✅ Las optimizaciones están funcionando correctamente")
    else:
        print("⚠️  Las optimizaciones podrían necesitar ajustes")

if __name__ == "__main__":
    asyncio.run(benchmark_processing())
EOF

chmod +x benchmark.py

echo ""
echo "🎉 ¡Optimizaciones configuradas exitosamente!"
echo ""
echo "📋 Archivos creados:"
echo "  • config/optimization.env - Configuración de optimización"
echo "  • start_optimized.sh - Script de inicio optimizado"
echo "  • monitor_performance.sh - Monitor de rendimiento"
echo "  • benchmark.py - Benchmark de rendimiento"
echo ""
echo "🚀 Para iniciar el servidor optimizado:"
echo "  ./start_optimized.sh"
echo ""
echo "📊 Para monitorear rendimiento:"
echo "  ./monitor_performance.sh"
echo ""
echo "🔬 Para ejecutar benchmark:"
echo "  python benchmark.py"
echo ""
echo "⚙️  Configuración actual: $MODE"
case $MODE in
  "production")
    echo "  • Optimizado para producción"
    echo "  • YOLO cada 3 frames"
    echo "  • LSTM cada 5 frames"
    echo "  • Logs minimizados"
    ;;
  "development")
    echo "  • Optimizado para desarrollo"
    echo "  • YOLO cada 2 frames"
    echo "  • LSTM cada 3 frames"
    echo "  • Logs detallados"
    ;;
  "debug")
    echo "  • Configurado para debug"
    echo "  • Procesamiento en cada frame"
    echo "  • Logs máximos"
    ;;
  "high-performance")
    echo "  • Máximo rendimiento"
    echo "  • YOLO cada 4 frames"
    echo "  • LSTM cada 8 frames"
    echo "  • FPS reducido a 15"
    ;;
esac

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

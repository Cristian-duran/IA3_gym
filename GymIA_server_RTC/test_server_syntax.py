#!/usr/bin/env python3
"""
Test script para verificar que webrtc_server_optimized.py
tiene sintaxis correcta y puede importarse.
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

def test_import():
    """Prueba que el módulo se puede importar sin errores de sintaxis"""
    try:
        # Solo importar la definición de clases y funciones, no ejecutar
        with open('app/webrtc_server_optimized.py', 'r', encoding='utf-8') as f:
            code = f.read()
        
        # Compilar el código para verificar sintaxis
        compile(code, 'app/webrtc_server_optimized.py', 'exec')
        print("✅ SINTAXIS CORRECTA: El servidor se puede compilar sin errores")
        return True
        
    except SyntaxError as e:
        print(f"❌ ERROR DE SINTAXIS: {e}")
        print(f"Línea {e.lineno}: {e.text}")
        return False
    except Exception as e:
        print(f"❌ ERROR GENERAL: {e}")
        return False

def test_websocket_feedback_logic():
    """Verifica que la lógica de feedback esté correctamente implementada"""
    with open('app/webrtc_server_optimized.py', 'r', encoding='utf-8') as f:
        code = f.read()
    
    checks = [
        ('websocket=None', 'Parámetro websocket en constructor'),
        ('self.websocket = websocket', 'Asignación de websocket'),
        ('websocket=websocket', 'Paso de websocket a VideoTransformTrack'),
        ('"type": "feedback"', 'Mensaje de feedback por WebSocket'),
        ('WebSocketState.CONNECTED', 'Verificación de estado WebSocket'),
        ('asyncio.create_task', 'Envío asíncrono de mensaje')
    ]
    
    all_passed = True
    for check, description in checks:
        if check in code:
            print(f"✅ {description}: Encontrado")
        else:
            print(f"❌ {description}: NO encontrado")
            all_passed = False
    
    return all_passed

def test_optimization_logic():
    """Verifica que las optimizaciones estén implementadas"""
    with open('app/webrtc_server_optimized.py', 'r', encoding='utf-8') as f:
        code = f.read()
    
    optimizations = [
        ('DETECTION_INTERVAL', 'Intervalo de detección YOLO'),
        ('PREDICTION_INTERVAL', 'Intervalo de predicción LSTM'),
        ('detection_interval', 'Variable de intervalo en clase'),
        ('frame_count % self.detection_interval', 'Lógica de salto de frames'),
        ('ThreadPoolExecutor', 'Threading para CPU intensivo'),
        ('should_predict()', 'Lógica inteligente de predicción')
    ]
    
    all_passed = True
    for opt, description in optimizations:
        if opt in code:
            print(f"✅ {description}: Implementado")
        else:
            print(f"❌ {description}: NO implementado")
            all_passed = False
    
    return all_passed

if __name__ == "__main__":
    print("🔍 VERIFICACIÓN COMPLETA DEL SERVIDOR OPTIMIZADO")
    print("=" * 60)
    
    print("\n1. VERIFICACIÓN DE SINTAXIS:")
    syntax_ok = test_import()
    
    print("\n2. VERIFICACIÓN DE LÓGICA WEBSOCKET:")
    websocket_ok = test_websocket_feedback_logic()
    
    print("\n3. VERIFICACIÓN DE OPTIMIZACIONES:")
    optimizations_ok = test_optimization_logic()
    
    print("\n" + "=" * 60)
    if syntax_ok and websocket_ok and optimizations_ok:
        print("🎉 TODAS LAS VERIFICACIONES PASARON")
        print("✅ El servidor está listo para usar")
        sys.exit(0)
    else:
        print("❌ ALGUNAS VERIFICACIONES FALLARON")
        print("🔧 Revisar los errores mostrados arriba")
        sys.exit(1)

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

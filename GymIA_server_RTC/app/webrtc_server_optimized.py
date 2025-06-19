# Servidor WebRTC optimizado con FastAPI y aiortc
# Procesa video en tiempo real con mejoras de rendimiento

import asyncio
import json
import cv2
import numpy as np
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from starlette.websockets import WebSocketState
from aiortc import RTCPeerConnection, RTCSessionDescription, VideoStreamTrack, RTCIceCandidate
from aiortc.contrib.media import MediaBlackhole, MediaRecorder
from av import VideoFrame
import logging
from collections import deque
from ultralytics import YOLO
from keras.models import load_model
from app.utils.processing import preprocess_frame, calculate_angle, draw_skeleton
import os
import concurrent.futures
import time

# --- Configuración de ejercicios y modelos ---
def load_exercise_config():
    return {
        "peso_muerto": {
            "model_path": "models/lstm4-model4pm.h5",
            "timesteps": 30,
            "angle_joints": [5, 11, 13],
            "angle_thresholds": {"abajo": 140, "arriba": 175},
            "class_labels": [
                "columna_incorrectos",
                "columna_correctos",
                "extension_incorrectas",
                "extension_correctas"
            ],
            "error_msgs": {
                "columna_incorrectos": (
                    "error: columna incorrecta",
                    "correccion: espalda neutra durante el descenso y el levantamiento"
                ),
                "columna_correctos": (
                    "correcto: columna correcta",
                    "buena postura de la espalda"
                ),
                "extension_incorrectas": (
                    "error: super extension o extension incompleta",
                    "correccion: hombros alineados al nivel de la cadera"
                ),
                "extension_correctas": (
                    "correcto: extension correcta",
                    "buena postura en la extension"
                )
            }
        },
        "sentadilla": {
            "model_path": "models/lstm5-model5sen.h5",
            "timesteps": 60,
            "angle_joints": [5, 11, 13, 6, 12, 14],
            "angle_thresholds": {"abajo": 90, "arriba": 160},
            "class_labels": [
                "caderas_incorrectos",
                "caderas_correctos",
                "rodillas_incorrectos",
                "rodillas_correctos"
            ],
            "error_msgs": {
                "caderas_incorrectos": (
                    "error: posicion incorrecta de las caderas",
                    "correccion: baja y sube las caderas en forma recta"
                ),
                "caderas_correctos": (
                    "correcto: posicion correcta de las caderas",
                    "Buena tecnica"
                ),
                "rodillas_incorrectos": (
                    "error: rodillas hacia adentro",
                    "correccion: manten las rodillas ligeramente hacia afuera"
                ),
                "rodillas_correctos": (
                    "correcto: rodillas correctas",
                    "Buena posicion de las rodillas"
                )
            }
        }
    }

# Carga global de YOLO-Pose
YOLO_MODEL = YOLO("models/yolo11n-pose.pt")
EXERCISES = load_exercise_config()
DEFAULT_EXERCISE = os.environ.get("GYMIA_EXERCISE", "peso_muerto")

# Configuración de optimización
DEBUG_MODE = os.environ.get("DEBUG_MODE", "false").lower() == "true"
DETECTION_INTERVAL = int(os.environ.get("DETECTION_INTERVAL", "3"))  # Procesar 1 de cada 3 frames
PREDICTION_INTERVAL = int(os.environ.get("PREDICTION_INTERVAL", "5"))  # Predecir cada 5 frames cuando buffer lleno

app = FastAPI()

# Permitir CORS para pruebas locales
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Lógica de señalización WebSocket ---

@app.websocket("/signaling")
async def websocket_endpoint(websocket: WebSocket):
    if DEBUG_MODE:
        print("[SIGNALING] Nueva conexión WebSocket aceptada")
    await websocket.accept()
    pc = RTCPeerConnection()
    video_sender = None
    selected_exercise = DEFAULT_EXERCISE  # Por defecto
    
    @pc.on("track")
    def on_track(track):
        if DEBUG_MODE:
            print(f"[TRACK] Recibido track: {track.kind}")
        if track.kind == "video":
            local_video = VideoTransformTrack(track, exercise=selected_exercise, websocket=websocket)
            nonlocal video_sender
            video_sender = pc.addTrack(local_video)
            if DEBUG_MODE:
                print(f"[TRACK] Track de video procesado agregado al PeerConnection para ejercicio: {selected_exercise}")

    @pc.on("icecandidate")
    async def on_icecandidate(candidate):
        if DEBUG_MODE:
            print(f"[ICE] Nuevo ICE candidate generado: {candidate}")
        if websocket.client_state == WebSocketState.CONNECTED:
            await websocket.send_text(json.dumps({
                "type": "ice",
                "candidate": {
                    "candidate": candidate.candidate,
                    "sdpMid": candidate.sdpMid,
                    "sdpMLineIndex": candidate.sdpMLineIndex
                }
            }))

    try:
        while True:
            data = await websocket.receive_text()
            msg = json.loads(data)
            if msg["type"] == "offer":
                # Leer el ejercicio si viene en el mensaje
                selected_exercise = msg.get("exercise", DEFAULT_EXERCISE)
                if DEBUG_MODE:
                    print(f"[SIGNALING] Oferta recibida para ejercicio: {selected_exercise}")
                offer = RTCSessionDescription(sdp=msg["sdp"], type=msg["type"])
                await pc.setRemoteDescription(offer)
                answer = await pc.createAnswer()
                await pc.setLocalDescription(answer)
                await websocket.send_text(json.dumps({
                    "type": pc.localDescription.type,
                    "sdp": pc.localDescription.sdp
                }))
                if DEBUG_MODE:
                    print("[SIGNALING] Answer enviada")
            elif msg["type"] == "ice":
                candidate = msg["candidate"]
                if DEBUG_MODE:
                    print(f"[SIGNALING] ICE candidate recibido: {candidate}")
                # Parsear el string SDP del candidate
                candidate_str = candidate["candidate"]
                parts = candidate_str.split()
                if len(parts) >= 6:
                    foundation = parts[0].replace("candidate:", "")
                    component = int(parts[1])
                    protocol = parts[2]
                    priority = int(parts[3])
                    ip = parts[4]
                    port = int(parts[5])
                    typ = parts[7] if len(parts) > 7 else "host"
                    
                    ice = RTCIceCandidate(
                        foundation=foundation,
                        component=component,
                        protocol=protocol,
                        priority=priority,
                        ip=ip,
                        port=port,
                        type=typ,
                        sdpMid=candidate["sdpMid"],
                        sdpMLineIndex=candidate["sdpMLineIndex"]
                    )
                    await pc.addIceCandidate(ice)
                else:
                    if DEBUG_MODE:
                        print(f"[WARNING] Formato de ICE candidate inválido: {candidate_str}")
            elif msg["type"] == "bye":
                if DEBUG_MODE:
                    print("[SIGNALING] Conexión cerrada por el cliente")
                await pc.close()
                break
    except WebSocketDisconnect:
        if DEBUG_MODE:
            print("[SIGNALING] WebSocket desconectado")
        await pc.close()
    except Exception as e:
        if DEBUG_MODE:
            print(f"[ERROR] Excepción en signaling: {e}")
        await pc.close()

# --- Procesamiento de video y anotación optimizado ---

class VideoTransformTrack(VideoStreamTrack):
    """
    Track de video optimizado que procesa y anota los frames con mejor rendimiento.
    """
    kind = "video"

    def __init__(self, track, exercise=DEFAULT_EXERCISE, websocket=None):
        super().__init__()
        self.track = track
        self.websocket = websocket  # Referencia al WebSocket para enviar feedback
        self.exercise = exercise if exercise in EXERCISES else DEFAULT_EXERCISE
        self.cfg = EXERCISES[self.exercise]
        self.lstm = load_model(self.cfg["model_path"])
        self.buffer = deque(maxlen=self.cfg["timesteps"])
        self.thr = self.cfg["angle_thresholds"]
        self.joints = self.cfg["angle_joints"]
        self.state = None
        self.last_state = None
        self.reps = 0
        
        # Optimizaciones de rendimiento
        self.frame_count = 0
        self.detection_interval = DETECTION_INTERVAL
        self.prediction_interval = PREDICTION_INTERVAL
        self.last_detection = None
        self.last_prediction_result = None
        self.prediction_count = 0
        self.executor = concurrent.futures.ThreadPoolExecutor(max_workers=2)
        
        # Cache para evitar recálculos
        self.skeleton_color = (0, 0, 255)  # Color por defecto
        self.current_messages = []
        
        if DEBUG_MODE:
            print(f"[INIT] VideoTransformTrack inicializado para {self.exercise}")

    def should_predict(self):
        """Determina si debe ejecutar predicción LSTM basado en intervalos y cambios de estado"""
        return (self.prediction_count % self.prediction_interval == 0 or 
                self.state != self.last_state)

    def process_frame_cpu_intensive(self, img):
        """Procesa la parte CPU-intensiva en thread separado"""
        proc = preprocess_frame(img, YOLO_MODEL)
        return proc

    async def recv(self):
        frame = await self.track.recv()
        img = frame.to_ndarray(format="bgr24")
        
        self.frame_count += 1
        
        # Optimización: Solo procesar YOLO cada N frames
        if self.frame_count % self.detection_interval == 0:
            # Procesar en thread separado para no bloquear
            loop = asyncio.get_event_loop()
            proc = await loop.run_in_executor(
                self.executor, 
                self.process_frame_cpu_intensive, 
                img
            )
            self.last_detection = proc
        else:
            proc = self.last_detection
            
        if proc is None:
            out = cv2.resize(img, (640, 640))
            if DEBUG_MODE and self.frame_count % 30 == 0:  # Solo cada 30 frames
                print("[FRAME] No se detectaron poses, frame original reenviado")
        else:
            kps_flat, kps_orig, vis = proc
            self.buffer.append(kps_flat)
            
            # --- Lógica diferenciada por ejercicio (optimizada) ---
            state = self._calculate_exercise_state(kps_orig)
            
            # Actualizar estados
            self.last_state = self.state
            self.state = state
            
            # Optimización: Solo predecir LSTM cuando sea necesario
            if len(self.buffer) == self.cfg["timesteps"] and self.should_predict():
                self._process_lstm_prediction()
                self.prediction_count += 1
            # Solo dibujar estado si está disponible y en modo debug
            if state and DEBUG_MODE:
                cv2.putText(vis, f"State: {state}", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 0, 255), 2)
            
            # Mensajes de predicción ya NO se muestran visualmente (solo audio por WebSocket)
            # self._draw_prediction_messages(vis)  # ELIMINADO: Solo audio, no visual
            
            # SIEMPRE dibujar el esqueleto con el color correcto
            interest_points = self.joints if self.exercise == "sentadilla" else [5, 11, 13]
            draw_skeleton(vis, kps_orig, interest_points, self.skeleton_color, exercise=self.exercise)
            
            out = vis
            
        new_frame = VideoFrame.from_ndarray(out, format="bgr24")
        new_frame.pts = frame.pts
        new_frame.time_base = frame.time_base
        
        return new_frame

    def _calculate_exercise_state(self, kps_orig):
        """Calcula el estado del ejercicio de manera optimizada"""
        try:
            if self.exercise == "sentadilla":
                a, b, c = [kps_orig[i] for i in [5, 11, 13]]  # Hombro izq, cadera izq, rodilla izq
            else:
                a, b, c = [kps_orig[i] for i in self.joints]
                
            angle = calculate_angle(a, b, c)
            
            if angle < self.thr["abajo"]:
                return "abajo"
            elif angle > self.thr["arriba"]:
                return "arriba"
            return None
        except (IndexError, ValueError):
            return None

    def _process_lstm_prediction(self):
        """Procesa la predicción LSTM y actualiza el estado visual"""
        try:
            seq = np.array(self.buffer).reshape(1, self.cfg["timesteps"], -1)
            proba = self.lstm.predict(seq, verbose=0)[0]
            idx = int(np.argmax(proba))
            error_keys = list(self.cfg["error_msgs"].keys())
            
            if idx < len(error_keys):
                label = error_keys[idx]
                conf = proba[idx]                # Actualizar color del esqueleto
                self.skeleton_color = (0, 255, 0) if "correctos" in label or "correctas" in label else (0, 0, 255)
                
                # Preparar mensajes para mostrar
                err, sol = self.cfg["error_msgs"][label]
                err_color = (0, 0, 255) if err.startswith("error:") else (0, 255, 0)
                sol_color = (0, 255, 0) if any(word in sol for word in ["correcto:", "correccion:", "Buena"]) else (0, 255, 0)
                
                # NOTA: current_messages ya NO se usa para visual, solo se mantiene por compatibilidad
                # Los mensajes ahora SOLO se envían por WebSocket para audio TTS
                self.current_messages = [
                    (err, (10, 60), err_color),
                    (sol, (10, 85), sol_color),
                    (f"Conf: {conf:.2f}", (10, 110), (255, 255, 255))
                ]
                
                # Enviar feedback por WebSocket para TTS en cliente Flutter
                if self.websocket and self.websocket.client_state == WebSocketState.CONNECTED:
                    feedback_message = f"{err}\n{sol}\nConf: {conf:.2f}"
                    asyncio.create_task(self.websocket.send_text(json.dumps({
                        "type": "feedback",
                        "message": feedback_message                    })))
                
                if DEBUG_MODE:
                    print(f"[LSTM] Predicción: {label} (conf: {conf:.2f})")
            else:
                if DEBUG_MODE:
                    print(f"[WARNING] Índice fuera de rango: {idx}")
        except Exception as e:
            if DEBUG_MODE:
                print(f"[ERROR] Error en predicción LSTM: {e}")

    def _draw_prediction_messages(self, vis):
        """
        FUNCIÓN DESHABILITADA: Los mensajes ya NO se muestran visualmente.
        Solo se envían por WebSocket para reproducción de audio TTS.
        La lógica de mensajes se mantiene en _process_lstm_prediction() para el WebSocket.
        """
        # NO dibujar nada - solo audio por WebSocket
        pass

    def __del__(self):
        """Limpia recursos al destruir el objeto"""
        if hasattr(self, 'executor'):
            self.executor.shutdown(wait=False)

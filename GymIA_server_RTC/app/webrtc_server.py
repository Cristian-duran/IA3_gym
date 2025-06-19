# Servidor WebRTC con FastAPI y aiortc
# Procesa video en tiempo real, anota y devuelve el stream

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
                    "error: posicion incorrecta de la columna",
                    "correccion: espalda recta durante el descenso y el levantamiento"
                ),
                "columna_correctos": (
                    "correcto: posicion correcta de la columna",
                    "Buena postura de la espalda"
                ),
                "extension_incorrectas": (
                    "error: extension incorrecta",
                    "correccion: hombros no sobrepasen la cadera"
                ),
                "extension_correctas": (
                    "correcto: extension correcta",
                    "Buena tecnica en la extension"
                )
            }
        },
        "sentadilla": {
            "model_path": "models/lstm3-model3sen.h5",
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
                    "correccion: baja correctamente las caderas en forma recta"
                ),
                "caderas_correctos": (
                    "correcto: posicion correcta de las caderas",
                    "Buena tecnica"
                ),
                "rodillas_incorrectos": (
                    "error: rodillas hacia adentro",
                    "correccion: mantén las rodillas hacia afuera"
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
    print("[SIGNALING] Nueva conexión WebSocket aceptada")
    await websocket.accept()
    pc = RTCPeerConnection()
    video_sender = None
    selected_exercise = DEFAULT_EXERCISE  # Por defecto
    
    @pc.on("track")
    def on_track(track):
        print(f"[TRACK] Recibido track: {track.kind}")
        if track.kind == "video":
            local_video = VideoTransformTrack(track, exercise=selected_exercise)
            nonlocal video_sender
            video_sender = pc.addTrack(local_video)
            print(f"[TRACK] Track de video procesado agregado al PeerConnection para ejercicio: {selected_exercise}")

    @pc.on("icecandidate")
    async def on_icecandidate(candidate):
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
                print(f"[SIGNALING] Oferta recibida para ejercicio: {selected_exercise}")
                offer = RTCSessionDescription(sdp=msg["sdp"], type=msg["type"])
                await pc.setRemoteDescription(offer)
                answer = await pc.createAnswer()
                await pc.setLocalDescription(answer)
                await websocket.send_text(json.dumps({
                    "type": pc.localDescription.type,
                    "sdp": pc.localDescription.sdp
                }))
                print("[SIGNALING] Answer enviada")
            elif msg["type"] == "ice":
                candidate = msg["candidate"]
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
                    print(f"[WARNING] Formato de ICE candidate inválido: {candidate_str}")
            elif msg["type"] == "bye":
                print("[SIGNALING] Conexión cerrada por el cliente")
                await pc.close()
                break
    except WebSocketDisconnect:
        print("[SIGNALING] WebSocket desconectado")
        await pc.close()
    except Exception as e:
        print(f"[ERROR] Excepción en signaling: {e}")
        await pc.close()

# --- Procesamiento de video y anotación ---

class VideoTransformTrack(VideoStreamTrack):
    """
    Track de video que procesa y anota los frames recibidos.
    """
    kind = "video"

    def __init__(self, track, exercise=DEFAULT_EXERCISE):
        super().__init__()
        self.track = track
        self.exercise = exercise if exercise in EXERCISES else DEFAULT_EXERCISE
        self.cfg = EXERCISES[self.exercise]
        self.lstm = load_model(self.cfg["model_path"])
        self.buffer = deque(maxlen=self.cfg["timesteps"])
        self.thr = self.cfg["angle_thresholds"]
        self.joints = self.cfg["angle_joints"]
        self.state = None
        self.last_state = None
        self.reps = 0

    async def recv(self):
        frame = await self.track.recv()
        img = frame.to_ndarray(format="bgr24")
        print("[FRAME] Frame recibido para procesamiento")
        proc = preprocess_frame(img, YOLO_MODEL)
        if proc is None:
            out = cv2.resize(img, (640, 640))
            print("[FRAME] No se detectaron poses, frame original reenviado")
        else:
            kps_flat, kps_orig, vis = proc
            self.buffer.append(kps_flat)
            
            # --- Lógica diferenciada por ejercicio ---
            if self.exercise == "sentadilla":
                # Para sentadilla, puntos de interés: [5, 6, 11, 12, 13, 14]
                # Calcular ángulo (lógica interna, no mostrar)
                a, b, c = [kps_orig[i] for i in [5, 11, 13]]  # Hombro izq, cadera izq, rodilla izq
                angle = calculate_angle(a, b, c)
                # NO mostrar ángulo: cv2.putText(vis, f"Ang: {int(angle)}", ...)
                state = None
                if angle < self.thr["abajo"]:
                    state = "abajo"
                elif angle > self.thr["arriba"]:
                    state = "arriba"
                if state:
                    cv2.putText(vis, f"State: {state}", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 0, 255), 2)
            else:
                # Para peso muerto, puntos de interés: [5, 11, 13]
                # Calcular ángulo (lógica interna, no mostrar)
                a, b, c = [kps_orig[i] for i in self.joints]
                angle = calculate_angle(a, b, c)
                # NO mostrar ángulo: cv2.putText(vis, f"Ang: {int(angle)}", ...)
                state = None
                if angle < self.thr["abajo"]:
                    state = "abajo"
                elif angle > self.thr["arriba"]:
                    state = "arriba"
                if state:
                    cv2.putText(vis, f"State: {state}", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 0, 255), 2)
            self.last_state = self.state
            self.state = state
            
            # Variables por defecto para el esqueleto
            skeleton_color = (0, 0, 255)  # Rojo por defecto (asume incorrecto)
            show_messages = False
            
            if len(self.buffer) == self.cfg["timesteps"]:
                seq = np.array(self.buffer).reshape(1, self.cfg["timesteps"], -1)
                proba = self.lstm.predict(seq, verbose=0)[0]
                idx = int(np.argmax(proba))
                error_keys = list(self.cfg["error_msgs"].keys())
                if idx < len(error_keys):
                    label = error_keys[idx]
                    conf = proba[idx]
                    # Determinar color del esqueleto según corrección
                    skeleton_color = (0, 255, 0) if "correctos" in label or "correctas" in label else (0, 0, 255)
                    show_messages = True
                    
                    err, sol = self.cfg["error_msgs"][label]
                    # Determinar colores de mensajes según contenido
                    # Mensajes de error (que empiezan con "error:") en rojo
                    err_color = (0, 0, 255) if err.startswith("error:") else (0, 255, 0)
                    # Mensajes de corrección/confirmación en verde
                    sol_color = (0, 255, 0) if sol.startswith("correcto:") or sol.startswith("correccion:") or sol.startswith("Buena") else (0, 255, 0)
                      # Mostrar mensajes con colores apropiados
                    cv2.putText(vis, err, (10, 60), cv2.FONT_HERSHEY_SIMPLEX, 0.6, err_color, 2)
                    cv2.putText(vis, sol, (10, 85), cv2.FONT_HERSHEY_SIMPLEX, 0.6, sol_color, 2)
                else:
                    print(f"[WARNING] Índice de predicción fuera de rango: idx={idx}, clases={len(error_keys)}")
            
            # SIEMPRE dibujar el esqueleto con el color correcto
            # Para sentadilla usar todos los puntos [5, 11, 13, 6, 12, 14]
            # Para peso muerto usar solo [5, 11, 13]
            interest_points = self.joints if self.exercise == "sentadilla" else [5, 11, 13]
            draw_skeleton(vis, kps_orig, interest_points, skeleton_color, exercise=self.exercise)
            
            out = vis
            print("[FRAME] Frame procesado y anotado")
        new_frame = VideoFrame.from_ndarray(out, format="bgr24")
        new_frame.pts = frame.pts
        new_frame.time_base = frame.time_base
        print("[FRAME] Frame enviado de vuelta al cliente")
        return new_frame


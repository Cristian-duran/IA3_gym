from fastapi import FastAPI, WebSocket, WebSocketDisconnect
import cv2
import numpy as np
from collections import deque
from ultralytics import YOLO
from keras.models import load_model
from app.utils.processing import preprocess_frame, calculate_angle, draw_skeleton

app = FastAPI()

def load_exercise_config():
    return {
        "peso_muerto": {
            "model_path": "models/lstm4-model4pm.h5",
            "timesteps": 30,
            "angle_joints": [5, 11, 13],
            "angle_thresholds": {"down": 140, "up": 175},
            "error_msgs": {
                "caderas_incorrectos": (
                    "error: caderas demasiado bajas",
                    "correccion: eleva cadera manteniendo la espalda recta"
                ),
                "rodillas_incorrectos": (
                    "error: rodillas adelantadas",
                    "correccion: mantén las rodillas alineadas con los pies"
                )
            }
        },
        "sentadilla": {
            "model_path": "models/lstm3-model3sen.h5",
            "timesteps": 60,
            "angle_joints": [5, 11, 13],
            "angle_thresholds": {"down": 90, "up": 160},
            "error_msgs": {
                "profundidad_insuficiente": (
                    "error: falta profundidad",
                    "correccion: baja hasta que muslos paralelos al suelo"
                ),
                "espalda_curvada": (
                    "error: espalda curvada",
                    "correccion: mantén pecho alto y mirada al frente"
                )
            }
        }
    }

# Carga global de YOLO-Pose
yolo = YOLO("models/yolo11n-pose.pt")
EXERCISES = load_exercise_config()

@app.websocket("/ws/{exercise}")
async def websocket_exercise(ws: WebSocket, exercise: str):
    if exercise not in EXERCISES:
        await ws.close(code=1003)
        return

    cfg    = EXERCISES[exercise]
    lstm   = load_model(cfg["model_path"])
    buffer = deque(maxlen=cfg["timesteps"])
    thr    = cfg["angle_thresholds"]
    joints = cfg["angle_joints"]

    await ws.accept()
    try:
        while True:
            data = await ws.receive_bytes()
            arr   = np.frombuffer(data, np.uint8)
            frame = cv2.imdecode(arr, cv2.IMREAD_COLOR)

            proc = preprocess_frame(frame, yolo)
            if proc is None:
                out = cv2.resize(frame, (640, 640))
            else:
                kps_flat, kps_orig, vis = proc
                buffer.append(kps_flat)

                # Cálculo de ángulo y estado
                a, b, c = [kps_orig[i] for i in joints]
                angle = calculate_angle(a, b, c)
                cv2.putText(vis, f"Ang: {int(angle)}", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 0), 2)
                state = None
                if angle < thr["down"]: state = "down"
                elif angle > thr["up"]: state = "up"
                if state:
                    cv2.putText(vis, f"State: {state}", (10, 60), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 0, 255), 2)

                # LSTM predict
                if len(buffer) == cfg["timesteps"]:
                    seq   = np.array(buffer).reshape(1, cfg["timesteps"], -1)
                    proba = lstm.predict(seq)[0]
                    idx   = int(np.argmax(proba))
                    label = list(cfg["error_msgs"].keys())[idx]
                    conf  = proba[idx]
                    color = (0, 255, 0) if "correctos" in label else (0, 0, 255)
                    cv2.putText(vis, f"{label} ({conf:.2f})", (10, 90), cv2.FONT_HERSHEY_SIMPLEX, 0.8, color, 2)
                    draw_skeleton(vis, kps_orig, joints, color)
                    err, sol = cfg["error_msgs"][label]
                    cv2.putText(vis, err, (10, 130), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 0, 255), 2)
                    cv2.putText(vis, sol, (10, 155), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 0, 255), 2)
                out = vis

            _, jpg = cv2.imencode(".jpg", out, [cv2.IMWRITE_JPEG_QUALITY, 80])
            await ws.send_bytes(jpg.tobytes())
    except WebSocketDisconnect:
        pass
import cv2
import numpy as np

WINDOW_SIZE = (640, 640)

def preprocess_frame(frame, yolo_model):
    img = cv2.resize(frame, WINDOW_SIZE)
    res = yolo_model.track(img, persist=True)
    if not res or not res[0].boxes:
        return None

    best_idx, best_area = None, 0
    for i, box in enumerate(res[0].boxes.xyxy):
        x1, y1, x2, y2 = box.cpu().numpy()
        area = (x2 - x1) * (y2 - y1)
        if area > best_area:
            best_idx, best_area = i, area
    if best_idx is None:
        return None

    kps_flat = res[0].keypoints[best_idx].xyn.cpu().numpy().flatten()
    kps_orig = res[0].keypoints[best_idx].xy.data.cpu().numpy()[0]
    vis = res[0].plot()
    return kps_flat, kps_orig, vis


def calculate_angle(a, b, c):
    a, b, c = np.array(a), np.array(b), np.array(c)
    ba, bc = a - b, c - b
    if np.linalg.norm(ba) == 0 or np.linalg.norm(bc) == 0:
        return 0.0
    cos_angle = np.dot(ba, bc) / (np.linalg.norm(ba) * np.linalg.norm(bc))
    cos_angle = np.clip(cos_angle, -1.0, 1.0)
    return float(np.degrees(np.arccos(cos_angle)))


def draw_skeleton(frame, joints, interest, color, exercise=None):
    """
    Dibuja esqueleto completo en morado y resalta puntos de interés en verde/rojo
    """
    # Color base para todo el esqueleto (morado)
    base_color = (255, 0, 255)  # Morado en BGR
    
    # Primero dibujar TODOS los puntos del esqueleto en morado
    for idx in range(len(joints)):
        point = joints[idx]
        # Verificar que el punto sea válido (no (0,0) y dentro de límites)
        if (len(point) >= 2 and 
            not (point[0] == 0 and point[1] == 0) and 
            0 <= point[0] <= frame.shape[1] and 
            0 <= point[1] <= frame.shape[0]):
            point_tuple = tuple(map(int, point[:2]))
            cv2.circle(frame, point_tuple, radius=8, color=base_color, thickness=-1)
    
    # Luego redibujar SOLO los puntos de interés con el color específico (verde/rojo)
    for idx in interest:
        if idx < len(joints):
            point = joints[idx]
            # Verificar que el punto sea válido
            if (len(point) >= 2 and 
                not (point[0] == 0 and point[1] == 0) and 
                0 <= point[0] <= frame.shape[1] and 
                0 <= point[1] <= frame.shape[0]):
                point_tuple = tuple(map(int, point[:2]))
                cv2.circle(frame, point_tuple, radius=8, color=color, thickness=-1)
import cv2
import numpy as np
import time

WINDOW_SIZE = (640, 640)

# Cache para optimizar rendimiento
_last_keypoints = None
_last_vis = None
_cache_timestamp = 0
CACHE_DURATION = 0.1  # 100ms cache

def preprocess_frame(frame, yolo_model, use_cache=True):
    """
    Versión optimizada del preprocesamiento con cache opcional
    """
    global _last_keypoints, _last_vis, _cache_timestamp
    
    # Si hay cache válido y está habilitado, usarlo
    if use_cache and _last_keypoints is not None and time.time() - _cache_timestamp < CACHE_DURATION:
        return _last_keypoints
    
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
    
    result = (kps_flat, kps_orig, vis)
    
    # Actualizar cache
    if use_cache:
        _last_keypoints = result
        _cache_timestamp = time.time()
    
    return result


def calculate_angle(a, b, c):
    """
    Versión optimizada del cálculo de ángulos con validación mejorada
    """
    try:
        a, b, c = np.array(a, dtype=np.float32), np.array(b, dtype=np.float32), np.array(c, dtype=np.float32)
        
        # Verificar que los puntos no sean (0,0) o inválidos
        if np.any(np.isnan([a, b, c])) or np.any(np.isinf([a, b, c])):
            return 0.0
            
        ba, bc = a - b, c - b
        
        # Calcular normas
        norm_ba = np.linalg.norm(ba)
        norm_bc = np.linalg.norm(bc)
        
        if norm_ba == 0 or norm_bc == 0:
            return 0.0
            
        cos_angle = np.dot(ba, bc) / (norm_ba * norm_bc)
        cos_angle = np.clip(cos_angle, -1.0, 1.0)
        
        return float(np.degrees(np.arccos(cos_angle)))
    except (ValueError, ZeroDivisionError):
        return 0.0


def draw_skeleton(frame, joints, interest, color, exercise=None):
    """
    Versión optimizada del dibujo de esqueleto con validación mejorada.
    Dibuja esqueleto completo en morado y resalta puntos de interés en verde/rojo.
    """
    if joints is None or len(joints) == 0:
        return
        
    # Validar que interest sea una lista válida
    if not isinstance(interest, (list, tuple, np.ndarray)):
        return
    
    # Color base para todo el esqueleto (morado)
    base_color = (255, 0, 255)  # Morado en BGR
    
    # Primero dibujar TODOS los puntos del esqueleto en morado
    for idx in range(len(joints)):
        try:
            point = joints[idx]
            # Verificar que el punto sea válido (no (0,0) y dentro de límites razonables)
            if (len(point) >= 2 and 
                not (point[0] == 0 and point[1] == 0) and 
                0 <= point[0] <= frame.shape[1] and 
                0 <= point[1] <= frame.shape[0]):
                
                point_tuple = tuple(map(int, point[:2]))
                cv2.circle(frame, point_tuple, radius=8, color=base_color, thickness=-1)
        except (IndexError, ValueError, TypeError):
            # Si hay error con algún punto, continuar con el siguiente
            continue
        
    # Luego redibujar SOLO los puntos de interés con el color específico (verde/rojo)
    for idx in interest:
        try:
            if idx < len(joints):
                point = joints[idx]
                # Verificar que el punto sea válido (no (0,0) y dentro de límites razonables)
                if (len(point) >= 2 and 
                    not (point[0] == 0 and point[1] == 0) and 
                    0 <= point[0] <= frame.shape[1] and 
                    0 <= point[1] <= frame.shape[0]):
                    
                    point_tuple = tuple(map(int, point[:2]))
                    cv2.circle(frame, point_tuple, radius=8, color=color, thickness=-1)
        except (IndexError, ValueError, TypeError):
            # Si hay error con algún punto, continuar con el siguiente
            continue


def draw_skeleton_optimized(frame, joints, interest, color, exercise=None):
    """
    Versión más optimizada que dibuja múltiples círculos de una vez.
    Dibuja esqueleto completo en morado y resalta puntos de interés en verde/rojo.
    """
    if joints is None or len(joints) == 0 or not isinstance(interest, (list, tuple, np.ndarray)):
        return
    
    # Color base para todo el esqueleto (morado)
    base_color = (255, 0, 255)  # Morado en BGR
        
    # Recopilar todos los puntos válidos del esqueleto completo (morado)
    all_valid_points = []
    for idx in range(len(joints)):
        try:
            point = joints[idx]
            if (len(point) >= 2 and 
                not (point[0] == 0 and point[1] == 0) and 
                0 <= point[0] <= frame.shape[1] and 
                0 <= point[1] <= frame.shape[0]):
                all_valid_points.append(tuple(map(int, point[:2])))
        except (IndexError, ValueError, TypeError):
            continue
    
    # Dibujar todos los puntos del esqueleto en morado
    for point in all_valid_points:
        cv2.circle(frame, point, radius=8, color=base_color, thickness=-1)
        
    # Recopilar puntos de interés válidos (verde/rojo)
    interest_valid_points = []
    for idx in interest:
        try:
            if idx < len(joints):
                point = joints[idx]
                if (len(point) >= 2 and 
                    not (point[0] == 0 and point[1] == 0) and 
                    0 <= point[0] <= frame.shape[1] and 
                    0 <= point[1] <= frame.shape[0]):
                    interest_valid_points.append(tuple(map(int, point[:2])))
        except (IndexError, ValueError, TypeError):
            continue
    
    # Redibujar solo los puntos de interés con el color específico
    for point in interest_valid_points:
        cv2.circle(frame, point, radius=8, color=color, thickness=-1)


# Función de utilidad para limpiar cache si es necesario
def clear_cache():
    """Limpia el cache de preprocessing"""
    global _last_keypoints, _last_vis, _cache_timestamp
    _last_keypoints = None
    _last_vis = None
    _cache_timestamp = 0

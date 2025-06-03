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
    vis      = res[0].plot()
    return kps_flat, kps_orig, vis


def calculate_angle(a, b, c):
    a, b, c = np.array(a), np.array(b), np.array(c)
    ba, bc = a - b, c - b
    if np.linalg.norm(ba) == 0 or np.linalg.norm(bc) == 0:
        return 0.0
    cos_angle = np.dot(ba, bc) / (np.linalg.norm(ba) * np.linalg.norm(bc))
    cos_angle = np.clip(cos_angle, -1.0, 1.0)
    return float(np.degrees(np.arccos(cos_angle)))


def draw_skeleton(frame, joints, interest, color):
    for i in range(len(interest) - 1):
        a, b = interest[i], interest[i + 1]
        p1 = tuple(map(int, joints[a]))
        p2 = tuple(map(int, joints[b]))
        cv2.line(frame, p1, p2, color, thickness=4)
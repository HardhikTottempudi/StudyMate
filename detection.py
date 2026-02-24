import cv2
from ultralytics import YOLO

# 1) Load your custom model (.pt)
model = YOLO("best.pt")

# 2) Open webcam (0 = default camera)
cap = cv2.VideoCapture(0)

# (Optional) Ask for a specific resolution for speed/quality balance
cap.set(cv2.CAP_PROP_FRAME_WIDTH,  1280)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)

# 3) Inference loop
while True:
    ok, frame = cap.read()
    if not ok:
        break

    # Run inference (tune conf & iou as needed)
    results = model.predict(
        frame,
        conf=0.10,   # raise for fewer boxes, lower for more
        iou=0.45,   # NMS IoU threshold
        imgsz=640,  # 320/480/640 affect speed/accuracy
        verbose=False   
    )
    annotated = results[0].plot()

    # 5) Show
    cv2.imshow("Detections", annotated)

    # ESC to quit
    if cv2.waitKey(1) & 0xFF == 27:
        break

cap.release()
cv2.destroyAllWindows()

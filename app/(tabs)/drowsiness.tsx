// DetectPage.tsx
import * as ort from "onnxruntime-react-native";

import { useEffect, useRef, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import { Camera, useCameraDevices } from "react-native-vision-camera";

export default function DetectPage() {
  const devices = useCameraDevices();
  const device = devices.find(d => d.position === "front") 
              ?? devices.find(d => d.position === "back"); // choose front/back
  const cameraRef = useRef<Camera>(null);
  const [session, setSession] = useState<ort.InferenceSession | null>(null);
  const [boxes, setBoxes] = useState<Array<{x:number;y:number;w:number;h:number;score:number;label:number}>>([]);

  useEffect(() => {
    (async () => {
      const status = await Camera.requestCameraPermission();
      if (status !== "authorized") return;

      // Load ONNX model from bundle
      const sess = await ort.InferenceSession.create(
        // iOS: just the filename works; Android: use "model.onnx" in assets
        "model.onnx",
        { executionProviders: ["cpu"] } // or "coreml" on iOS if available
      );
      setSession(sess);
    })();
  }, []);

  // naive periodic capture → inference (simpler than a frame processor)
  useEffect(() => {
    if (!session || !cameraRef.current) return;
    let mounted = true;
    const interval = setInterval(async () => {
      try {
        // take a low-res photo for speed; or use takeSnapshot() if available
        const photo = await cameraRef.current?.takePhoto({ qualityPrioritization: "speed" });
        if (!photo || !mounted) return;

        // Load image into RGBA tensor [1,3,640,640] as your model expects
        // (Implement resize/normalize; code omitted for brevity)
        const inputTensor = await imageFileToTensor(photo.path, 640, 640); // write this util

        const results = await session.run({ images: inputTensor });
        const raw = results.outputs.data as Float32Array | number[];
        // Postprocess: decode boxes/scores/classes + NMS (implement for your model)
        const dets = postprocessDetections(raw, /*imgW*/640, /*imgH*/640, /*scoreTh*/0.25, /*iouTh*/0.45);
        setBoxes(dets);
      } catch (e) {
        // ignore occasional camera contention
      }
    }, 300); // ~3 fps starter; tune for your device
    return () => {
      mounted = false;
      clearInterval(interval);
    };
  }, [session]);

  if (!device) return <Text>Loading camera…</Text>;

  return (
    <View style={styles.container}>
      <Camera
        ref={cameraRef}
        style={StyleSheet.absoluteFill}
        device={device}
        isActive
        photo // we use takePhoto() for quick snapshots
      />
      {/* draw boxes as overlay */}
      <View style={StyleSheet.absoluteFill} pointerEvents="none">
        {boxes.map((b, i) => (
          <View key={i} style={{
            position: "absolute",
            left: b.x, top: b.y, width: b.w, height: b.h,
            borderWidth: 2, borderColor: "lime", borderRadius: 4
          }}/>
        ))}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({ container: { flex: 1, backgroundColor: "#000" }});

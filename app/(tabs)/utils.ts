import { Tensor } from 'onnxruntime-react-native';
import * as ImageManipulator from 'expo-image-manipulator';
import { decode as jpegDecode } from 'jpeg-js';

// Define the structure of a detection
export interface Detection {
  box: [number, number, number, number]; // [x, y, width, height]
  label: string;
  score: number;
}

const MODEL_WIDTH = 640;
const MODEL_HEIGHT = 640;

// COCO class names
const COCO_CLASSES = ['person', 'bicycle', 'car', 'motorcycle', 'airplane', 'bus', 'train', 'truck', 'boat', 'traffic light', 'fire hydrant', 'stop sign', 'parking meter', 'bench', 'bird', 'cat', 'dog', 'horse', 'sheep', 'cow', 'elephant', 'bear', 'zebra', 'giraffe', 'backpack', 'umbrella', 'handbag', 'tie', 'suitcase', 'frisbee', 'skis', 'snowboard', 'sports ball', 'kite', 'baseball bat', 'baseball glove', 'skateboard', 'surfboard', 'tennis racket', 'bottle', 'wine glass', 'cup', 'fork', 'knife', 'spoon', 'bowl', 'banana', 'apple', 'sandwich', 'orange', 'broccoli', 'carrot', 'hot dog', 'pizza', 'donut', 'cake', 'chair', 'couch', 'potted plant', 'bed', 'dining table', 'toilet', 'tv', 'laptop', 'mouse', 'remote', 'keyboard', 'cell phone', 'microwave', 'oven', 'toaster', 'sink', 'refrigerator', 'book', 'clock', 'vase', 'scissors', 'teddy bear', 'hair drier', 'toothbrush'];

/**
 * Preprocesses a camera frame to a tensor for the ONNX model.
 * @param frame The camera frame from react-native-vision-camera.
 * @returns A promise that resolves to the input tensor.
 */
export const preprocess = async (frame: any): Promise<Tensor> => {
  const { uri } = frame;
  // 1. Resize the image to 640x640
  const manipResult = await ImageManipulator.manipulateAsync(
    uri,
    [{ resize: { width: MODEL_WIDTH, height: MODEL_HEIGHT } }],
    { format: ImageManipulator.SaveFormat.JPEG, base64: true }
  );

  // 2. Decode JPEG to raw image data
  const rawImageData = jpegDecode(Buffer.from(manipResult.base64, 'base64'), { useTArray: true });
  const { width, height, data } = rawImageData;

  // 3. Normalize and create tensor
  const inputArray = new Float32Array(MODEL_WIDTH * MODEL_HEIGHT * 3);
  for (let i = 0; i < width * height; i++) {
    const j = i * 4;
    inputArray[i] = data[j] / 255.0; // R
    inputArray[i + width * height] = data[j + 1] / 255.0; // G
    inputArray[i + 2 * width * height] = data[j + 2] / 255.0; // B
  }

  const tensor = new Tensor('float32', inputArray, [1, 3, MODEL_HEIGHT, MODEL_WIDTH]);
  return tensor;
};

/**
 * Postprocesses the output of the ONNX model to a list of detections.
 * @param results The output from the ONNX model.
 * @returns A list of detections.
 */
export const postprocess = (results: any): Detection[] => {
  const detections: Detection[] = [];
  const confidenceThreshold = 0.5;

  // Assuming the output tensor name is 'output0' and shape is [1, 84, 8400]
  const data = results.output0.data as Float32Array;
  const numDetections = 8400;
  const numClasses = 80;

  for (let i = 0; i < numDetections; i++) {
    const classScores = data.slice(i * (numClasses + 4) + 4, (i + 1) * (numClasses + 4));
    let maxScore = 0;
    let maxIndex = -1;
    for (let j = 0; j < numClasses; j++) {
      if (classScores[j] > maxScore) {
        maxScore = classScores[j];
        maxIndex = j;
      }
    }

    if (maxScore > confidenceThreshold) {
      const [x_center, y_center, width, height] = data.slice(i * (numClasses + 4), i * (numClasses + 4) + 4);
      const x = (x_center - width / 2);
      const y = (y_center - height / 2);

      detections.push({
        box: [x, y, width, height],
        label: COCO_CLASSES[maxIndex],
        score: maxScore,
      });
    }
  }

  // Note: NMS is not implemented here, so you might see overlapping boxes.
  return detections;
};
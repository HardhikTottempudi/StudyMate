// import * as tf from '@tensorflow/tfjs';
// import '@tensorflow/tfjs-platform-react-native';
// import '@tensorflow/tfjs-react-native';
// import { decodeJpeg } from '@tensorflow/tfjs-react-native';
// import { CameraType, CameraView, useCameraPermissions } from 'expo-camera';
// import { useEffect, useRef, useState } from 'react';
// import {
//   ActivityIndicator,
//   Alert,
//   Dimensions,
//   StyleSheet,
//   Text,
//   TouchableOpacity,
//   View,
// } from 'react-native';

// const { width, height } = Dimensions.get('window');

// interface DetectionResult {
//   class: string;
//   score: number;
//   bbox: number[];
// }

// export default function ObjectDetectionScreen() {
//   const [permission, requestPermission] = useCameraPermissions();
//   const [facing, setFacing] = useState<CameraType>('back');
//   const [isModelLoaded, setIsModelLoaded] = useState(false);
//   const [isDetecting, setIsDetecting] = useState(false);
//   const [detections, setDetections] = useState<DetectionResult[]>([]);
//   const [model, setModel] = useState<tf.GraphModel | null>(null);
//   const cameraRef = useRef<CameraView>(null);

//   // COCO dataset class names (for MobileNet SSD)
//   const classNames = [
//     'person', 'bicycle', 'car', 'motorcycle', 'airplane', 'bus', 'train', 'truck',
//     'boat', 'traffic light', 'fire hydrant', 'stop sign', 'parking meter', 'bench',
//     'bird', 'cat', 'dog', 'horse', 'sheep', 'cow', 'elephant', 'bear', 'zebra',
//     'giraffe', 'backpack', 'umbrella', 'handbag', 'tie', 'suitcase', 'frisbee',
//     'skis', 'snowboard', 'sports ball', 'kite', 'baseball bat', 'baseball glove',
//     'skateboard', 'surfboard', 'tennis racket', 'bottle', 'wine glass', 'cup',
//     'fork', 'knife', 'spoon', 'bowl', 'banana', 'apple', 'sandwich', 'orange',
//     'broccoli', 'carrot', 'hot dog', 'pizza', 'donut', 'cake', 'chair', 'couch',
//     'potted plant', 'bed', 'dining table', 'toilet', 'tv', 'laptop', 'mouse',
//     'remote', 'keyboard', 'cell phone', 'microwave', 'oven', 'toaster', 'sink',
//     'refrigerator', 'book', 'clock', 'vase', 'scissors', 'teddy bear', 'hair drier',
//     'toothbrush'
//   ];

//   useEffect(() => {
//     initializeTensorFlow();
//   }, []);

//   const initializeTensorFlow = async () => {
//     try {
//       // Wait for TensorFlow to initialize
//       await tf.ready();
//       console.log('TensorFlow.js initialized');
      
//       // Load a pre-trained model (MobileNet SSD)
//       // You can replace this URL with your own model
//       const modelUrl = 'https://tfhub.dev/tensorflow/tfjs-model/ssd_mobilenet_v2/1/default/1';
      
//       const loadedModel = await tf.loadGraphModel(modelUrl);
//       setModel(loadedModel);
//       setIsModelLoaded(true);
//       console.log('Model loaded successfully');
//     } catch (error) {
//       console.error('Error initializing TensorFlow:', error);
//       Alert.alert('Error', 'Failed to load object detection model');
//     }
//   };

//   const toggleCameraFacing = () => {
//     setFacing(current => (current === 'back' ? 'front' : 'back'));
//   };

//   const preprocessImage = (imageTensor: tf.Tensor3D): tf.Tensor4D => {
//     // Resize image to model input size (usually 300x300 for SSD MobileNet)
//     const resized = tf.image.resizeBilinear(imageTensor, [300, 300]);
    
//     // Normalize pixel values to [0, 1]
//     const normalized = resized.div(255.0);
    
//     // Add batch dimension
//     const batched = normalized.expandDims(0) as tf.Tensor4D;
    
//     return batched;
//   };

//   const postprocessDetections = (
//     boxes: tf.Tensor,
//     scores: tf.Tensor,
//     classes: tf.Tensor,
//     numDetections: tf.Tensor
//   ): DetectionResult[] => {
//     const boxesArray = boxes.dataSync() as Float32Array;
//     const scoresArray = scores.dataSync() as Float32Array;
//     const classesArray = classes.dataSync() as Float32Array;
//     const numDetectionsArray = numDetections.dataSync() as Float32Array;

//     const detectionResults: DetectionResult[] = [];
//     const numDet = numDetectionsArray[0];

//     for (let i = 0; i < numDet && i < 10; i++) { // Limit to top 10 detections
//       const score = scoresArray[i];
//       if (score > 0.5) { // Confidence threshold
//         const classIndex = Math.floor(classesArray[i]);
//         const className = classNames[classIndex] || 'Unknown';
        
//         const bbox = [
//           boxesArray[i * 4] * height,     // y1
//           boxesArray[i * 4 + 1] * width,  // x1
//           boxesArray[i * 4 + 2] * height, // y2
//           boxesArray[i * 4 + 3] * width,  // x2
//         ];

//         detectionResults.push({
//           class: className,
//           score: score,
//           bbox: bbox,
//         });
//       }
//     }

//     return detectionResults;
//   };

//   const runObjectDetection = async () => {
//     if (!cameraRef.current || !model || isDetecting) return;

//     setIsDetecting(true);
    
//     try {
//       // Take a picture
//       const photo = await cameraRef.current.takePictureAsync({
//         quality: 0.7,
//         base64: true,
//       });

//       if (!photo?.uri) {
//         throw new Error('Failed to capture image');
//       }

//       // Convert image to tensor
//       const response = await fetch(photo.uri);
//       const imageData = await response.arrayBuffer();
//       const imageTensor = decodeJpeg(new Uint8Array(imageData));

//       // Preprocess the image
//       const preprocessed = preprocessImage(imageTensor as tf.Tensor3D);

//       // Run inference
//       const predictions = await model.predict(preprocessed) as tf.Tensor[];

//       // Extract detection results
//       const boxes = predictions[0];      // Detection boxes
//       const scores = predictions[1];     // Detection scores
//       const classes = predictions[2];    // Detection classes
//       const numDetections = predictions[3]; // Number of detections

//       // Post-process detections
//       const detectionResults = postprocessDetections(boxes, scores, classes, numDetections);
//       setDetections(detectionResults);

//       // Clean up tensors
//       imageTensor.dispose();
//       preprocessed.dispose();
//       predictions.forEach(tensor => tensor.dispose());

//     } catch (error) {
//       console.error('Error during object detection:', error);
//       Alert.alert('Error', 'Failed to perform object detection');
//     } finally {
//       setIsDetecting(false);
//     }
//   };

//   if (!permission) {
//     return <View style={styles.container} />;
//   }

//   if (!permission.granted) {
//     return (
//       <View style={styles.container}>
//         <Text style={styles.message}>We need your permission to show the camera</Text>
//         <TouchableOpacity onPress={requestPermission} style={styles.button}>
//           <Text style={styles.buttonText}>Grant Permission</Text>
//         </TouchableOpacity>
//       </View>
//     );
//   }

//   return (
//     <View style={styles.container}>
//       <CameraView
//         ref={cameraRef}
//         style={styles.camera}
//         facing={facing}
//       >
//         <View style={styles.overlay}>
//           {/* Model status */}
//           <View style={styles.statusContainer}>
//             <Text style={styles.statusText}>
//               Model: {isModelLoaded ? 'Loaded ✅' : 'Loading...'}
//             </Text>
//           </View>

//           {/* Detection results */}
//           <View style={styles.detectionsContainer}>
//             {detections.map((detection, index) => (
//               <Text key={index} style={styles.detectionText}>
//                 {detection.class}: {(detection.score * 100).toFixed(1)}%
//               </Text>
//             ))}
//           </View>

//           {/* Controls */}
//           <View style={styles.controlsContainer}>
//             <TouchableOpacity 
//               style={styles.controlButton} 
//               onPress={toggleCameraFacing}
//             >
//               <Text style={styles.controlButtonText}>Flip Camera</Text>
//             </TouchableOpacity>
            
//             <TouchableOpacity
//               style={[
//                 styles.detectButton,
//                 (!isModelLoaded || isDetecting) && styles.detectButtonDisabled
//               ]}
//               onPress={runObjectDetection}
//               disabled={!isModelLoaded || isDetecting}
//             >
//               {isDetecting ? (
//                 <ActivityIndicator color="#fff" size="small" />
//               ) : (
//                 <Text style={styles.detectButtonText}>Detect Objects</Text>
//               )}
//             </TouchableOpacity>
//           </View>
//         </View>
//       </CameraView>
//     </View>
//   );
// }

// const styles = StyleSheet.create({
//   container: {
//     flex: 1,
//     backgroundColor: 'black',
//   },
//   message: {
//     textAlign: 'center',
//     paddingBottom: 10,
//     color: 'white',
//     fontSize: 16,
//   },
//   camera: {
//     flex: 1,
//   },
//   overlay: {
//     flex: 1,
//     backgroundColor: 'transparent',
//     justifyContent: 'space-between',
//   },
//   statusContainer: {
//     position: 'absolute',
//     top: 50,
//     left: 20,
//     right: 20,
//     backgroundColor: 'rgba(0, 0, 0, 0.5)',
//     padding: 10,
//     borderRadius: 8,
//   },
//   statusText: {
//     color: 'white',
//     fontSize: 14,
//     textAlign: 'center',
//   },
//   detectionsContainer: {
//     position: 'absolute',
//     top: 100,
//     left: 20,
//     right: 20,
//     backgroundColor: 'rgba(0, 0, 0, 0.7)',
//     padding: 15,
//     borderRadius: 8,
//     maxHeight: 200,
//   },
//   detectionText: {
//     color: 'white',
//     fontSize: 16,
//     marginVertical: 2,
//     fontWeight: '500',
//   },
//   controlsContainer: {
//     position: 'absolute',
//     bottom: 50,
//     left: 20,
//     right: 20,
//     flexDirection: 'row',
//     justifyContent: 'space-between',
//     alignItems: 'center',
//   },
//   controlButton: {
//     backgroundColor: 'rgba(255, 255, 255, 0.2)',
//     paddingHorizontal: 20,
//     paddingVertical: 12,
//     borderRadius: 25,
//   },
//   controlButtonText: {
//     color: 'white',
//     fontSize: 14,
//     fontWeight: '600',
//   },
//   detectButton: {
//     backgroundColor: '#007AFF',
//     paddingHorizontal: 30,
//     paddingVertical: 15,
//     borderRadius: 25,
//     minWidth: 140,
//     alignItems: 'center',
//   },
//   detectButtonDisabled: {
//     backgroundColor: 'rgba(0, 122, 255, 0.5)',
//   },
//   detectButtonText: {
//     color: 'white',
//     fontSize: 16,
//     fontWeight: 'bold',
//   },
//   button: {
//     backgroundColor: '#007AFF',
//     paddingHorizontal: 20,
//     paddingVertical: 12,
//     borderRadius: 8,
//     alignSelf: 'center',
//   },
//   buttonText: {
//     color: 'white',
//     fontSize: 16,
//     fontWeight: '600',
//   },
// });
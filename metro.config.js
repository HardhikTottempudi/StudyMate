const { getDefaultConfig } = require('expo/metro-config');

const config = getDefaultConfig(__dirname);

// Add support for TensorFlow.js model files and other assets
config.resolver.assetExts.push(
  // TensorFlow.js model files
  'bin', 
  'txt', 
  'tflite',
  // Additional image formats that might be needed
  'jpg', 
  'png', 
  'json'
);

// Ensure these file types are not treated as source code
config.resolver.sourceExts = config.resolver.sourceExts.filter(ext => !config.resolver.assetExts.includes(ext));

module.exports = config;
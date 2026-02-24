import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Animated,
  Dimensions,
  BackHandler,
  Alert,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { SafeAreaView } from 'react-native-safe-area-context';
import NativeAppBlocker from '../services/nativeAppBlocker';

const { width, height } = Dimensions.get('window');

interface BlockingScreenProps {
  blockedAppName: string;
  onEndStudySession: () => void;
  onBackToStudy: () => void;
  visible: boolean;
}

export default function BlockingScreen({ 
  blockedAppName, 
  onEndStudySession, 
  onBackToStudy, 
  visible 
}: BlockingScreenProps) {
  const [pulseAnim] = useState(new Animated.Value(1));
  const [shakeAnim] = useState(new Animated.Value(0));

  useEffect(() => {
    if (visible) {
      // Start pulse animation
      const pulse = Animated.loop(
        Animated.sequence([
          Animated.timing(pulseAnim, {
            toValue: 1.2,
            duration: 1000,
            useNativeDriver: true,
          }),
          Animated.timing(pulseAnim, {
            toValue: 1,
            duration: 1000,
            useNativeDriver: true,
          }),
        ])
      );

      pulse.start();

      // Prevent back button
      const backHandler = BackHandler.addEventListener('hardwareBackPress', () => {
        shake();
        return true; // Prevent default back behavior
      });

      return () => {
        pulse.stop();
        backHandler.remove();
      };
    }
  }, [visible]);

  const shake = () => {
    Animated.sequence([
      Animated.timing(shakeAnim, { toValue: 10, duration: 50, useNativeDriver: true }),
      Animated.timing(shakeAnim, { toValue: -10, duration: 50, useNativeDriver: true }),
      Animated.timing(shakeAnim, { toValue: 10, duration: 50, useNativeDriver: true }),
      Animated.timing(shakeAnim, { toValue: 0, duration: 50, useNativeDriver: true }),
    ]).start();
  };

  const handleEndStudySession = () => {
    Alert.alert(
      'End Study Session?',
      'Are you sure you want to end your study session? This will unblock all apps.',
      [
        { text: 'Cancel', style: 'cancel' },
        { text: 'End Session', style: 'destructive', onPress: onEndStudySession },
      ]
    );
  };

  if (!visible) return null;

  return (
    <SafeAreaView style={styles.container}>
      <LinearGradient
        colors={['#E74C3C', '#C0392B', '#A93226']}
        style={styles.gradient}
      >
        <Animated.View 
          style={[
            styles.content,
            { transform: [{ translateX: shakeAnim }] }
          ]}
        >
          {/* Blocked Icon */}
          <Animated.View 
            style={[
              styles.iconContainer,
              { transform: [{ scale: pulseAnim }] }
            ]}
          >
            <Ionicons name="shield-outline" size={100} color="#FFFFFF" />
            <View style={styles.blockOverlay}>
              <Ionicons name="close" size={40} color="#E74C3C" />
            </View>
          </Animated.View>

          {/* Title */}
          <Text style={styles.title}>App Blocked!</Text>
          
          {/* Blocked App Name */}
          <Text style={styles.appName}>{blockedAppName}</Text>
          
          {/* Message */}
          <Text style={styles.message}>
            This app is blocked during your study session.{'\n'}
            Stay focused and keep studying! 📚
          </Text>

          {/* Motivational Quote */}
          <View style={styles.quoteContainer}>
            <Text style={styles.quote}>
              "Success is the sum of small efforts repeated day in and day out."
            </Text>
            <Text style={styles.quoteAuthor}>- Robert Collier</Text>
          </View>

          {/* Action Buttons */}
          <View style={styles.buttonContainer}>
            <TouchableOpacity 
              style={styles.primaryButton} 
              onPress={onBackToStudy}
              activeOpacity={0.8}
            >
              <Ionicons name="book" size={24} color="#FFFFFF" />
              <Text style={styles.primaryButtonText}>Back to Study</Text>
            </TouchableOpacity>

            <TouchableOpacity 
              style={styles.secondaryButton} 
              onPress={handleEndStudySession}
              activeOpacity={0.8}
            >
              <Ionicons name="stop-circle" size={20} color="#E74C3C" />
              <Text style={styles.secondaryButtonText}>End Session</Text>
            </TouchableOpacity>
          </View>

          {/* Warning Text */}
          <Text style={styles.warningText}>
            ⚠️ Pressing back or trying to close this screen won't work.{'\n'}
            You must choose one of the options above.
          </Text>
        </Animated.View>
      </LinearGradient>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    zIndex: 9999,
  },
  gradient: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  content: {
    alignItems: 'center',
    paddingHorizontal: 30,
    width: '100%',
  },
  iconContainer: {
    position: 'relative',
    marginBottom: 30,
  },
  blockOverlay: {
    position: 'absolute',
    top: 30,
    right: 10,
    backgroundColor: '#FFFFFF',
    borderRadius: 25,
    width: 50,
    height: 50,
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.3,
    shadowRadius: 4,
    elevation: 5,
  },
  title: {
    fontSize: 36,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 10,
    textAlign: 'center',
  },
  appName: {
    fontSize: 24,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 20,
    textAlign: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    paddingHorizontal: 20,
    paddingVertical: 8,
    borderRadius: 20,
  },
  message: {
    fontSize: 18,
    color: '#FFFFFF',
    textAlign: 'center',
    marginBottom: 30,
    lineHeight: 26,
    opacity: 0.9,
  },
  quoteContainer: {
    backgroundColor: 'rgba(255, 255, 255, 0.15)',
    borderRadius: 15,
    padding: 20,
    marginBottom: 40,
    borderLeftWidth: 4,
    borderLeftColor: '#FFFFFF',
  },
  quote: {
    fontSize: 16,
    color: '#FFFFFF',
    fontStyle: 'italic',
    textAlign: 'center',
    marginBottom: 8,
  },
  quoteAuthor: {
    fontSize: 14,
    color: '#FFFFFF',
    textAlign: 'right',
    opacity: 0.8,
  },
  buttonContainer: {
    width: '100%',
    alignItems: 'center',
    marginBottom: 30,
  },
  primaryButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    paddingHorizontal: 40,
    paddingVertical: 16,
    borderRadius: 30,
    marginBottom: 15,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 8,
    minWidth: 200,
    justifyContent: 'center',
  },
  primaryButtonText: {
    color: '#E74C3C',
    fontSize: 18,
    fontWeight: '600',
    marginLeft: 10,
  },
  secondaryButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'transparent',
    paddingHorizontal: 30,
    paddingVertical: 12,
    borderRadius: 25,
    borderWidth: 2,
    borderColor: '#FFFFFF',
    minWidth: 160,
    justifyContent: 'center',
  },
  secondaryButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '500',
    marginLeft: 8,
  },
  warningText: {
    fontSize: 12,
    color: '#FFFFFF',
    textAlign: 'center',
    opacity: 0.7,
    lineHeight: 18,
  },
});

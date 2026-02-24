import { Ionicons } from '@expo/vector-icons';
import { useAudioPlayer, useAudioPlayerStatus } from 'expo-audio';
import { Audio } from 'expo-av';
import { Camera } from 'expo-camera';
import { LinearGradient } from 'expo-linear-gradient';
import * as Linking from 'expo-linking';
import { router } from 'expo-router';
import React, { useEffect, useRef, useState } from 'react';
import {
  Alert,
  Dimensions,
  Image,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
// Removed analytics imports - moved to study session page
const { width } = Dimensions.get('window');

export default function DashboardScreen() {
  const [currentCarouselIndex, setCurrentCarouselIndex] = useState(0);
  const [isPlayingSound, setIsPlayingSound] = useState(false);
  const [isAudioReady, setIsAudioReady] = useState(false);
  const carouselScrollRef = useRef<ScrollView>(null);
  
  // Removed study data state - moved to study session page

  // Initialize audio player
  const player = useAudioPlayer(require('../../assets/sounds/rain.mp3'));
  const status = useAudioPlayerStatus(player);
  
  const inspirationalImages = [
    require('../../assets/images/lock_in.jpg'),
    require('../../assets/images/insp1.jpg'),
    require('../../assets/images/inspo2.jpg'),
  ];

  const performanceData = [
    { title: 'Hours Completed', value: '10 Hrs', color: '#4CAF50' },
    { title: 'Goals Completed', value: '2/5', color: '#2196F3' },
    { title: 'Focus Time', value: '2 Hrs', color: '#FF9800' },
    { title: 'Study Streak', value: '7 Days', color: '#9C27B0', img: require('../../assets/images/chart.png') },
  ];

  // Setup audio player
  useEffect(() => {
    const setupAudio = async () => {
      try {
        console.log('🎵 Starting audio setup for platform:', Platform.OS);
        
        // Configure audio session for iOS with more aggressive settings
        if (Platform.OS === 'ios') {
          await Audio.setAudioModeAsync({
            allowsRecordingIOS: false,
            playsInSilentModeIOS: true,
            staysActiveInBackground: true,
            shouldDuckAndroid: false,
            playThroughEarpieceAndroid: false,
          });
          console.log('📱 iOS audio mode configured');
        }
        
        // Request audio permissions
        const { status } = await Audio.requestPermissionsAsync();
        console.log('🔐 Audio permissions status:', status);
        if (status !== 'granted') {
          Alert.alert('Permission Required', 'Audio permission is needed to play sounds');
          return;
        }
        
        // Configure audio player with maximum settings
        player.loop = true;
        player.volume = 1.0; // Maximum volume for testing
        
        // Wait longer for iOS to be ready
        await new Promise(resolve => setTimeout(resolve, 500));
        setIsAudioReady(true);
      
        
      } catch (error) {
        console.error('❌ Failed to setup audio player:', error);
      }
    };
    
    setupAudio();
  }, []);

  // Cleanup
  useEffect(() => {
    return () => {
      try {
        if (status.playing) {
          player.pause();
        }
        player.remove();
      } catch (error) {
        console.error('Error cleaning up audio player:', error);
      }
    };
  }, []);

  const handlePlayRainSound = async () => {
    if (!isAudioReady) {
      Alert.alert('Audio Not Ready', 'Please wait for audio to load');
      return;
    }

    try {
      
      if (status.playing) {
        await player.pause();
        setIsPlayingSound(false);
        console.log('Audio paused');
      } else {
        await player.play();
        setIsPlayingSound(true);
        console.log('Audio playing');
      }
    } catch (error) {
      console.error('Audio playback error:', error);
      Alert.alert('Audio Error', `Could not play rain sound:`);
    }
  };

  const handleCameraDetection = async () => {
    const { status } = await Camera.requestCameraPermissionsAsync();
    if (status === 'granted') {
      // Open external camera detection URL (as in original Kotlin app)
      const url = 'https://demo.roboflow.com/drowsiness-sgvf2-tixi5/1?publishable_key=rf_JULDEIHODmWX9hxVH5cPND0AiSs2';
      await Linking.openURL(url);
    } else {
      Alert.alert('Permission Required', 'Camera permission is needed for distraction detection');
    }
  };

  // Remove unused toggleAppBlocking function since we removed app blocking

  const renderCarouselIndicators = () => {
    return (
      <View style={styles.indicatorContainer}>
        {inspirationalImages.map((_, index) => (
          <View
            key={index}
            style={[
              styles.indicator,
              { backgroundColor: currentCarouselIndex === index ? '#667eea' : '#CCC' }
            ]}
          />
        ))}
      </View>
    );
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.scrollView} showsVerticalScrollIndicator={false}>
        {/* Header */}
        <View style={styles.header}>
          <Text style={styles.headerTitle}>Dashboard</Text>
          <TouchableOpacity style={styles.settingsButton}>
            <Ionicons name="settings-outline" size={24} color="#667eea" />
          </TouchableOpacity>
        </View>

        {/* Inspirational Carousel */}
        <View style={styles.carouselSection}>
          <ScrollView
            ref={carouselScrollRef}
            horizontal
            pagingEnabled
            showsHorizontalScrollIndicator={false}
            onMomentumScrollEnd={(event) => {
              const index = Math.round(event.nativeEvent.contentOffset.x / width);
              setCurrentCarouselIndex(index);
            }}
            style={styles.carousel}
          >
            {inspirationalImages.map((image, index) => (
              <Image key={index} source={image} style={styles.carouselImage} />
            ))}
          </ScrollView>
          {renderCarouselIndicators()}
        </View>

        {/* Performance Tracker */}
        <View style={styles.performanceSection}>
          <Text style={styles.sectionTitle}>Performance Metrics</Text>
          <ScrollView horizontal showsHorizontalScrollIndicator={false}>
            <View style={styles.performanceContainer}>
            {performanceData.map((item, index) => (
                  <LinearGradient
                    key={index}
                    colors={['#FFFFFF', '#F8F9FA']}
                    style={[
                      styles.performanceCard,
                      // Adjust width based on content
                      { width: item.img ? 160 : 120 }
                    ]}
                  >
                    {/* <View style={[styles.performanceIndicator, { backgroundColor: item.color }]} /> */}
                    <Text style={styles.performanceTitle}>{item.title}</Text>
                    <Text style={styles.performanceValue}>{item.value}</Text>
                    {item.img && (
                      <Image 
                        source={item.img} 
                        style={styles.performanceImage}
                        //resizeMode="contain"
                      />
                    )}
                  </LinearGradient>
                ))}
            </View>
          </ScrollView>
        </View>


        {/* Quick Actions */}
        <View style={styles.featuresSection}>
          <Text style={styles.sectionTitle}>Quick Actions</Text>
          <View style={styles.featureRow}>
            <TouchableOpacity style={styles.featureCard} onPress={() => router.push('/study-session')}>
              <LinearGradient colors={['#667eea', '#764ba2']} style={styles.featureGradient}>
                <Ionicons name="play-circle-outline" size={32} color="#FFFFFF" />
                <Text style={styles.featureTitle}>Start Session</Text>
                <Text style={styles.featureSubtitle}>Begin studying</Text>
              </LinearGradient>
            </TouchableOpacity>

            <TouchableOpacity style={styles.featureCard} onPress={handleCameraDetection}>
              <LinearGradient colors={['#4CAF50', '#45a049']} style={styles.featureGradient}>
                <Image source={require('../../assets/images/camera.png')} style={styles.featureIcon} />
                <Text style={styles.featureTitle}>Focus Monitor</Text>
                <Text style={styles.featureSubtitle}>Camera detection</Text>
              </LinearGradient>
            </TouchableOpacity>
          </View>
        </View>

        {/* Rain Sound Player */}
        <View style={styles.soundSection}>
          <Text style={styles.sectionTitle}>Focus Sounds</Text>
          <TouchableOpacity style={styles.soundCard} onPress={handlePlayRainSound}>
            <Image source={require('../../assets/images/rain.png')} style={styles.soundBackground} />
            <LinearGradient 
              colors={['rgba(0,0,0,0.3)', 'rgba(0,0,0,0.7)']} 
              style={styles.soundOverlay}
            >
              <View style={styles.soundContent}>
                <Text style={styles.soundTitle}>Rain & Thunder</Text>
                <Text style={styles.soundSubtitle}>20hr of Focus Sounds</Text>
                <TouchableOpacity style={styles.playButton} onPress={handlePlayRainSound}>
                  <Ionicons 
                    name={status.playing ? "pause" : "play"} 
                    size={24} 
                    color="#FFFFFF" 
                  />
                </TouchableOpacity>
              </View>
            </LinearGradient>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8F9FA',
  },
  scrollView: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 16,
  },
  headerTitle: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#2C3E50',
  },
  settingsButton: {
    padding: 8,
  },
  carouselSection: {
    marginBottom: 0,
  },
  carousel: {
    height: 180,
  },
  carouselImage: {
    width: width - 32,
    height: 150,
    marginHorizontal: 16,
    borderRadius: 12,
    resizeMode: 'cover',
  },
  indicatorContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 12,
  },
  indicator: {
    width: 8,
    height: 8,
    borderRadius: 4,
    marginHorizontal: 4,
  },
  performanceSection: {
    marginBottom: 24,
    backgroundColor: '#a571a8ff',
    paddingVertical: 16,
    borderRadius: 12,
    margin: 16,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: '600',
    color: '#2C3E50',
    marginHorizontal: 20,
    marginBottom: 16,
  },
  performanceContainer: {
    flexDirection: 'row',
    paddingHorizontal: 20,
    //height: "60%", // Fixed height for consistency
  },
  performanceCard: {
  // Remove fixed dimensions, make it flexible based on content
  minWidth: 120, // Minimum width for cards without images
  maxWidth: 160, // Maximum width for cards with images
  minHeight: 100, // Minimum height to ensure consistency
  borderRadius: 12,
  padding: 16,
  marginRight: 12,
  shadowColor: '#000',
  shadowOffset: { width: 0, height: 2 },
  shadowOpacity: 0.1,
  shadowRadius: 8,
  elevation: 4,
  alignSelf: 'flex-start', // Allow height to adjust to content
},
performanceImage: {
  height: 150,
  width: '100%',
  resizeMode: 'contain',
  alignSelf: 'center',
  marginTop: 8,
},
  performanceIndicator: {
    width: 4,
    height: 20,
    borderRadius: 2,
    marginBottom: 8,
  },
  performanceTitle: {
    fontSize: 12,
    color: '#7F8C8D',
    marginBottom: 4,
  },
  performanceValue: {
    fontSize: 16,
    fontWeight: '600',
    color: '#2C3E50',
  },
  featuresSection: {
    marginBottom: 24,
    paddingHorizontal: 20,
  },
  featureRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  featureCard: {
    flex: 1,
    marginHorizontal: 6,
  },
  featureGradient: {
    height: 120,
    borderRadius: 12,
    padding: 16,
    justifyContent: 'center',
    alignItems: 'center',
  },
  featureIcon: {
    width: 32,
    height: 32,
    marginBottom: 8,
    tintColor: '#FFFFFF',
  },
  featureTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#FFFFFF',
    textAlign: 'center',
    marginBottom: 4,
  },
  featureSubtitle: {
    fontSize: 12,
    color: '#FFFFFF',
    opacity: 0.8,
    textAlign: 'center',
  },
  soundSection: {
    marginBottom: 100,
    paddingHorizontal: 20,
  },
  soundCard: {
    height: 150,
    borderRadius: 12,
    overflow: 'hidden',
  },
  soundBackground: {
    width: '100%',
    height: '100%',
    position: 'absolute',
  },
  soundOverlay: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  soundContent: {
    alignItems: 'center',
  },
  soundTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 4,
  },
  soundSubtitle: {
    fontSize: 14,
    color: '#FFFFFF',
    opacity: 0.8,
    marginBottom: 16,
  },
  playButton: {
    width: 50,
    height: 50,
    borderRadius: 25,
    backgroundColor: 'rgba(255, 255, 255, 0.3)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  // Analytics section styles
  analyticsSection: {
    marginBottom: 24,
    paddingHorizontal: 20,
  },
  // Goals section styles
  goalsSection: {
    marginBottom: 24,
    paddingHorizontal: 20,
  },
  goalProgressContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  goalDetails: {
    marginLeft: 24,
    flex: 1,
  },
  goalDetailTitle: {
    fontSize: 12,
    color: '#7F8C8D',
    marginBottom: 4,
  },
  goalDetailValue: {
    fontSize: 16,
    fontWeight: '600',
    color: '#2C3E50',
    marginBottom: 12,
  },
  // Insights section styles
  insightsSection: {
    marginBottom: 24,
    paddingHorizontal: 20,
  },
  insightGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
  },
  insightCard: {
    width: (width - 56) / 2,
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  insightTitle: {
    fontSize: 12,
    color: '#7F8C8D',
    textAlign: 'center',
    marginTop: 8,
    marginBottom: 4,
  },
  insightValue: {
    fontSize: 16,
    fontWeight: '600',
    color: '#2C3E50',
    textAlign: 'center',
  },
  // Achievements section styles
  achievementsSection: {
    marginBottom: 24,
    paddingHorizontal: 20,
  },
  achievementContainer: {
    flexDirection: 'row',
    paddingHorizontal: 20,
  },
  achievementCard: {
    width: 120,
    marginRight: 12,
  },
  achievementGradient: {
    height: 100,
    borderRadius: 12,
    padding: 12,
    justifyContent: 'center',
    alignItems: 'center',
  },
  achievementTitle: {
    fontSize: 12,
    fontWeight: '600',
    textAlign: 'center',
    marginTop: 6,
  },
  achievementProgress: {
    fontSize: 10,
    textAlign: 'center',
    marginTop: 4,
  },
});

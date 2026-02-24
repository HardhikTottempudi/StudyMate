import React, { useState, useEffect, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Alert,
  Dimensions,
  ScrollView,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { Audio } from 'expo-audio';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { BarChart, LineChart, CircularProgress, StudyHeatmap } from '@/components/StudyCharts';
import studyDataService, { DailyStudyData, StudyGoal, Achievement, WeeklyStats } from '@/services/studyDataService';

const { width } = Dimensions.get('window');

// Common apps that students might want to block
const COMMON_APPS = [
  { name: 'Instagram', icon: 'logo-instagram', package: 'com.instagram.android', blocked: false },
  { name: 'Facebook', icon: 'logo-facebook', package: 'com.facebook.katana', blocked: false },
  { name: 'Twitter/X', icon: 'logo-twitter', package: 'com.twitter.android', blocked: false },
  { name: 'TikTok', icon: 'musical-notes', package: 'com.ss.android.ugc.trill', blocked: false },
  { name: 'YouTube', icon: 'logo-youtube', package: 'com.google.android.youtube', blocked: false },
  { name: 'Snapchat', icon: 'camera', package: 'com.snapchat.android', blocked: false },
  { name: 'WhatsApp', icon: 'logo-whatsapp', package: 'com.whatsapp', blocked: false },
  { name: 'Telegram', icon: 'paper-plane', package: 'org.telegram.messenger', blocked: false },
  { name: 'Netflix', icon: 'tv', package: 'com.netflix.mediaclient', blocked: false },
  { name: 'Spotify', icon: 'musical-note', package: 'com.spotify.music', blocked: false },
  { name: 'Games', icon: 'game-controller', package: 'games.*', blocked: false },
  { name: 'Chrome', icon: 'globe', package: 'com.android.chrome', blocked: false },
];

export default function StudySessionScreen() {
  const [isStudying, setIsStudying] = useState(false);
  const [studyTime, setStudyTime] = useState(0); // in seconds
  const [breakTime, setBreakTime] = useState(0);
  const [isBreak, setIsBreak] = useState(false);
  const [totalStudyTime, setTotalStudyTime] = useState(0);
  const [blockedApps, setBlockedApps] = useState(COMMON_APPS);
  const [showAppSelector, setShowAppSelector] = useState(false);
  const intervalRef = useRef<NodeJS.Timeout | null>(null);
  const [sound, setSound] = useState<Audio.Sound | null>(null);
  
  // Analytics data state
  const [todayData, setTodayData] = useState<DailyStudyData | null>(null);
  const [weeklyStats, setWeeklyStats] = useState<WeeklyStats | null>(null);
  const [studyGoals, setStudyGoals] = useState<StudyGoal[]>([]);
  const [achievements, setAchievements] = useState<Achievement[]>([]);
  const [studyStreak, setStudyStreak] = useState(0);

  useEffect(() => {
    loadTotalStudyTime();
    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
      if (sound) {
        sound.unloadAsync();
      }
    };
  }, []);

  const loadTotalStudyTime = async () => {
    try {
      const stored = await AsyncStorage.getItem('totalStudyTime');
      if (stored) {
        setTotalStudyTime(parseInt(stored));
      }
    } catch (error) {
      console.log('Error loading study time:', error);
    }
  };

  const saveTotalStudyTime = async (time: number) => {
    try {
      await AsyncStorage.setItem('totalStudyTime', time.toString());
    } catch (error) {
      console.log('Error saving study time:', error);
    }
  };

  const startTimer = () => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
    }
    
    intervalRef.current = setInterval(() => {
      if (isBreak) {
        setBreakTime(prev => {
          if (prev <= 1) {
            completeBreak();
            return 0;
          }
          return prev - 1;
        });
      } else {
        setStudyTime(prev => prev + 1);
      }
    }, 1000);
  };

  const toggleAppBlocking = (index: number) => {
    setBlockedApps(prev => prev.map((app, i) => 
      i === index ? { ...app, blocked: !app.blocked } : app
    ));
  };

  const getBlockedAppsCount = () => {
    return blockedApps.filter(app => app.blocked).length;
  };

  const startStudySession = () => {
    const selectedApps = blockedApps.filter(app => app.blocked);
    if (selectedApps.length === 0) {
      Alert.alert(
        'No Apps Selected',
        'Please select at least one app to block during your study session.',
        [{ text: 'OK' }]
      );
      return;
    }
    
    setIsStudying(true);
    setStudyTime(0);
    setIsBreak(false);
    startTimer();
    playFocusSound();
    
    // Here you would implement actual app blocking functionality
    Alert.alert(
      'Study Session Started!',
      `Blocking ${selectedApps.length} app(s): ${selectedApps.map(app => app.name).join(', ')}`,
      [{ text: 'Focus!' }]
    );
  };

  const pauseStudySession = () => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
    }
    stopFocusSound();
    
    Alert.alert(
      'Study Session Paused',
      'What would you like to do?',
      [
        { text: 'Resume', onPress: resumeStudySession },
        { text: 'End Session', onPress: endStudySession },
      ]
    );
  };

  const resumeStudySession = () => {
    startTimer();
    playFocusSound();
  };

  const endStudySession = () => {
    setIsStudying(false);
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
    }
    
    const newTotal = totalStudyTime + studyTime;
    setTotalStudyTime(newTotal);
    saveTotalStudyTime(newTotal);
    
    Alert.alert(
      'Study Session Complete!',
      `Great job! You studied for ${Math.floor(studyTime / 60)} minutes. All blocked apps are now available.`,
      [
        { text: 'Take Break', onPress: startBreak },
        { text: 'Continue', onPress: () => setStudyTime(0) },
      ]
    );
    stopFocusSound();
  };

  const startBreak = () => {
    setIsBreak(true);
    setBreakTime(5 * 60); // 5 minute break
    startTimer();
  };

  const completeBreak = () => {
    setIsBreak(false);
    setBreakTime(0);
    Alert.alert('Break Over!', 'Ready to get back to studying?', [
      { text: 'Start Studying', onPress: startStudySession },
      { text: 'Not Yet', onPress: () => {} },
    ]);
  };

  const playFocusSound = async () => {
    try {
      const { sound: newSound } = await Audio.Sound.createAsync(
        { uri: 'https://www.soundjay.com/misc/sounds/bell-ringing-05.mp3' },
        { shouldPlay: true, volume: 0.3 }
      );
      setSound(newSound);
    } catch (error) {
      console.log('Error playing sound:', error);
    }
  };

  const stopFocusSound = async () => {
    if (sound) {
      await sound.stopAsync();
      await sound.unloadAsync();
      setSound(null);
    }
  };

  const formatTime = (seconds: number) => {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes.toString().padStart(2, '0')}:${remainingSeconds.toString().padStart(2, '0')}`;
  };

  const formatHours = (seconds: number) => {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    return `${hours}h ${minutes}m`;
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.scrollView} showsVerticalScrollIndicator={false}>
        <View style={styles.header}>
          <Text style={styles.headerTitle}>Study Session</Text>
          <View style={styles.totalTimeContainer}>
            <Ionicons name="time-outline" size={16} color="#667eea" />
            <Text style={styles.totalTimeText}>Total: {formatHours(totalStudyTime)}</Text>
          </View>
        </View>

        <View style={styles.timerSection}>
          <LinearGradient
            colors={isStudying ? ['#667eea', '#764ba2'] : ['#95A5A6', '#7F8C8D']}
            style={styles.timerCard}
          >
            <Text style={styles.timerLabel}>
              {isBreak ? 'Break Time' : 'Study Time'}
            </Text>
            <Text style={styles.timerDisplay}>
              {isBreak ? formatTime(breakTime) : formatTime(studyTime)}
            </Text>
            <View style={styles.timerButtons}>
              {!isStudying ? (
                <TouchableOpacity style={styles.startButton} onPress={startStudySession}>
                  <Ionicons name="play" size={32} color="#FFFFFF" />
                  <Text style={styles.buttonText}>Start</Text>
                </TouchableOpacity>
              ) : (
                <View style={styles.activeButtons}>
                  <TouchableOpacity style={styles.pauseButton} onPress={pauseStudySession}>
                    <Ionicons name="pause" size={24} color="#FFFFFF" />
                    <Text style={styles.buttonTextSmall}>Pause</Text>
                  </TouchableOpacity>
                  <TouchableOpacity style={styles.endButton} onPress={endStudySession}>
                    <Ionicons name="stop" size={24} color="#FFFFFF" />
                    <Text style={styles.buttonTextSmall}>End</Text>
                  </TouchableOpacity>
                </View>
              )}
            </View>
          </LinearGradient>
        </View>

        {!isStudying && (
          <View style={styles.appBlockingSection}>
            <View style={styles.appBlockingHeader}>
              <Text style={styles.sectionTitle}>Select Apps to Block</Text>
              <Text style={styles.appBlockingSubtitle}>
                {getBlockedAppsCount()} app(s) selected
              </Text>
            </View>
            <View style={styles.appsGrid}>
              {blockedApps.map((app, index) => (
                <TouchableOpacity
                  key={index}
                  style={[
                    styles.appCard,
                    app.blocked && styles.appCardSelected
                  ]}
                  onPress={() => toggleAppBlocking(index)}
                >
                  <Ionicons 
                    name={app.icon as any} 
                    size={24} 
                    color={app.blocked ? '#FFFFFF' : '#667eea'} 
                  />
                  <Text style={[
                    styles.appName,
                    app.blocked && styles.appNameSelected
                  ]}>
                    {app.name}
                  </Text>
                  {app.blocked && (
                    <Ionicons 
                      name="checkmark-circle" 
                      size={16} 
                      color="#FFFFFF" 
                      style={styles.checkIcon}
                    />
                  )}
                </TouchableOpacity>
              ))}
            </View>
          </View>
        )}

        <View style={styles.blockingSection}>
          <Text style={styles.sectionTitle}>App Blocking Status</Text>
          <LinearGradient
            colors={isStudying ? ['#E74C3C', '#C0392B'] : ['#95A5A6', '#7F8C8D']}
            style={styles.blockingCard}
          >
            <View style={styles.blockingContent}>
              <Ionicons 
                name={isStudying ? "shield-checkmark" : "shield-outline"} 
                size={32} 
                color="#FFFFFF" 
              />
              <View style={styles.blockingText}>
                <Text style={styles.blockingTitle}>
                  {isStudying ? 'Apps Blocked' : 'Apps Available'}
                </Text>
                <Text style={styles.blockingSubtitle}>
                  {isStudying 
                    ? `${getBlockedAppsCount()} apps are currently blocked` 
                    : 'Start studying to block selected apps'
                  }
                </Text>
              </View>
            </View>
          </LinearGradient>
        </View>

        <View style={styles.statsSection}>
          <Text style={styles.sectionTitle}>Today's Progress</Text>
          <View style={styles.statsGrid}>
            <View style={styles.statCard}>
              <Text style={styles.statValue}>{Math.floor(studyTime / 60)}</Text>
              <Text style={styles.statLabel}>Minutes</Text>
            </View>
            <View style={styles.statCard}>
              <Text style={styles.statValue}>3</Text>
              <Text style={styles.statLabel}>Sessions</Text>
            </View>
            <View style={styles.statCard}>
              <Text style={styles.statValue}>7</Text>
              <Text style={styles.statLabel}>Day Streak</Text>
            </View>
          </View>
        </View>

        {/* Analytics Sections */}
        <View style={styles.analyticsSection}>
          <Text style={styles.sectionTitle}>Weekly Study Progress</Text>
          <BarChart 
            data={[
              {label: 'Mon', value: 120, color: '#667eea'},
              {label: 'Tue', value: 90, color: '#667eea'},
              {label: 'Wed', value: 150, color: '#667eea'},
              {label: 'Thu', value: 80, color: '#667eea'},
              {label: 'Fri', value: 100, color: '#667eea'},
              {label: 'Sat', value: 60, color: '#667eea'},
              {label: 'Sun', value: 140, color: '#667eea'}
            ]}
            height={160}
            showValues={true}
          />
        </View>

        <View style={styles.goalsSection}>
          <Text style={styles.sectionTitle}>Study Goals</Text>
          <View style={styles.goalProgressContainer}>
            <CircularProgress 
              progress={65}
              size={100}
              color="#667eea"
              title="Daily Goal"
            />
            <View style={styles.goalDetails}>
              <Text style={styles.goalDetailTitle}>Daily Target</Text>
              <Text style={styles.goalDetailValue}>2h 0m</Text>
              <Text style={styles.goalDetailTitle}>Completed</Text>
              <Text style={styles.goalDetailValue}>1h 18m</Text>
            </View>
          </View>
        </View>

        <View style={styles.insightsSection}>
          <Text style={styles.sectionTitle}>Study Insights</Text>
          <View style={styles.insightGrid}>
            <View style={styles.insightCard}>
              <Ionicons name="time-outline" size={24} color="#4CAF50" />
              <Text style={styles.insightTitle}>Total Study Time</Text>
              <Text style={styles.insightValue}>24h 15m</Text>
            </View>
            <View style={styles.insightCard}>
              <Ionicons name="trending-up-outline" size={24} color="#2196F3" />
              <Text style={styles.insightTitle}>Best Session</Text>
              <Text style={styles.insightValue}>2h 30m</Text>
            </View>
            <View style={styles.insightCard}>
              <Ionicons name="calendar-outline" size={24} color="#FF9800" />
              <Text style={styles.insightTitle}>Sessions This Week</Text>
              <Text style={styles.insightValue}>12</Text>
            </View>
            <View style={styles.insightCard}>
              <Ionicons name="star-outline" size={24} color="#9C27B0" />
              <Text style={styles.insightTitle}>Focus Average</Text>
              <Text style={styles.insightValue}>8.5/10</Text>
            </View>
          </View>
        </View>

        <View style={styles.achievementsSection}>
          <Text style={styles.sectionTitle}>Recent Achievements</Text>
          <ScrollView horizontal showsHorizontalScrollIndicator={false}>
            <View style={styles.achievementContainer}>
              <View style={styles.achievementCard}>
                <LinearGradient
                  colors={['#4CAF50', '#45a049']}
                  style={styles.achievementGradient}
                >
                  <Ionicons name="play-circle" size={28} color="#FFFFFF" />
                  <Text style={styles.achievementTitle}>First Steps</Text>
                  <Text style={styles.achievementProgress}>1/1</Text>
                </LinearGradient>
              </View>
              <View style={styles.achievementCard}>
                <LinearGradient
                  colors={['#E0E0E0', '#BDBDBD']}
                  style={styles.achievementGradient}
                >
                  <Ionicons name="time" size={28} color="#757575" />
                  <Text style={[styles.achievementTitle, {color: '#757575'}]}>Hour Hero</Text>
                  <Text style={[styles.achievementProgress, {color: '#757575'}]}>45/60</Text>
                </LinearGradient>
              </View>
              <View style={styles.achievementCard}>
                <LinearGradient
                  colors={['#4CAF50', '#45a049']}
                  style={styles.achievementGradient}
                >
                  <Ionicons name="calendar" size={28} color="#FFFFFF" />
                  <Text style={styles.achievementTitle}>Week Warrior</Text>
                  <Text style={styles.achievementProgress}>7/7</Text>
                </LinearGradient>
              </View>
            </View>
          </ScrollView>
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
  totalTimeContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  totalTimeText: {
    marginLeft: 4,
    fontSize: 14,
    color: '#667eea',
    fontWeight: '500',
  },
  timerSection: {
    paddingHorizontal: 20,
    marginBottom: 24,
  },
  timerCard: {
    borderRadius: 20,
    padding: 32,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 8,
  },
  timerLabel: {
    fontSize: 18,
    color: '#FFFFFF',
    opacity: 0.9,
    marginBottom: 8,
  },
  timerDisplay: {
    fontSize: 48,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 24,
    fontFamily: 'monospace',
  },
  timerButtons: {
    flexDirection: 'row',
  },
  startButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 25,
  },
  pauseButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 25,
  },
  buttonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
    marginLeft: 8,
  },
  durationSection: {
    paddingHorizontal: 20,
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: '600',
    color: '#2C3E50',
    marginBottom: 16,
  },
  durationGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
  },
  durationCard: {
    width: (width - 56) / 2,
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    alignItems: 'center',
    borderWidth: 2,
    borderColor: 'transparent',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  selectedDuration: {
    borderColor: '#667eea',
    backgroundColor: '#F0F4FF',
  },
  durationText: {
    fontSize: 16,
    fontWeight: '500',
    color: '#2C3E50',
  },
  selectedDurationText: {
    color: '#667eea',
    fontWeight: '600',
  },
  blockingSection: {
    paddingHorizontal: 20,
    marginBottom: 24,
  },
  blockingCard: {
    borderRadius: 12,
    padding: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 8,
    elevation: 5,
  },
  blockingContent: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  blockingText: {
    marginLeft: 16,
    flex: 1,
  },
  blockingTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 4,
  },
  blockingSubtitle: {
    fontSize: 12,
    color: '#FFFFFF',
    opacity: 0.8,
  },
  statsSection: {
    paddingHorizontal: 20,
    marginBottom: 24,
  },
  statsGrid: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  statCard: {
    flex: 1,
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
    marginHorizontal: 4,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  statValue: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#667eea',
    marginBottom: 4,
  },
  statLabel: {
    fontSize: 12,
    color: '#7F8C8D',
  },
  appBlockingSection: {
    paddingHorizontal: 20,
    marginBottom: 24,
  },
  appBlockingHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  appBlockingSubtitle: {
    fontSize: 14,
    color: '#667eea',
    fontWeight: '500',
  },
  appsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
  },
  appCard: {
    width: (width - 56) / 3,
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 12,
    marginBottom: 12,
    alignItems: 'center',
    borderWidth: 2,
    borderColor: 'transparent',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
    position: 'relative',
  },
  appCardSelected: {
    borderColor: '#667eea',
    backgroundColor: '#667eea',
  },
  appName: {
    fontSize: 12,
    fontWeight: '500',
    color: '#2C3E50',
    marginTop: 6,
    textAlign: 'center',
  },
  appNameSelected: {
    color: '#FFFFFF',
    fontWeight: '600',
  },
  checkIcon: {
    position: 'absolute',
    top: 4,
    right: 4,
  },
  activeButtons: {
    flexDirection: 'row',
    gap: 12,
  },
  endButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(231, 76, 60, 0.8)',
    paddingHorizontal: 20,
    paddingVertical: 10,
    borderRadius: 20,
  },
  buttonTextSmall: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '600',
    marginLeft: 6,
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
    marginBottom: 100,
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
    color: '#FFFFFF',
    textAlign: 'center',
    marginTop: 6,
  },
  achievementProgress: {
    fontSize: 10,
    color: '#FFFFFF',
    textAlign: 'center',
    marginTop: 4,
  },
});

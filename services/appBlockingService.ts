import * as TaskManager from 'expo-task-manager';
import * as BackgroundFetch from 'expo-background-fetch';
import { AppState, AppStateStatus, Linking, Alert } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';

const BACKGROUND_FETCH_TASK = 'app-blocking-monitor';
const BLOCKED_APPS_KEY = 'blocked_apps';
const STUDY_SESSION_KEY = 'is_studying';

export interface BlockedApp {
  name: string;
  packageName: string;
  blocked: boolean;
}

class AppBlockingService {
  private static instance: AppBlockingService;
  private isMonitoring = false;
  private appStateSubscription: any;
  private checkInterval: NodeJS.Timeout | null = null;

  private constructor() {}

  public static getInstance(): AppBlockingService {
    if (!AppBlockingService.instance) {
      AppBlockingService.instance = new AppBlockingService();
    }
    return AppBlockingService.instance;
  }

  // Initialize the app blocking service
  async initialize() {
    try {
      // Register background task
      await this.registerBackgroundTask();
      
      // Set up app state monitoring
      this.setupAppStateMonitoring();
      
      console.log('App blocking service initialized');
    } catch (error) {
      console.error('Failed to initialize app blocking service:', error);
    }
  }

  // Register background task for monitoring
  private async registerBackgroundTask() {
    try {
      await BackgroundFetch.registerTaskAsync(BACKGROUND_FETCH_TASK, {
        minimumInterval: 1000, // Check every second when possible
        stopOnTerminate: false,
        startOnBoot: true,
      });
      
      console.log('Background task registered');
    } catch (error) {
      console.error('Failed to register background task:', error);
    }
  }

  // Set up app state monitoring
  private setupAppStateMonitoring() {
    this.appStateSubscription = AppState.addEventListener(
      'change',
      this.handleAppStateChange.bind(this)
    );
  }

  // Handle app state changes
  private async handleAppStateChange(nextAppState: AppStateStatus) {
    const isStudying = await this.getStudyingStatus();
    
    if (!isStudying) {
      return;
    }

    // If app goes to background during study session, start monitoring
    if (nextAppState === 'background') {
      await this.startActiveMonitoring();
    } 
    // If app comes to foreground, stop intensive monitoring
    else if (nextAppState === 'active') {
      this.stopActiveMonitoring();
    }
  }

  // Start active monitoring when StudyMate goes to background
  private async startActiveMonitoring() {
    if (this.isMonitoring) return;
    
    this.isMonitoring = true;
    console.log('Starting active app monitoring...');

    // Check every 500ms for blocked apps
    this.checkInterval = setInterval(async () => {
      await this.checkForBlockedApps();
    }, 500);
  }

  // Stop active monitoring
  private stopActiveMonitoring() {
    if (!this.isMonitoring) return;
    
    this.isMonitoring = false;
    
    if (this.checkInterval) {
      clearInterval(this.checkInterval);
      this.checkInterval = null;
    }
    
    console.log('Stopped active app monitoring');
  }

  // Check if any blocked apps are running
  private async checkForBlockedApps() {
    try {
      const isStudying = await this.getStudyingStatus();
      if (!isStudying) {
        this.stopActiveMonitoring();
        return;
      }

      const blockedApps = await this.getBlockedApps();
      const activeApps = await this.getRunningApps();
      
      // Check if any blocked app is running
      for (const blockedApp of blockedApps) {
        if (blockedApp.blocked && this.isAppRunning(blockedApp.packageName, activeApps)) {
          await this.blockApp(blockedApp);
          break;
        }
      }
    } catch (error) {
      console.error('Error checking for blocked apps:', error);
    }
  }

  // Get currently running apps (simplified version)
  private async getRunningApps(): Promise<string[]> {
    try {
      // In a real implementation, you would use native modules to get running apps
      // For now, we'll use app state changes and package detection
      // This is a limitation of Expo - real app detection requires native code
      return [];
    } catch (error) {
      console.error('Error getting running apps:', error);
      return [];
    }
  }

  // Check if a specific app is running
  private isAppRunning(packageName: string, runningApps: string[]): boolean {
    return runningApps.includes(packageName);
  }

  // Block a specific app by redirecting back to StudyMate
  private async blockApp(app: BlockedApp) {
    console.log(`Blocking app: ${app.name}`);
    
    try {
      // Try to bring StudyMate back to foreground
      await Linking.openURL('studymate://block-warning');
      
      // Show blocking notification
      this.showBlockingAlert(app);
      
    } catch (error) {
      console.error('Error blocking app:', error);
      // Fallback to alert
      this.showBlockingAlert(app);
    }
  }

  // Show blocking alert
  private showBlockingAlert(app: BlockedApp) {
    Alert.alert(
      'App Blocked! 🚫',
      `${app.name} is blocked during your study session. Stay focused!`,
      [
        {
          text: 'Back to Study',
          onPress: () => {
            // Try to open StudyMate
            Linking.openURL('studymate://').catch(() => {
              console.log('Could not open StudyMate');
            });
          }
        },
        {
          text: 'End Study Session',
          onPress: async () => {
            await this.endStudySession();
          },
          style: 'destructive'
        }
      ],
      { cancelable: false }
    );
  }

  // Public methods for managing study sessions
  public async startStudySession(blockedApps: BlockedApp[]) {
    try {
      await AsyncStorage.setItem(BLOCKED_APPS_KEY, JSON.stringify(blockedApps));
      await AsyncStorage.setItem(STUDY_SESSION_KEY, 'true');
      
      // Start background monitoring
      await BackgroundFetch.startAsync(BACKGROUND_FETCH_TASK);
      
      console.log('Study session started with app blocking');
      return true;
    } catch (error) {
      console.error('Error starting study session:', error);
      return false;
    }
  }

  public async endStudySession() {
    try {
      await AsyncStorage.setItem(STUDY_SESSION_KEY, 'false');
      
      // Stop background monitoring
      await BackgroundFetch.stopAsync(BACKGROUND_FETCH_TASK);
      this.stopActiveMonitoring();
      
      console.log('Study session ended');
      return true;
    } catch (error) {
      console.error('Error ending study session:', error);
      return false;
    }
  }

  // Helper methods
  private async getBlockedApps(): Promise<BlockedApp[]> {
    try {
      const stored = await AsyncStorage.getItem(BLOCKED_APPS_KEY);
      return stored ? JSON.parse(stored) : [];
    } catch (error) {
      console.error('Error getting blocked apps:', error);
      return [];
    }
  }

  private async getStudyingStatus(): Promise<boolean> {
    try {
      const status = await AsyncStorage.getItem(STUDY_SESSION_KEY);
      return status === 'true';
    } catch (error) {
      console.error('Error getting studying status:', error);
      return false;
    }
  }

  // Clean up
  public cleanup() {
    if (this.appStateSubscription) {
      this.appStateSubscription.remove();
    }
    this.stopActiveMonitoring();
  }
}

// Background task definition
TaskManager.defineTask(BACKGROUND_FETCH_TASK, async () => {
  try {
    const service = AppBlockingService.getInstance();
    // Perform background monitoring
    console.log('Background fetch executed');
    
    return BackgroundFetch.BackgroundFetchResult.NewData;
  } catch (error) {
    console.error('Background task failed:', error);
    return BackgroundFetch.BackgroundFetchResult.Failed;
  }
});

export default AppBlockingService;

import AsyncStorage from '@react-native-async-storage/async-storage';

// Types for study data
export interface StudySession {
  id: string;
  date: string;
  startTime: string;
  endTime: string;
  duration: number; // in seconds
  subject?: string;
  focusScore: number; // 1-10 rating
  notes?: string;
  type: 'focused' | 'break' | 'review';
}

export interface DailyStudyData {
  date: string;
  totalTime: number; // in seconds
  sessions: StudySession[];
  goals: {
    target: number; // in seconds
    achieved: number; // in seconds
    completed: boolean;
  };
  breaks: number;
  focusRating: number; // average focus score
}

export interface StudyGoal {
  id: string;
  title: string;
  description: string;
  targetValue: number;
  currentValue: number;
  unit: 'minutes' | 'hours' | 'sessions' | 'days';
  deadline: string;
  completed: boolean;
  createdAt: string;
}

export interface WeeklyStats {
  week: string;
  totalTime: number;
  averageDaily: number;
  bestDay: string;
  longestSession: number;
  totalSessions: number;
  focusScore: number;
  goalsCompleted: number;
}

export interface Achievement {
  id: string;
  title: string;
  description: string;
  icon: string;
  unlockedAt?: string;
  progress: number;
  maxProgress: number;
}

const STORAGE_KEYS = {
  DAILY_DATA: '@StudyMate:dailyData',
  STUDY_GOALS: '@StudyMate:studyGoals',
  ACHIEVEMENTS: '@StudyMate:achievements',
  WEEKLY_STATS: '@StudyMate:weeklyStats',
  USER_PREFERENCES: '@StudyMate:preferences',
  TOTAL_STUDY_TIME: '@StudyMate:totalStudyTime'
};

class StudyDataService {
  // Daily Data Management
  async getDailyData(date: string): Promise<DailyStudyData | null> {
    try {
      const data = await AsyncStorage.getItem(`${STORAGE_KEYS.DAILY_DATA}:${date}`);
      return data ? JSON.parse(data) : null;
    } catch (error) {
      console.error('Error getting daily data:', error);
      return null;
    }
  }

  async saveDailyData(date: string, data: DailyStudyData): Promise<void> {
    try {
      await AsyncStorage.setItem(`${STORAGE_KEYS.DAILY_DATA}:${date}`, JSON.stringify(data));
    } catch (error) {
      console.error('Error saving daily data:', error);
    }
  }

  async addStudySession(session: StudySession): Promise<void> {
    try {
      const date = session.date;
      let dailyData = await this.getDailyData(date);
      
      if (!dailyData) {
        dailyData = {
          date,
          totalTime: 0,
          sessions: [],
          goals: { target: 7200, achieved: 0, completed: false }, // 2 hours default
          breaks: 0,
          focusRating: 0
        };
      }

      dailyData.sessions.push(session);
      dailyData.totalTime += session.duration;
      dailyData.goals.achieved += session.duration;
      dailyData.goals.completed = dailyData.goals.achieved >= dailyData.goals.target;
      
      if (session.type === 'break') {
        dailyData.breaks += 1;
      }

      // Calculate average focus rating
      const focusSessions = dailyData.sessions.filter(s => s.type === 'focused');
      dailyData.focusRating = focusSessions.length > 0 
        ? focusSessions.reduce((sum, s) => sum + s.focusScore, 0) / focusSessions.length 
        : 0;

      await this.saveDailyData(date, dailyData);
      await this.updateTotalStudyTime(session.duration);
      await this.checkAchievements();
    } catch (error) {
      console.error('Error adding study session:', error);
    }
  }

  // Study Goals Management
  async getStudyGoals(): Promise<StudyGoal[]> {
    try {
      const data = await AsyncStorage.getItem(STORAGE_KEYS.STUDY_GOALS);
      return data ? JSON.parse(data) : [];
    } catch (error) {
      console.error('Error getting study goals:', error);
      return [];
    }
  }

  async addStudyGoal(goal: Omit<StudyGoal, 'id' | 'createdAt'>): Promise<void> {
    try {
      const goals = await this.getStudyGoals();
      const newGoal: StudyGoal = {
        ...goal,
        id: Date.now().toString(),
        createdAt: new Date().toISOString()
      };
      goals.push(newGoal);
      await AsyncStorage.setItem(STORAGE_KEYS.STUDY_GOALS, JSON.stringify(goals));
    } catch (error) {
      console.error('Error adding study goal:', error);
    }
  }

  async updateGoalProgress(goalId: string, progress: number): Promise<void> {
    try {
      const goals = await this.getStudyGoals();
      const goalIndex = goals.findIndex(g => g.id === goalId);
      if (goalIndex !== -1) {
        goals[goalIndex].currentValue = progress;
        goals[goalIndex].completed = progress >= goals[goalIndex].targetValue;
        await AsyncStorage.setItem(STORAGE_KEYS.STUDY_GOALS, JSON.stringify(goals));
      }
    } catch (error) {
      console.error('Error updating goal progress:', error);
    }
  }

  // Analytics and Statistics
  async getWeeklyStats(weekStart: string): Promise<WeeklyStats | null> {
    try {
      const data = await AsyncStorage.getItem(`${STORAGE_KEYS.WEEKLY_STATS}:${weekStart}`);
      return data ? JSON.parse(data) : null;
    } catch (error) {
      console.error('Error getting weekly stats:', error);
      return null;
    }
  }

  async calculateWeeklyStats(weekStart: string): Promise<WeeklyStats> {
    const weekDays = this.getWeekDates(weekStart);
    let totalTime = 0;
    let totalSessions = 0;
    let totalFocusScore = 0;
    let bestDay = weekDays[0];
    let bestDayTime = 0;
    let longestSession = 0;
    let goalsCompleted = 0;

    for (const day of weekDays) {
      const dailyData = await this.getDailyData(day);
      if (dailyData) {
        totalTime += dailyData.totalTime;
        totalSessions += dailyData.sessions.length;
        totalFocusScore += dailyData.focusRating;
        
        if (dailyData.totalTime > bestDayTime) {
          bestDayTime = dailyData.totalTime;
          bestDay = day;
        }

        const dayLongest = Math.max(...dailyData.sessions.map(s => s.duration));
        if (dayLongest > longestSession) {
          longestSession = dayLongest;
        }

        if (dailyData.goals.completed) {
          goalsCompleted++;
        }
      }
    }

    const stats: WeeklyStats = {
      week: weekStart,
      totalTime,
      averageDaily: totalTime / 7,
      bestDay,
      longestSession,
      totalSessions,
      focusScore: totalFocusScore / 7,
      goalsCompleted
    };

    await AsyncStorage.setItem(`${STORAGE_KEYS.WEEKLY_STATS}:${weekStart}`, JSON.stringify(stats));
    return stats;
  }

  // Achievements System
  async getAchievements(): Promise<Achievement[]> {
    try {
      const data = await AsyncStorage.getItem(STORAGE_KEYS.ACHIEVEMENTS);
      if (data) {
        return JSON.parse(data);
      }
      
      // Initialize default achievements
      const defaultAchievements: Achievement[] = [
        {
          id: 'first_session',
          title: 'First Steps',
          description: 'Complete your first study session',
          icon: 'play-circle',
          progress: 0,
          maxProgress: 1
        },
        {
          id: 'hour_milestone',
          title: 'Hour Hero',
          description: 'Study for 1 hour in a single day',
          icon: 'time',
          progress: 0,
          maxProgress: 3600
        },
        {
          id: 'week_warrior',
          title: 'Week Warrior',
          description: 'Study for 7 consecutive days',
          icon: 'calendar',
          progress: 0,
          maxProgress: 7
        },
        {
          id: 'focus_master',
          title: 'Focus Master',
          description: 'Maintain 9+ focus score for 5 sessions',
          icon: 'eye',
          progress: 0,
          maxProgress: 5
        },
        {
          id: 'century_club',
          title: 'Century Club',
          description: 'Complete 100 study sessions',
          icon: 'trophy',
          progress: 0,
          maxProgress: 100
        }
      ];
      
      await AsyncStorage.setItem(STORAGE_KEYS.ACHIEVEMENTS, JSON.stringify(defaultAchievements));
      return defaultAchievements;
    } catch (error) {
      console.error('Error getting achievements:', error);
      return [];
    }
  }

  async checkAchievements(): Promise<void> {
    try {
      const achievements = await this.getAchievements();
      const totalStats = await this.getTotalStats();
      
      // Update achievement progress
      for (const achievement of achievements) {
        let newProgress = achievement.progress;
        
        switch (achievement.id) {
          case 'first_session':
            newProgress = totalStats.totalSessions > 0 ? 1 : 0;
            break;
          case 'hour_milestone':
            newProgress = Math.max(newProgress, totalStats.longestDayTime);
            break;
          case 'week_warrior':
            newProgress = totalStats.currentStreak;
            break;
          case 'focus_master':
            // Count sessions with 9+ focus score
            newProgress = totalStats.highFocusSessions;
            break;
          case 'century_club':
            newProgress = totalStats.totalSessions;
            break;
        }

        if (newProgress !== achievement.progress) {
          achievement.progress = newProgress;
          if (newProgress >= achievement.maxProgress && !achievement.unlockedAt) {
            achievement.unlockedAt = new Date().toISOString();
          }
        }
      }

      await AsyncStorage.setItem(STORAGE_KEYS.ACHIEVEMENTS, JSON.stringify(achievements));
    } catch (error) {
      console.error('Error checking achievements:', error);
    }
  }

  // Helper Methods
  private getWeekDates(weekStart: string): string[] {
    const dates = [];
    const start = new Date(weekStart);
    
    for (let i = 0; i < 7; i++) {
      const date = new Date(start);
      date.setDate(start.getDate() + i);
      dates.push(date.toISOString().split('T')[0]);
    }
    
    return dates;
  }

  async getTotalStats(): Promise<any> {
    // Implementation for getting total statistics across all time
    const totalTime = await AsyncStorage.getItem(STORAGE_KEYS.TOTAL_STUDY_TIME);
    // Add more comprehensive stats calculation here
    return {
      totalTime: totalTime ? parseInt(totalTime) : 0,
      totalSessions: 0, // Calculate from all daily data
      longestDayTime: 0,
      currentStreak: 0,
      highFocusSessions: 0
    };
  }

  async updateTotalStudyTime(additionalTime: number): Promise<void> {
    try {
      const current = await AsyncStorage.getItem(STORAGE_KEYS.TOTAL_STUDY_TIME);
      const total = (current ? parseInt(current) : 0) + additionalTime;
      await AsyncStorage.setItem(STORAGE_KEYS.TOTAL_STUDY_TIME, total.toString());
    } catch (error) {
      console.error('Error updating total study time:', error);
    }
  }

  // Get current date in YYYY-MM-DD format
  getCurrentDate(): string {
    return new Date().toISOString().split('T')[0];
  }

  // Format time from seconds to readable format
  formatTime(seconds: number): string {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    
    if (hours > 0) {
      return `${hours}h ${minutes}m`;
    }
    return `${minutes}m`;
  }

  // Get study streak
  async getStudyStreak(): Promise<number> {
    try {
      let streak = 0;
      const today = new Date();
      
      for (let i = 0; i < 365; i++) { // Check up to a year
        const date = new Date(today);
        date.setDate(today.getDate() - i);
        const dateString = date.toISOString().split('T')[0];
        
        const dailyData = await this.getDailyData(dateString);
        if (dailyData && dailyData.totalTime > 0) {
          streak++;
        } else if (i > 0) { // Don't break on today if no data yet
          break;
        }
      }
      
      return streak;
    } catch (error) {
      console.error('Error getting study streak:', error);
      return 0;
    }
  }
}

export const studyDataService = new StudyDataService();
export default studyDataService;

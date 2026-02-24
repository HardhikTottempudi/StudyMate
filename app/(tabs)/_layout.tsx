import { Tabs } from 'expo-router';
import { Image } from 'react-native';
import { MyTabBar } from '@/components/MyTabBar';

export default function TabLayout() {
  return (
    <Tabs 
      tabBar={(props) => <MyTabBar {...props} />} 
      screenOptions={{ 
        tabBarActiveTintColor: '#667eea', 
        headerShown: false 
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: 'Dashboard',
          tabBarIcon: ({ focused }) => (
            <Image
              source={require('../../assets/images/dasboard.png')}
              style={{ 
                width: 24, 
                height: 24, 
                tintColor: focused ? '#667eea' : '#999' 
              }}
            />
          ),
        }}
      />
      <Tabs.Screen
        name="flashcards"
        options={{
          title: 'Flashcards',
          tabBarIcon: ({ focused }) => (
            <Image
              source={require('../../assets/images/flashcard.png')}
              style={{ 
                width: 24, 
                height: 24, 
                tintColor: focused ? '#667eea' : '#999' 
              }}
            />
          ),
        }}
      />
      <Tabs.Screen
        name="study-session"
        options={{
          title: 'Study Session',
          tabBarIcon: ({ focused }) => (
            <Image
              source={require('../../assets/images/study_session.png')}
              style={{ 
                width: 24, 
                height: 24, 
                tintColor: focused ? '#667eea' : '#999' 
              }}
            />
          ),
        }}
      />
      <Tabs.Screen
        name="mindmaps"
        options={{
          title: 'Mindmaps',
          tabBarIcon: ({ focused }) => (
            <Image
              source={require('../../assets/images/mindmap.png')}
              style={{ 
                width: 24, 
                height: 24, 
                tintColor: focused ? '#667eea' : '#999' 
              }}
            />
          ),
        }}
      />
    </Tabs>
  );
}

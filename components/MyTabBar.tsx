import { BottomTabBarProps } from '@react-navigation/bottom-tabs';
import { LinearGradient } from 'expo-linear-gradient';
import React from 'react';
import { StyleSheet, Text, TouchableOpacity, View } from 'react-native';

// Define colors for different active states
const getActiveColors = (routeName: string) => {
  switch (routeName) {
    case 'index': // Dashboard
      return ['#ffd93d', '#ffb347']; // Blue gradient
    case 'flashcards':
      return ['#ffd93d', '#ffb347']; // Pink gradient
    case 'study-session':
      return ['#ffd93d', '#ffb347']; // Yellow/Orange gradient
    case 'mindmaps':
      return ['#ffd93d', '#ffb347']; // Blue gradient
    default:
      return ['#ffd93d', '#ffb347'];
  }
};

export function MyTabBar({ state, descriptors, navigation }: BottomTabBarProps) {
  return (
    <View style={styles.container}>
      <View style={styles.tabBar}>
        <View style={styles.tabContainer}>
          {state.routes.map((route, index) => {
            const { options } = descriptors[route.key];
            const isFocused = state.index === index;
            const activeColors = getActiveColors(route.name);

            const onPress = () => {
              const event = navigation.emit({
                type: 'tabPress',
                target: route.key,
                canPreventDefault: true,
              });

              if (!isFocused && !event.defaultPrevented) {
                navigation.navigate(route.name as never);
              }
            };

            const onLongPress = () => {
              navigation.emit({
                type: 'tabLongPress',
                target: route.key,
              });
            };

            return (
              <TouchableOpacity
                key={route.key}
                accessibilityRole="button"
                accessibilityState={isFocused ? { selected: true } : {}}
                accessibilityLabel={options.tabBarAccessibilityLabel}
                onPress={onPress}
                onLongPress={onLongPress}
                style={styles.tab}
              >
                <View style={styles.tabContent}>
                  <View style={[styles.iconContainer, isFocused && styles.activeIconContainer]}>
                    {isFocused && (
                      <LinearGradient
                        colors={activeColors}
                        style={styles.activeBackground}
                      />
                    )}
                    <View style={styles.iconWrapper}>
                      {options.tabBarIcon && options.tabBarIcon({
                        focused: isFocused,
                        color: isFocused ? '#FFFFFF' : '#7F8C8D',
                        size: 20,
                      })}
                    </View>
                  </View>
                  <Text style={[styles.label, isFocused && styles.activeLabel]}>
                    {options.title || route.name}
                  </Text>
                </View>
              </TouchableOpacity>
            );
          })}
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    paddingBottom: 20, // Reduced safe area padding
  },
  tabBar: {
    backgroundColor: '#F8F9FA',
    borderRadius: 70, // Increased from 20 for more rounded ends
    marginHorizontal: 16,
    marginBottom: 6,
    paddingVertical: 8, // Reduced from 12
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2, // Reduced shadow
    },
    shadowOpacity: 0.08,
    shadowRadius: 8,
    elevation: 6,
  },
  tabContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    alignItems: 'center',
    paddingHorizontal: 12, // Reduced padding
  },
  tab: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 4, // Reduced from 8
  },
  tabContent: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  iconContainer: {
    width: 44, // Reduced from 56
    height: 44, // Reduced from 56
    borderRadius: 22, // Reduced from 28
    justifyContent: 'center',
    alignItems: 'center',
    position: 'relative',
    marginBottom: 2, // Reduced from 4
  },
  activeIconContainer: {
    transform: [{ scale: 1.05 }], // Reduced scale from 1.1
  },
  activeBackground: {
    position: 'absolute',
    width: 44, // Reduced from 56
    height: 44, // Reduced from 56
    borderRadius: 22, // Reduced from 28
    top: 0,
    left: 0,
  },
  iconWrapper: {
    zIndex: 1,
  },
  label: {
    fontSize: 10, // Reduced from 11
    fontWeight: '500',
    color: '#7F8C8D',
    textAlign: 'center',
    marginTop: 1, // Reduced from 2
  },
  activeLabel: {
    color: '#667eea',
    fontWeight: '600',
  },
});

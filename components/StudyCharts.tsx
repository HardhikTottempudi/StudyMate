import React from 'react';
import { View, Text, StyleSheet, Dimensions } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';

const { width: screenWidth } = Dimensions.get('window');

interface BarChartProps {
  data: Array<{
    label: string;
    value: number;
    color?: string;
  }>;
  maxValue?: number;
  height?: number;
  showValues?: boolean;
}

export const BarChart: React.FC<BarChartProps> = ({ 
  data, 
  maxValue, 
  height = 120, 
  showValues = true 
}) => {
  const max = maxValue || Math.max(...data.map(d => d.value));
  const chartWidth = screenWidth - 80;
  const barWidth = Math.max(20, (chartWidth - (data.length - 1) * 8) / data.length);

  return (
    <View style={[styles.chartContainer, { height }]}>
      <View style={styles.barsContainer}>
        {data.map((item, index) => {
          const barHeight = max > 0 ? (item.value / max) * (height - 40) : 0;
          
          return (
            <View key={index} style={styles.barColumn}>
              <View style={[styles.barContainer, { height: height - 40 }]}>
                {barHeight > 0 && (
                  <LinearGradient
                    colors={item.color ? [item.color, `${item.color}80`] : ['#667eea', '#764ba2']}
                    style={[
                      styles.bar,
                      {
                        width: barWidth,
                        height: barHeight,
                        marginBottom: 0
                      }
                    ]}
                  />
                )}
              </View>
              <Text style={[styles.barLabel, { width: barWidth }]}>
                {item.label}
              </Text>
              {showValues && (
                <Text style={styles.barValue}>
                  {item.value}
                </Text>
              )}
            </View>
          );
        })}
      </View>
    </View>
  );
};

interface LineChartProps {
  data: Array<{
    label: string;
    value: number;
  }>;
  height?: number;
  color?: string;
}

export const LineChart: React.FC<LineChartProps> = ({ 
  data, 
  height = 120, 
  color = '#667eea' 
}) => {
  if (data.length < 2) return null;

  const max = Math.max(...data.map(d => d.value));
  const min = Math.min(...data.map(d => d.value));
  const range = max - min || 1;
  const chartWidth = screenWidth - 80;
  const pointWidth = chartWidth / (data.length - 1);

  const points = data.map((item, index) => ({
    x: index * pointWidth,
    y: height - 40 - ((item.value - min) / range) * (height - 80)
  }));

  return (
    <View style={[styles.chartContainer, { height }]}>
      <View style={styles.lineChartContainer}>
        {/* Render line segments */}
        {points.slice(0, -1).map((point, index) => {
          const nextPoint = points[index + 1];
          const lineLength = Math.sqrt(
            Math.pow(nextPoint.x - point.x, 2) + Math.pow(nextPoint.y - point.y, 2)
          );
          const angle = Math.atan2(nextPoint.y - point.y, nextPoint.x - point.x);
          
          return (
            <View
              key={index}
              style={[
                styles.lineSegment,
                {
                  left: point.x,
                  top: point.y,
                  width: lineLength,
                  transform: [{ rotate: `${angle}rad` }],
                  backgroundColor: color
                }
              ]}
            />
          );
        })}
        
        {/* Render points */}
        {points.map((point, index) => (
          <View
            key={`point-${index}`}
            style={[
              styles.dataPoint,
              {
                left: point.x - 4,
                top: point.y - 4,
                backgroundColor: color
              }
            ]}
          />
        ))}
      </View>
      
      {/* Labels */}
      <View style={styles.lineLabelsContainer}>
        {data.map((item, index) => (
          <Text key={index} style={[styles.lineLabel, { left: index * pointWidth - 15 }]}>
            {item.label}
          </Text>
        ))}
      </View>
    </View>
  );
};

interface CircularProgressProps {
  progress: number; // 0-100
  size?: number;
  strokeWidth?: number;
  color?: string;
  backgroundColor?: string;
  showPercentage?: boolean;
  title?: string;
}

export const CircularProgress: React.FC<CircularProgressProps> = ({
  progress,
  size = 80,
  strokeWidth = 8,
  color = '#667eea',
  backgroundColor = '#E5E5E5',
  showPercentage = true,
  title
}) => {
  const radius = (size - strokeWidth) / 2;
  const circumference = 2 * Math.PI * radius;
  const strokeDasharray = circumference;
  const strokeDashoffset = circumference - (progress / 100) * circumference;

  return (
    <View style={[styles.circularProgressContainer, { width: size, height: size }]}>
      <View style={styles.circularProgressInner}>
        {/* Background circle */}
        <View
          style={[
            styles.circularProgressRing,
            {
              width: size,
              height: size,
              borderRadius: size / 2,
              borderWidth: strokeWidth,
              borderColor: backgroundColor
            }
          ]}
        />
        
        {/* Progress circle - simplified version using border */}
        <View
          style={[
            styles.circularProgressRing,
            styles.circularProgressForeground,
            {
              width: size,
              height: size,
              borderRadius: size / 2,
              borderWidth: strokeWidth,
              borderColor: 'transparent',
              borderTopColor: color,
              transform: [{ rotate: `${(progress / 100) * 360 - 90}deg` }]
            }
          ]}
        />
        
        {showPercentage && (
          <View style={styles.circularProgressText}>
            <Text style={styles.circularProgressPercentage}>
              {Math.round(progress)}%
            </Text>
            {title && (
              <Text style={styles.circularProgressTitle}>
                {title}
              </Text>
            )}
          </View>
        )}
      </View>
    </View>
  );
};

interface HeatmapProps {
  data: Array<Array<{
    date: string;
    value: number;
  }>>;
  maxValue?: number;
  cellSize?: number;
}

export const StudyHeatmap: React.FC<HeatmapProps> = ({ 
  data, 
  maxValue, 
  cellSize = 12 
}) => {
  const max = maxValue || Math.max(...data.flat().map(d => d.value));
  
  const getIntensity = (value: number) => {
    if (max === 0) return 0;
    return value / max;
  };

  const getColor = (intensity: number) => {
    if (intensity === 0) return '#EBEDF0';
    if (intensity < 0.25) return '#C6E48B';
    if (intensity < 0.5) return '#7BC96F';
    if (intensity < 0.75) return '#239A3B';
    return '#196127';
  };

  return (
    <View style={styles.heatmapContainer}>
      {data.map((week, weekIndex) => (
        <View key={weekIndex} style={styles.heatmapWeek}>
          {week.map((day, dayIndex) => {
            const intensity = getIntensity(day.value);
            const color = getColor(intensity);
            
            return (
              <View
                key={dayIndex}
                style={[
                  styles.heatmapCell,
                  {
                    width: cellSize,
                    height: cellSize,
                    backgroundColor: color
                  }
                ]}
              />
            );
          })}
        </View>
      ))}
    </View>
  );
};

const styles = StyleSheet.create({
  chartContainer: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 16,
    marginVertical: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  
  // Bar Chart Styles
  barsContainer: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    justifyContent: 'space-around',
    flex: 1,
  },
  barColumn: {
    alignItems: 'center',
  },
  barContainer: {
    justifyContent: 'flex-end',
    alignItems: 'center',
  },
  bar: {
    borderTopLeftRadius: 4,
    borderTopRightRadius: 4,
  },
  barLabel: {
    fontSize: 10,
    color: '#7F8C8D',
    textAlign: 'center',
    marginTop: 4,
  },
  barValue: {
    fontSize: 10,
    color: '#2C3E50',
    fontWeight: '600',
    marginTop: 2,
  },
  
  // Line Chart Styles
  lineChartContainer: {
    position: 'relative',
    flex: 1,
  },
  lineSegment: {
    position: 'absolute',
    height: 2,
    borderRadius: 1,
  },
  dataPoint: {
    position: 'absolute',
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  lineLabelsContainer: {
    flexDirection: 'row',
    position: 'relative',
    marginTop: 8,
  },
  lineLabel: {
    position: 'absolute',
    fontSize: 10,
    color: '#7F8C8D',
    textAlign: 'center',
    width: 30,
  },
  
  // Circular Progress Styles
  circularProgressContainer: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  circularProgressInner: {
    position: 'relative',
    alignItems: 'center',
    justifyContent: 'center',
  },
  circularProgressRing: {
    position: 'absolute',
  },
  circularProgressForeground: {
    borderLeftColor: 'transparent',
    borderRightColor: 'transparent',
    borderBottomColor: 'transparent',
  },
  circularProgressText: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  circularProgressPercentage: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#2C3E50',
  },
  circularProgressTitle: {
    fontSize: 10,
    color: '#7F8C8D',
    marginTop: 2,
  },
  
  // Heatmap Styles
  heatmapContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
  },
  heatmapWeek: {
    flexDirection: 'column',
    marginRight: 2,
  },
  heatmapCell: {
    marginBottom: 2,
    borderRadius: 2,
  },
});

export default {
  BarChart,
  LineChart,
  CircularProgress,
  StudyHeatmap
};

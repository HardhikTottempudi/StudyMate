import { router } from 'expo-router';
import React from 'react';
import { Image, StyleSheet, Text, TouchableOpacity, View } from 'react-native';

export default function StartPage() {
  return (
    <View style={styles.container}>
        <View style={styles.content}>
          {/* Logo Section */}
          <View style={styles.logoContainer}>
            <Image
              source={require('../assets/images/img.png')}
              style={styles.logo}
              resizeMode="contain"
            />
            <Text style={styles.title}>StudyMate</Text>
            <Text style={styles.subtitle}>unlock your true potential</Text>
          </View>

          {/* Buttons Section */}
          <View style={styles.buttonContainer}>
            <TouchableOpacity
              style={styles.loginButton}
              onPress={() => router.push('/(auth)/login')}
            >
              <Text style={styles.loginButtonText}>Login</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.signupButton}
              onPress={() => router.push('/(auth)/signup')}
            >
              <Text style={styles.signupButtonText}>Sign Up</Text>
            </TouchableOpacity>
          </View>
        </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fff",
  },
  gradient: {
    flex: 1,
  },
  content: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 32,
  },
  logoContainer: {
    alignItems: 'center',
    marginBottom:50,
  },
  logo: {
    width: 180,
    height: 130,
    marginBottom: 20,
  },
  title: {
    fontSize: 36,
    fontWeight: 'bold',
    color: '#000000ff',
    marginBottom: 8,
    textAlign: 'center',
  },
  subtitle: {
    fontSize: 14,
    color: '#808080ff',
    textAlign: 'right',
    fontStyle: 'italic',
    alignSelf: 'flex-end',
    width: '100%',
  },
  buttonContainer: {
    width: '100%',
    maxWidth: 300,
    alignItems: 'center',
    gap: 26,
  },
  loginButton: {
    width: '60%',
    backgroundColor: '#FFFFFF',
    paddingVertical: 16,
    // paddingHorizontal: 40,
    borderRadius: 25,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.25,
    shadowRadius: 3.84,
    elevation: 5,
  },
  loginButtonText: {
    color: '#393939ff',
    fontSize: 18,
    fontWeight: '600',
  },
  signupButton: {
    width: '60%',
    backgroundColor: '#FFFFFF',
    paddingVertical: 16,
    // paddingHorizontal: 40,
    borderRadius: 25,
    alignItems: 'center',
    borderWidth: 2,
    borderColor: '#FFFFFF',
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.25,
    shadowRadius: 3.84,
    elevation: 5, 
  },
  signupButtonText: {
    color:  '#393939ff',
    fontSize: 18,
    fontWeight: '600',
  },
});

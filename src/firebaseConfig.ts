// firebase.ts
import { getApps, initializeApp } from "firebase/app";
import {
  Auth,
  getAuth
} from "firebase/auth";
// @ts-ignore -- RN typings quirk
import { getReactNativePersistence, initializeAuth } from "firebase/auth";

import AsyncStorage from "@react-native-async-storage/async-storage";

// Your config (replace with yours)
const firebaseConfig = {
  apiKey: "AIzaSyDnEfROOWpJq-Cpk83ciqTfU44DsE5cHg8",
  authDomain: "studymate-bbd1c.firebaseapp.com",
  projectId: "studymate-bbd1c",
  storageBucket: "studymate-bbd1c.firebasestorage.app",
  messagingSenderId: "239376838704",
  appId: "1:239376838704:web:c5bb955701f613938d3df5",
  measurementId: "G-TTFH3307K0"
};

// Initialize Firebase
let app;
let auth: Auth;

if (!getApps().length) {
  app = initializeApp(firebaseConfig);

  // Ensure persistence on native
  auth = initializeAuth(app, {
    persistence: getReactNativePersistence(AsyncStorage),
  });
} else {
  app = getApps()[0]!;
  auth = getAuth(app);
}

export { app, auth };


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/auth/screens/start_page.dart';
import 'features/dashboard/screens/main_navigation.dart';
import 'shared/theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    runApp(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SafeArea(
              child: Center(
                  child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.cloud_off_rounded, size: 48),
              const SizedBox(height: 16),
              const Text(
                  'StudyMate couldn’t start. Check your connection and try again.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: main, child: const Text('Try again')),
            ]),
          ))),
        )));
    return;
  }

  runApp(const ProviderScope(child: StudyMateApp()));
}

class StudyMateApp extends StatelessWidget {
  const StudyMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyMate',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return MainNavigation(key: ValueKey(snapshot.data!.uid));
        }
        return const StartPage();
      },
    );
  }
}

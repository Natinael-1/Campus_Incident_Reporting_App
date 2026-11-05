import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/incident_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/staff/staff_dashboard_screen.dart';
import 'screens/student/student_home_screen.dart';
import 'utils/app_constants.dart';

//Toggle this to false only if you switch to paid cloud Firebase Storage later
const bool useStorageEmulator = true;

Future<void> main() async {
  // 1. Ensure Flutter engine bindings are ready before calling native plugins
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase using generated firebase_options.dart file
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Connect Firebase Storage to the local Emulator running on port 9199
  if (useStorageEmulator) {
    // Android Emulator uses '10.0.2.2' to reach your host laptop's localhost
    final String emulatorHost =
        (!kIsWeb && Platform.isAndroid) ? '10.0.2.2' : 'localhost';

    await FirebaseStorage.instance.useStorageEmulator(emulatorHost, 9199);
  }

  runApp(const CampusIncidentApp());
}

class CampusIncidentApp extends StatelessWidget {
  const CampusIncidentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider<IncidentProvider>(
          create: (_) => IncidentProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Campus Incident Reporter',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppConstants.scaffoldBackground,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppConstants.primaryBlue,
            primary: AppConstants.primaryBlue,
            surface: AppConstants.cardWhite,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppConstants.scaffoldBackground,
            foregroundColor: AppConstants.textDark,
            elevation: 0,
            centerTitle: true,
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}

//Listens to AuthProvider and routes the user to Login, Student Home, or Staff Dashboard
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthProvider authProvider = context.watch<AuthProvider>();

    // Show a clean splash loading indicator while checking initial Firebase session
    if (!authProvider.isInitialized) {
      return const Scaffold(
        backgroundColor: AppConstants.scaffoldBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CircularProgressIndicator(
                color: AppConstants.primaryBlue,
              ),
              SizedBox(height: 16.0),
              Text(
                'Loading Campus Incident Reporter...',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Not signed in -> show LoginScreen
    if (!authProvider.isAuthenticated || authProvider.currentUser == null) {
      return const LoginScreen();
    }

    // Signed in -> route based on verified role ('staff' vs 'student')
    if (authProvider.isStaff) {
      return const StaffDashboardScreen();
    }

    return const StudentHomeScreen();
  }
}
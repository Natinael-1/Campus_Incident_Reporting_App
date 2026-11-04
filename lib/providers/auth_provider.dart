import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  StreamSubscription<User?>? _authSubscription;

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  AuthProvider() {
    _initializeAuth();
  }

  
  // GETTERS (Read by UI Screens)
  
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  // True when a user is logged in and their profile is loaded
  bool get isAuthenticated => _currentUser != null;

  //Role-based access control getters
  bool get isStaff => _currentUser?.isStaff ?? false;
  bool get isStudent => _currentUser?.isStudent ?? true;

  
  // INITIALIZATION & AUTH STREAM LISTENER
  
  Future<void> _initializeAuth() async {
    try {
      // Seed the allowed @alueducation.com staff emails in Firestore if not already present
      await _authService.seedAuthorizedStaff();
    } catch (_) {
      // Ignore seeding errors if offline during initial boot
    }

    // Listen to Firebase Auth login/logout events in real time
    _authSubscription = _authService.authStateChanges.listen(
      (User? firebaseUser) async {
        if (firebaseUser == null) {
          _currentUser = null;
          _isInitialized = true;
          notifyListeners();
        } else {
          // Only fetch from Firestore if we don't already have this user loaded
          if (_currentUser == null || _currentUser!.uid != firebaseUser.uid) {
            try {
              _currentUser = await _authService.getUserProfile(firebaseUser.uid);
            } catch (e) {
              _errorMessage = e.toString().replaceFirst('Exception: ', '');
            }
          }
          _isInitialized = true;
          notifyListeners();
        }
      },
    );
  }

 
  // REGISTER NEW USER
  
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String department = 'Software Engineering',
    String location = 'Kigali, Rwanda',
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _currentUser = await _authService.registerWithEmailAndPassword(
        name: name,
        email: email,
        password: password,
        department: department,
        location: location,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  
  // SIGN IN EXISTING USER

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _currentUser = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  
  // SIGN OUT

  Future<void> signOut() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _authService.signOut();
      _currentUser = null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

 
  // REFRESH USER PROFILE & HELPERS
  
  Future<void> refreshUserProfile() async {
    final User? firebaseUser = _authService.currentFirebaseUser;
    if (firebaseUser == null) return;

    try {
      _currentUser = await _authService.getUserProfile(firebaseUser.uid);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
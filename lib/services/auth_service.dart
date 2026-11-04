import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../utils/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream that listens in real-time to whether a user logs in or logs out
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Returns the currently logged-in Firebase Auth user (or null if logged out)
  User? get currentFirebaseUser => _auth.currentUser;

  /// 0. SEED AUTHORIZED STAFF: Pre-populates allowed @alueducation.com staff emails
  /// Call this once during app startup or from a setup helper so your test staff accounts work
  Future<void> seedAuthorizedStaff() async {
    final List<Map<String, String>> initialStaffList = [
      {
        'email': 'facilities@alueducation.com',
        'name': 'Jean Paul (Facilities)',
        'department': 'Facilities Management',
      },
      {
        'email': 'admin.staff@alueducation.com',
        'name': 'Campus Operations Admin',
        'department': 'Campus Operations',
      },
      {
        'email': 'it.support@alueducation.com',
        'name': 'ALU IT Support',
        'department': 'IT & Infrastructure',
      },
    ];

    final CollectionReference<Map<String, dynamic>> staffCollection =
        _firestore.collection(AppConstants.authorizedStaffCollection);

    for (final Map<String, String> staff in initialStaffList) {
      final String emailKey = staff['email']!.toLowerCase().trim();
      final DocumentSnapshot<Map<String, dynamic>>existingDoc =
          await staffCollection.doc(emailKey).get();

      if (!existingDoc.exists) {
        await staffCollection.doc(emailKey).set({
          'email': emailKey,
          'name': staff['name'],
          'department': staff['department'],
          'seededAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  /// Helper: Checks if an email is in the 'authorized_staff' Firestore collection
  /*Future?> _getAuthorizedStaffRecord(String email) async {
    final String normalizedEmail = email.toLowerCase().trim();
    final DocumentSnapshot> doc = await _firestore
        .collection(AppConstants.authorizedStaffCollection)
        .doc(normalizedEmail)
        .get();

    if (doc.exists && doc.data() != null) {
      return doc.data();
    }
    return null;
  }*/
  Future<Map<String, dynamic>?> _getAuthorizedStaffRecord(String email) async {
  final String normalizedEmail = email.toLowerCase().trim();

  final DocumentSnapshot<Map<String, dynamic>> doc = await _firestore
      .collection(AppConstants.authorizedStaffCollection)
      .doc(normalizedEmail)
      .get();

  if (doc.exists && doc.data() != null) {
    return doc.data();
  }

  return null;
}

  /// 1. REGISTER: Automatically resolves role based on @alueducation.com + Firestore allowlist
  Future<UserModel> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    String department = 'Software Engineering',
    String location = 'Kigali, Rwanda',
  }) async {
    try {
      final String cleanEmail = email.toLowerCase().trim();
      String assignedRole = 'student';
      String assignedDepartment = department.trim();

      // Step A: If the user enters an @alueducation.com email, verify it exists in 'authorized_staff'
      if (cleanEmail.endsWith('@alueducation.com')) {
        final Map<String, dynamic>? staffRecord =
            await _getAuthorizedStaffRecord(cleanEmail);

        if (staffRecord == null) {
          throw Exception(
            'Access denied: This @alueducation.com email is not registered in the authorized campus staff directory.',
          );
        }

        assignedRole = 'staff';
        assignedDepartment =
            staffRecord['department'] ?? 'Facilities Management';
      }

      // Step B: Create the account in Firebase Authentication
      final UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final User? firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('User registration failed. Please try again.');
      }

      // Step C: Build UserModel with the system-verified role ('student' or 'staff')
      final UserModel newUser = UserModel(
        uid: firebaseUser.uid,
        name: name.trim(),
        email: cleanEmail,
        role: assignedRole,
        department: assignedDepartment,
        location: location.trim(),
        createdAt: DateTime.now(),
      );

      // Step D: Save the user document inside the 'users' collection in Cloud Firestore
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(firebaseUser.uid)
          .set(newUser.toMap());

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e.code));
    } catch (e) {
      // Remove the extra "Exception: " prefix so UI snackbars stay clean
      final String message = e.toString().replaceFirst('Exception: ', '');
      throw Exception(message);
    }
  }

  /// 2. LOGIN: Signs in with email & password and fetches the user's role from Firestore
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final String cleanEmail = email.toLowerCase().trim();

      // Step A: Verify email & password with Firebase Authentication
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final User? firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Login failed. Please try again.');
      }

      // Step B: Fetch the matching UserModel document from Cloud Firestore
      final UserModel? userModel = await getUserProfile(firebaseUser.uid);
      if (userModel != null) {
        return userModel;
      }

      // Fallback: Check if the email belongs to authorized_staff before defaulting to student
      final Map<String, dynamic>? staffRecord =
          await _getAuthorizedStaffRecord(cleanEmail);

      final UserModel fallbackUser = UserModel(
        uid: firebaseUser.uid,
        name: staffRecord?['name'] ??
            firebaseUser.email?.split('@').first ??
            'Campus User',
        email: cleanEmail,
        role: staffRecord != null ? 'staff' : 'student',
        department: staffRecord?['department'] ?? 'Software Engineering',
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(firebaseUser.uid)
          .set(fallbackUser.toMap());

      return fallbackUser;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e.code));
    } catch (e) {
      final String message = e.toString().replaceFirst('Exception: ', '');
      throw Exception(message);
    }
  }

  /// 3. FETCH PROFILE: Reads a single user document from Firestore by UID
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load user profile: ${e.toString()}');
    }
  }

  /// 4. LOGOUT: Signs out the current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Translates technical Firebase error codes into friendly English messages for the UI
  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Your password is too weak. Please use at least 6 characters.';
      case 'invalid-email':
        return 'The email address format is invalid.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Authentication failed ($code). Please try again.';
    }
  }
}
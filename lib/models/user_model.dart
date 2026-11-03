import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String department; 
  final String location;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.department = 'Software Engineering',
    this.location = 'Kigali, Rwanda',
    required this.createdAt,
  });

  // Getter to check if a user is authorized staff
  bool get isStaff => role.toLowerCase() == 'staff';

 
  // Getter to check if a logged in user is a student
  bool get isStudent => role.toLowerCase() == 'student';

  // Getter to extract the first name
  String get firstName => name.trim().split(' ').first;

  //Converts a Cloud Firestore Document Map into a UserModel object
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      department: map['department'] ?? 'Software Engineering',
      location: map['location'] ?? 'Kigali, Rwanda',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  //Converts this UserModel object into a Map to save inside Cloud Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  //Creates a modified copy of the UserModel when updating profile fields
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? role,
    String? department,
    String? location,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentModel {
  final String id;
  final String title;
  final String description;
  final String category; 
  final String location; 
  final String? imageUrl; 
  final String status; 
  final String reportedByUid;
  final String reportedByName;
  final String? updatedByStaffName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? inProgressAt; 
  final DateTime? resolvedAt; 

  const IncidentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    this.imageUrl,
    this.status = 'Submitted',
    required this.reportedByUid,
    required this.reportedByName,
    this.updatedByStaffName,
    required this.createdAt,
    required this.updatedAt,
    this.inProgressAt,
    this.resolvedAt,
  });

  //Helper getters to check the current status for badges and timeline steps
  bool get isSubmitted => status == 'Submitted';
  bool get isInProgress => status == 'In Progress';
  bool get isResolved => status == 'Resolved';

  //Helper getter to check if the student attached a photo
  bool get hasPhoto => imageUrl != null && imageUrl!.trim().isNotEmpty;

  // Generates relative time strings like "2 hours ago" or "3 days ago" for Incident Cards
  String get timeAgo {
    final Duration diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} ${diff.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ${diff.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (diff.inDays < 30) {
      return '${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      final int months = (diff.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
  }

  // Converts a Cloud Firestore Document Map into an IncidentModel object
  factory IncidentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return IncidentModel(
      id: documentId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Facilities',
      location: map['location'] ?? '',
      imageUrl: map['imageUrl'],
      status: map['status'] ?? 'Submitted',
      reportedByUid: map['reportedByUid'] ?? '',
      reportedByName: map['reportedByName'] ?? 'Student',
      updatedByStaffName: map['updatedByStaffName'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      inProgressAt: map['inProgressAt'] is Timestamp
          ? (map['inProgressAt'] as Timestamp).toDate()
          : null,
      resolvedAt: map['resolvedAt'] is Timestamp
          ? (map['resolvedAt'] as Timestamp).toDate()
          : null,
    );
  }

  //Converts this IncidentModel object into a Map to save inside Cloud Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'imageUrl': imageUrl,
      'status': status,
      'reportedByUid': reportedByUid,
      'reportedByName': reportedByName,
      'updatedByStaffName': updatedByStaffName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'inProgressAt':
          inProgressAt != null ? Timestamp.fromDate(inProgressAt!) : null,
      'resolvedAt':
          resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }

  //Creates an updated copy of the IncidentModel (e.g., when Staff updates status)
  IncidentModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? location,
    String? imageUrl,
    String? status,
    String? reportedByUid,
    String? reportedByName,
    String? updatedByStaffName,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? inProgressAt,
    DateTime? resolvedAt,
  }) {
    return IncidentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      reportedByUid: reportedByUid ?? this.reportedByUid,
      reportedByName: reportedByName ?? this.reportedByName,
      updatedByStaffName: updatedByStaffName ?? this.updatedByStaffName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      inProgressAt: inProgressAt ?? this.inProgressAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
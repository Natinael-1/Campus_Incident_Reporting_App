import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/incident_model.dart';
import '../utils/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //Generates a new unique Firestore Document ID before uploading an image
  String generateIncidentId() {
    return _firestore.collection(AppConstants.incidentsCollection).doc().id;
  }

  //CREATE: Saves a new incident report document in Cloud Firestore
  Future<void> createIncident(IncidentModel incident) async {
    try {
      await _firestore
          .collection(AppConstants.incidentsCollection)
          .doc(incident.id)
          .set(incident.toMap());
    } on FirebaseException catch (e) {
      throw Exception('Failed to submit incident (${e.code}): ${e.message}');
    } catch (e) {
      throw Exception('Error submitting incident: ${e.toString()}');
    }
  }

  //REAL-TIME STREAM (ALL INCIDENTS): Listens to all campus incidents newest first
  Stream<List<IncidentModel>> getAllIncidentsStream() {
    return _firestore
        .collection(AppConstants.incidentsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      return snapshot.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
        return IncidentModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  //FETCH ONCE (ALL INCIDENTS): Loads all incidents once for manual refresh
  Future<List<IncidentModel>> getAllIncidentsOnce() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection(AppConstants.incidentsCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
        return IncidentModel.fromMap(doc.data(), doc.id);
      }).toList();
    } on FirebaseException catch (e) {
      throw Exception('Failed to load incidents (${e.code}): ${e.message}');
    } catch (e) {
      throw Exception('Error loading incidents: ${e.toString()}');
    }
  }

  //REAL-TIME STREAM (STUDENT'S OWN INCIDENTS): Filters by reportedByUid
  Stream<List<IncidentModel>> getUserIncidentsStream(String uid) {
    return _firestore
        .collection(AppConstants.incidentsCollection)
        .where('reportedByUid', isEqualTo: uid)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      final List<IncidentModel> incidents = snapshot.docs.map(
        (QueryDocumentSnapshot<Map<String, dynamic>> doc) {
          return IncidentModel.fromMap(doc.data(), doc.id);
        },
      ).toList();

      // Sort newest first in Dart to avoid Firestore composite index errors
      incidents.sort((IncidentModel a, IncidentModel b) {
        return b.createdAt.compareTo(a.createdAt);
      });

      return incidents;
    });
  }

  //FETCH SINGLE INCIDENT: Reads one incident document by ID
  Future<IncidentModel?> getIncidentById(String incidentId) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await _firestore
          .collection(AppConstants.incidentsCollection)
          .doc(incidentId)
          .get();

      if (doc.exists && doc.data() != null) {
        return IncidentModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } on FirebaseException catch (e) {
      throw Exception('Failed to fetch incident (${e.code}): ${e.message}');
    } catch (e) {
      throw Exception('Error fetching incident: ${e.toString()}');
    }
  }

  //UPDATE STATUS (STAFF ONLY): Updates status and records timeline timestamps
  Future<void> updateIncidentStatus({
    required String incidentId,
    required String newStatus,
    required String staffName,
  }) async {
    try {
      final DateTime now = DateTime.now();
      final Map<String, dynamic> updates = <String, dynamic>{
        'status': newStatus,
        'updatedByStaffName': staffName,
        'updatedAt': Timestamp.fromDate(now),
      };

      // Record exact stage timestamp for the Incident Details Status Timeline
      if (newStatus == AppConstants.statusInProgress) {
        updates['inProgressAt'] = Timestamp.fromDate(now);
      } else if (newStatus == AppConstants.statusResolved) {
        updates['resolvedAt'] = Timestamp.fromDate(now);
      }

      await _firestore
          .collection(AppConstants.incidentsCollection)
          .doc(incidentId)
          .update(updates);
    } on FirebaseException catch (e) {
      throw Exception('Failed to update status (${e.code}): ${e.message}');
    } catch (e) {
      throw Exception('Error updating status: ${e.toString()}');
    }
  }

  Future<void> updateIncidentDetails({
    required String incidentId,
    required String title,
    required String description,
    required String category,
    required String location,
    required String? imageUrl,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.incidentsCollection)
          .doc(incidentId)
          .update(<String, dynamic>{
        'title': title.trim(),
        'description': description.trim(),
        'category': category.trim(),
        'location': location.trim(),
        'imageUrl': imageUrl,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on FirebaseException catch (e) {
      throw Exception('Failed to update incident (${e.code}): ${e.message}');
    } catch (e) {
      throw Exception('Error updating incident: ${e.toString()}');
    }
  }

  //DELETE INCIDENT: Removes an incident document from Cloud Firestore
  Future<void> deleteIncident(String incidentId) async {
    try {
      await _firestore
          .collection(AppConstants.incidentsCollection)
          .doc(incidentId)
          .delete();
    } on FirebaseException catch (e) {
      throw Exception('Failed to delete incident (${e.code}): ${e.message}');
    } catch (e) {
      throw Exception('Error deleting incident: ${e.toString()}');
    }
  }
}
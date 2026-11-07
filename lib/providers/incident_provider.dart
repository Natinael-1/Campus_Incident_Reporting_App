import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/incident_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../utils/app_constants.dart';

class IncidentProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  StreamSubscription<List<IncidentModel>>? _incidentsSubscription;

  List<IncidentModel> _allIncidents = <IncidentModel>[];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Search and Filter State
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';

  IncidentProvider() {
    listenToIncidents();
  }

  
  // BASIC GETTERS

  List<IncidentModel> get allIncidents => _allIncidents;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedStatus => _selectedStatus;

  
  //FILTERED & RECENT LIST GETTERS

  //Returns incidents filtered by the active search query, category, and status tab
  List<IncidentModel> get filteredIncidents {
    return _allIncidents.where((IncidentModel incident) {
      // 1. Category Filter
      final bool matchesCategory = _selectedCategory == 'All' ||
          incident.category.toLowerCase() == _selectedCategory.toLowerCase();

      // 2. Status Filter ('All', 'Submitted', 'In Progress', 'Resolved')
      final bool matchesStatus = _selectedStatus == 'All' ||
          incident.status.toLowerCase() == _selectedStatus.toLowerCase();

      // 3. Search Query Filter (matches title, description, or location)
      final String query = _searchQuery.trim().toLowerCase();
      final bool matchesSearch = query.isEmpty ||
          incident.title.toLowerCase().contains(query) ||
          incident.description.toLowerCase().contains(query) ||
          incident.location.toLowerCase().contains(query) ||
          incident.category.toLowerCase().contains(query);

      return matchesCategory && matchesStatus && matchesSearch;
    }).toList();
  }

  //Returns the 5 most recent reports for the Home Screen "Recent Reports" section
  List<IncidentModel> get recentIncidents {
    if (_allIncidents.length <= 5) {
      return _allIncidents;
    }
    return _allIncidents.sublist(0, 5);
  }

  //Returns all incidents submitted by a specific student (by UID)
  List<IncidentModel> getUserIncidents(String uid) {
    return _allIncidents
        .where((IncidentModel incident) => incident.reportedByUid == uid)
        .toList();
  }

  //Returns a student's own reports filtered by the active status tab & search query
  List<IncidentModel> getFilteredUserIncidents(String uid) {
    return filteredIncidents
        .where((IncidentModel incident) => incident.reportedByUid == uid)
        .toList();
  }

  //Finds a specific incident in memory by ID so Detail Screen updates in real time
  IncidentModel? getIncidentByIdFromCache(String incidentId) {
    for (final IncidentModel incident in _allIncidents) {
      if (incident.id == incidentId) {
        return incident;
      }
    }
    return null;
  }

  
  // 3. SUMMARY COUNTERS (FOR HOME & PROFILE CARDS)
  

  //Total counts across all campus reports (used on Staff Dashboard & global feed)
  int get totalCount => _allIncidents.length;

  int get submittedCount => _allIncidents
      .where((IncidentModel i) => i.status == AppConstants.statusSubmitted)
      .length;

  int get inProgressCount => _allIncidents
      .where((IncidentModel i) => i.status == AppConstants.statusInProgress)
      .length;

  int get resolvedCount => _allIncidents
      .where((IncidentModel i) => i.status == AppConstants.statusResolved)
      .length;

  //Student-specific summary counts for the "My Reports" cards
  int getUserTotalCount(String uid) => getUserIncidents(uid).length;

  int getUserSubmittedCount(String uid) => getUserIncidents(uid)
      .where((IncidentModel i) => i.status == AppConstants.statusSubmitted)
      .length;

  int getUserInProgressCount(String uid) => getUserIncidents(uid)
      .where((IncidentModel i) => i.status == AppConstants.statusInProgress)
      .length;

  int getUserResolvedCount(String uid) => getUserIncidents(uid)
      .where((IncidentModel i) => i.status == AppConstants.statusResolved)
      .length;

  
  // 4. REAL-TIME STREAM & MANUAL REFRESH
  
  //Opens a real-time listener to the Cloud Firestore 'incidents' collection
  void listenToIncidents() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _incidentsSubscription?.cancel();
    _incidentsSubscription = _firestoreService.getAllIncidentsStream().listen(
      (List<IncidentModel> incidents) {
        _allIncidents = incidents;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object error) {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        notifyListeners();
      },
    );
  }

  //Manually reloads incidents (used for pull-to-refresh on the feed)
  Future<void> refreshIncidents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allIncidents = await _firestoreService.getAllIncidentsOnce();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  
  // 5. SEARCH & FILTER UPDATERS
  

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSelectedStatus(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    _selectedStatus = 'All';
    notifyListeners();
  }

 
  // 6. SUBMIT NEW INCIDENT (WITH OPTIONAL PHOTO)
  

  Future<bool> submitIncident({
    required String title,
    required String description,
    required String category,
    required String location,
    required String reportedByUid,
    required String reportedByName,
    File? imageFile,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Step A: Generate a unique Firestore document ID first
      final String incidentId = _firestoreService.generateIncidentId();
      String? uploadedImageUrl;

      // Step B: If the student attached a photo, upload it to Firebase Storage first
      if (imageFile != null) {
        uploadedImageUrl = await _storageService.uploadIncidentImage(
          imageFile: imageFile,
          incidentId: incidentId,
        );
      }

      // Step C: Build the IncidentModel with status = 'Submitted'
      final DateTime now = DateTime.now();
      final IncidentModel newIncident = IncidentModel(
        id: incidentId,
        title: title.trim(),
        description: description.trim(),
        category: category.trim(),
        location: location.trim(),
        imageUrl: uploadedImageUrl,
        status: AppConstants.statusSubmitted,
        reportedByUid: reportedByUid,
        reportedByName: reportedByName.trim(),
        createdAt: now,
        updatedAt: now,
      );

      // Step D: Save the document in Cloud Firestore
      await _firestoreService.createIncident(newIncident);

      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  
  // 7. UPDATE INCIDENT STATUS (STAFF ONLY)
  
  Future<bool> updateIncidentStatus({
    required String incidentId,
    required String newStatus,
    required String staffName,
    required bool isStaffUser,
  }) async {
    // Access Control Check: Block non-staff users from updating statuses
    if (!isStaffUser) {
      _errorMessage =
          'Unauthorized: Only authorized campus staff can update incident status.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.updateIncidentStatus(
        incidentId: incidentId,
        newStatus: newStatus,
        staffName: staffName,
      );

      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> editIncident({
      required IncidentModel existingIncident,
      required String title,
      required String description,
      required String category,
      required String location,
      File? newImageFile,
      bool removeExistingImage = false,
    }) async {
      _isSubmitting = true;
      _errorMessage = null;
      notifyListeners();

      try {
        String? finalImageUrl = existingIncident.imageUrl;

        // Case 1: User picked a brand-new photo from Camera/Gallery -> upload & replace
        if (newImageFile != null) {
          finalImageUrl = await _storageService.uploadIncidentImage(
            imageFile: newImageFile,
            incidentId: existingIncident.id,
          );
        }
        // Case 2: User tapped the 'X' button to remove the existing photo without picking a new one
        else if (removeExistingImage && existingIncident.imageUrl != null) {
          try {
            await _storageService.deleteIncidentImage(existingIncident.imageUrl!);
          } catch (_) {
            // Ignore storage deletion error if file was already missing
          }
          finalImageUrl = null;
        }

        // Update the document fields in Cloud Firestore
        await _firestoreService.updateIncidentDetails(
          incidentId: existingIncident.id,
          title: title,
          description: description,
          category: category,
          location: location,
          imageUrl: finalImageUrl,
        );

        _isSubmitting = false;
        notifyListeners();
        return true;
      } catch (e) {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isSubmitting = false;
        notifyListeners();
        return false;
      }
  }
  
  // 8. DELETE INCIDENT
  Future<bool> deleteIncident(IncidentModel incident) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (incident.hasPhoto && incident.imageUrl != null) {
        try {
          await _storageService.deleteIncidentImage(incident.imageUrl!);
        } catch (_) {
          // Continue deleting the Firestore document even if storage image was already removed
        }
      }

      await _firestoreService.deleteIncident(incident.id);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _incidentsSubscription?.cancel();
    super.dispose();
  }
}
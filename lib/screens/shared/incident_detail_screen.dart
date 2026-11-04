import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/incident_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../utils/app_constants.dart';
import '../../widgets/status_badge.dart';

class IncidentDetailScreen extends StatelessWidget {
  final IncidentModel initialIncident;

  const IncidentDetailScreen({
    super.key,
    required this.initialIncident,
  });

  // ==========================================
  // DATE & TIME FORMATTING HELPERS
  // ==========================================
  static const List<String> _monthNames = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Formats DateTime as "Oct 15, 2026 at 10:24 AM" for the Submitted metadata row
  String _formatFullDateTime(DateTime dt) {
    final String month = _monthNames[dt.month - 1];
    final int hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final String minute = dt.minute.toString().padLeft(2, '0');
    final String period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month ${dt.day}, ${dt.year} at $hour12:$minute $period';
  }

  /// Formats DateTime as "Oct 15, 10:24 AM" for the Status Timeline nodes
  String _formatShortDateTime(DateTime? dt) {
    if (dt == null) return 'Pending';
    final String month = _monthNames[dt.month - 1];
    final int hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final String minute = dt.minute.toString().padLeft(2, '0');
    final String period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month ${dt.day}, $hour12:$minute $period';
  }

  // ==========================================
  // STAFF STATUS UPDATE HANDLER
  // ==========================================
  Future<void> _handleStatusUpdate(
    BuildContext context,
    IncidentModel incident,
    String newStatus,
  ) async {
    if (incident.status == newStatus) return;

    final AuthProvider authProvider = context.read<AuthProvider>();
    final IncidentProvider incidentProvider = context.read<IncidentProvider>();
    final UserModel? currentUser = authProvider.currentUser;

    final bool success = await incidentProvider.updateIncidentStatus(
      incidentId: incident.id,
      newStatus: newStatus,
      staffName: currentUser?.name ?? 'Authorized Staff',
      isStaffUser: authProvider.isStaff,
    );

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Incident status updated to "$newStatus"'),
          backgroundColor: AppConstants.resolvedText,
        ),
      );
    } else {
      final String error =
          incidentProvider.errorMessage ?? 'Failed to update status.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ==========================================
  // DELETE INCIDENT HANDLER (OPTIONAL ACTION)
  // ==========================================
  Future<void> _confirmDelete(
    BuildContext context,
    IncidentModel incident,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppConstants.cardWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: const Text(
            'Delete Incident Report?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppConstants.textDark,
            ),
          ),
          content: const Text(
            'Are you sure you want to permanently remove this incident report?',
            style: TextStyle(color: AppConstants.textSecondary),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppConstants.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    final IncidentProvider incidentProvider = context.read<IncidentProvider>();
    final bool success = await incidentProvider.deleteIncident(incident);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incident deleted.'),
          backgroundColor: AppConstants.textDark,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final IncidentProvider incidentProvider = context.watch<IncidentProvider>();
    final AuthProvider authProvider = context.watch<AuthProvider>();

    // Read the latest version from provider cache so status updates reflect immediately
    final IncidentModel incident =
        incidentProvider.getIncidentByIdFromCache(initialIncident.id) ??
            initialIncident;

    final bool isStaff = authProvider.isStaff;
    final bool isReporter =
        authProvider.currentUser?.uid == incident.reportedByUid;
    final bool canDelete =
        isStaff || (isReporter && incident.isSubmitted);

    return Scaffold(
      backgroundColor: AppConstants.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppConstants.scaffoldBackground,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppConstants.textDark),
        title: const Text(
          'Incident Details',
          style: TextStyle(
            color: AppConstants.textDark,
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: <Widget>[
          if (canDelete)
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: AppConstants.textDark,
              ),
              color: AppConstants.cardWhite,
              onSelected: (String value) {
                if (value == 'delete') {
                  _confirmDelete(context, incident);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        size: 20.0,
                      ),
                      SizedBox(width: 8.0),
                      Text(
                        'Delete Report',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 1. Top Header Card (Thumbnail + Title + Location + Status Badge)
              _buildHeaderCard(incident),
              const SizedBox(height: 16.0),

              // 2. Submission Date & Reporter Info Card
              _buildMetadataSection(incident),
              const SizedBox(height: 22.0),

              // 3. Status Timeline (Submitted -> In Progress -> Resolved)
              const Text(
                'Status Timeline',
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.textDark,
                ),
              ),
              const SizedBox(height: 12.0),
              _buildStatusTimeline(incident),
              const SizedBox(height: 22.0),

              // 4. Staff-Only Access Control Card (Only visible to authorized staff)
              if (isStaff) ...<Widget>[
                _buildStaffActionCard(
                  context,
                  incident,
                  incidentProvider.isSubmitting,
                ),
                const SizedBox(height: 22.0),
              ],

              // 5. Full Description Section
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.textDark,
                ),
              ),
              const SizedBox(height: 8.0),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppConstants.cardWhite,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: AppConstants.borderColor),
                ),
                child: Text(
                  incident.description,
                  style: const TextStyle(
                    fontSize: 14.0,
                    color: AppConstants.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 22.0),

              // 6. Attached Photo Section
              const Text(
                'Attached Photo',
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.textDark,
                ),
              ),
              const SizedBox(height: 10.0),
              _buildAttachedPhoto(incident),
              const SizedBox(height: 28.0),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. Builds the top summary row matching the Canvas sample (Thumbnail + Title + Location + Badge)
  Widget _buildHeaderCard(IncidentModel incident) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppConstants.cardWhite,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _buildSmallThumbnail(incident),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  incident.title,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.textDark,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  '${incident.location} • ${incident.category}',
                  style: const TextStyle(
                    fontSize: 13.0,
                    color: AppConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: 8.0),
                StatusBadge(status: incident.status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallThumbnail(IncidentModel incident) {
    if (incident.hasPhoto && incident.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Image.network(
          incident.imageUrl!,
          width: 72.0,
          height: 72.0,
          fit: BoxFit.cover,
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stackTrace,
          ) {
            return _buildFallbackBox(incident);
          },
        ),
      );
    }
    return _buildFallbackBox(incident);
  }

  Widget _buildFallbackBox(IncidentModel incident) {
    return Container(
      width: 72.0,
      height: 72.0,
      decoration: BoxDecoration(
        color: AppConstants.lightBlueSurface,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Icon(
        AppConstants.getCategoryIcon(incident.category),
        color: AppConstants.primaryBlue,
        size: 32.0,
      ),
    );
  }

  /// 2. Builds the Submitted timestamp, Reporter Name, and Staff Updater info
  Widget _buildMetadataSection(IncidentModel incident) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: AppConstants.cardWhite,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.calendar_today_outlined,
                size: 16.0,
                color: AppConstants.textSecondary,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  'Submitted on ${_formatFullDateTime(incident.createdAt)}',
                  style: const TextStyle(
                    fontSize: 13.0,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Row(
            children: <Widget>[
              const Icon(
                Icons.person_outline_rounded,
                size: 17.0,
                color: AppConstants.textSecondary,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  'Reported by ${incident.reportedByName}',
                  style: const TextStyle(
                    fontSize: 13.0,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (incident.updatedByStaffName != null &&
              incident.updatedByStaffName!.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 8.0),
            Row(
              children: <Widget>[
                const Icon(
                  Icons.verified_user_outlined,
                  size: 16.0,
                  color: AppConstants.primaryBlue,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    'Last updated by ${incident.updatedByStaffName}',
                    style: const TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 3. Builds the 3-Step Horizontal Status Timeline matching the Canvas UI
  Widget _buildStatusTimeline(IncidentModel incident) {
    final bool step1Done = true; // Always submitted
    final bool step2Active = incident.isInProgress || incident.isResolved;
    final bool step3Active = incident.isResolved;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: AppConstants.cardWhite,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Column(
        children: <Widget>[
          // Circles and connecting horizontal lines
          Row(
            children: <Widget>[
              _buildTimelineCircle(
                isActive: step1Done,
                icon: Icons.check_rounded,
              ),
              Expanded(
                child: Container(
                  height: 3.0,
                  color: step2Active
                      ? AppConstants.primaryBlue
                      : AppConstants.borderColor,
                ),
              ),
              _buildTimelineCircle(
                isActive: step2Active,
                icon: incident.isResolved
                    ? Icons.check_rounded
                    : Icons.sync_rounded,
              ),
              Expanded(
                child: Container(
                  height: 3.0,
                  color: step3Active
                      ? AppConstants.primaryBlue
                      : AppConstants.borderColor,
                ),
              ),
              _buildTimelineCircle(
                isActive: step3Active,
                icon: step3Active
                    ? Icons.check_rounded
                    : Icons.priority_high_rounded,
              ),
            ],
          ),
          const SizedBox(height: 10.0),

          // Step Titles & Timestamps
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Submitted',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.textDark,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      _formatShortDateTime(incident.createdAt),
                      style: const TextStyle(
                        fontSize: 11.0,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'In Progress',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: step2Active
                            ? AppConstants.primaryBlue
                            : AppConstants.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      step2Active
                          ? _formatShortDateTime(
                              incident.inProgressAt ?? incident.updatedAt,
                            )
                          : 'Pending',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11.0,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      'Resolved',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: step3Active
                            ? AppConstants.resolvedText
                            : AppConstants.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      step3Active
                          ? _formatShortDateTime(
                              incident.resolvedAt ?? incident.updatedAt,
                            )
                          : 'Pending',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 11.0,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCircle({
    required bool isActive,
    required IconData icon,
  }) {
    return Container(
      width: 30.0,
      height: 30.0,
      decoration: BoxDecoration(
        color: isActive ? AppConstants.primaryBlue : AppConstants.borderColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 16.0,
        color: isActive ? AppConstants.cardWhite : AppConstants.textSecondary,
      ),
    );
  }

  /// 4. Staff-Only Status Control Card (Hidden for students)
  Widget _buildStaffActionCard(
    BuildContext context,
    IncidentModel incident,
    bool isSubmitting,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppConstants.lightBlueSurface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppConstants.primaryBlue.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(
                Icons.admin_panel_settings_outlined,
                color: AppConstants.primaryBlue,
                size: 20.0,
              ),
              SizedBox(width: 8.0),
              Text(
                'Staff Resolution Controls',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          const Text(
            'Select a new status below to update this incident in real time:',
            style: TextStyle(
              fontSize: 12.5,
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 12.0),
          Row(
            children: AppConstants.allStatuses.map((String statusOption) {
              final bool isCurrent = incident.status == statusOption;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ElevatedButton(
                    onPressed: (isSubmitting || isCurrent)
                        ? null
                        : () => _handleStatusUpdate(
                              context,
                              incident,
                              statusOption,
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrent
                          ? AppConstants.primaryBlue
                          : AppConstants.cardWhite,
                      foregroundColor: isCurrent
                          ? AppConstants.cardWhite
                          : AppConstants.textDark,
                      disabledBackgroundColor: isCurrent
                          ? AppConstants.primaryBlue
                          : AppConstants.cardWhite.withValues(alpha: 0.6),
                      disabledForegroundColor: isCurrent
                          ? AppConstants.cardWhite
                          : AppConstants.textSecondary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        side: BorderSide(
                          color: isCurrent
                              ? AppConstants.primaryBlue
                              : AppConstants.borderColor,
                        ),
                      ),
                    ),
                    child: Text(
                      statusOption,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 5. Builds the large Attached Photo preview (or a clean empty state if no photo was attached)
  Widget _buildAttachedPhoto(IncidentModel incident) {
    if (incident.hasPhoto && incident.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Image.network(
          incident.imageUrl!,
          width: double.infinity,
          height: 220.0,
          fit: BoxFit.cover,
          loadingBuilder: (
            BuildContext context,
            Widget child,
            ImageChunkEvent? loadingProgress,
          ) {
            if (loadingProgress == null) return child;
            return Container(
              width: double.infinity,
              height: 220.0,
              decoration: BoxDecoration(
                color: AppConstants.cardWhite,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: AppConstants.borderColor),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppConstants.primaryBlue,
                ),
              ),
            );
          },
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stackTrace,
          ) {
            return _buildNoPhotoBox('Unable to load image from Storage.');
          },
        ),
      );
    }

    return _buildNoPhotoBox('No photo was attached to this incident report.');
  }

  Widget _buildNoPhotoBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: AppConstants.cardWhite,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.image_not_supported_outlined,
            color: AppConstants.textSecondary,
            size: 32.0,
          ),
          const SizedBox(height: 8.0),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.0,
              color: AppConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
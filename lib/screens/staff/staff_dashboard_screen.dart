import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/incident_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../utils/app_constants.dart';
import '../../widgets/incident_card.dart';
import '../shared/incident_detail_screen.dart';
import '../student/create_incident_screen.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  int _selectedTabIndex = 0; // 0: Staff Queue & Analytics, 1: Staff Profile
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openIncidentDetails(IncidentModel incident) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => IncidentDetailScreen(
          initialIncident: incident,
        ),
      ),
    );
  }

  void _openCreateIncidentScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => CreateIncidentScreen(
          onReportSubmitted: () {
            Navigator.of(context).pop();
            setState(() {
              _selectedTabIndex = 0;
            });
          },
        ),
      ),
    );
  }

  Future<void> _quickUpdateStatus(
    IncidentModel incident,
    String newStatus,
  ) async {
    if (incident.status == newStatus) return;

    final AuthProvider authProvider = context.read<AuthProvider>();
    final IncidentProvider incidentProvider = context.read<IncidentProvider>();

    final bool success = await incidentProvider.updateIncidentStatus(
      incidentId: incident.id,
      newStatus: newStatus,
      staffName: authProvider.currentUser?.name ?? 'Authorized Staff',
      isStaffUser: authProvider.isStaff,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Updated "${incident.title}" to $newStatus',
          ),
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

  @override
  Widget build(BuildContext context) {
    final AuthProvider authProvider = context.watch<AuthProvider>();
    final IncidentProvider incidentProvider = context.watch<IncidentProvider>();
    final UserModel? currentUser = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppConstants.scaffoldBackground,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedTabIndex,
          children: <Widget>[
            _buildStaffQueueTab(currentUser, incidentProvider),
            _buildStaffProfileTab(currentUser, authProvider, incidentProvider),
          ],
        ),
      ),
      bottomNavigationBar: _buildStaffBottomNavBar(),
    );
  }

  
  // TAB 0: STAFF OPERATIONS DASHBOARD & INCIDENT QUEUE
  
  Widget _buildStaffQueueTab(
    UserModel? user,
    IncidentProvider incidentProvider,
  ) {
    final String firstName = user?.firstName ?? 'Staff';
    final List<IncidentModel> filteredList = incidentProvider.filteredIncidents;

    final List<String> statusOptions = <String>[
      'All',
      ...AppConstants.allStatuses,
    ];
    final List<String> categoryOptions = <String>[
      'All',
      ...AppConstants.categories,
    ];

    return RefreshIndicator(
      color: AppConstants.primaryBlue,
      onRefresh: incidentProvider.refreshIncidents,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 1. Staff Greeting Header + Verified Role Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              'Hello, $firstName 👋',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 22.0,
                                fontWeight: FontWeight.w800,
                                color: AppConstants.textDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 3.0,
                            ),
                            decoration: BoxDecoration(
                              color: AppConstants.lightBlueSurface,
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: AppConstants.primaryBlue.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  Icons.verified_user_rounded,
                                  size: 13.0,
                                  color: AppConstants.primaryBlue,
                                ),
                                SizedBox(width: 4.0),
                                Text(
                                  'Staff Portal',
                                  style: TextStyle(
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w700,
                                    color: AppConstants.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4.0),
                      const Text(
                        'Review campus reports and update resolution statuses.',
                        style: TextStyle(
                          fontSize: 13.0,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _selectedTabIndex = 1),
                  child: CircleAvatar(
                    radius: 20.0,
                    backgroundColor: AppConstants.primaryBlue,
                    child: Text(
                      firstName.isNotEmpty ? firstName[0].toUpperCase() : 'S',
                      style: const TextStyle(
                        color: AppConstants.cardWhite,
                        fontWeight: FontWeight.w700,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),

            // 2. Campus-Wide Report Summary (4 Stat Cards)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  'Campus Overview',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.textDark,
                  ),
                ),
                if (incidentProvider.selectedCategory != 'All' ||
                    incidentProvider.selectedStatus != 'All' ||
                    incidentProvider.searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      incidentProvider.clearFilters();
                    },
                    child: const Text(
                      'Reset Filters',
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.primaryBlue,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12.0),
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildStatCard(
                    count: incidentProvider.totalCount.toString(),
                    label: 'Total',
                    icon: Icons.assignment_outlined,
                    iconColor: AppConstants.primaryBlue,
                    bgColor: AppConstants.lightBlueSurface,
                    onTap: () => incidentProvider.setSelectedStatus('All'),
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: _buildStatCard(
                    count: incidentProvider.submittedCount.toString(),
                    label: 'Submitted',
                    icon: Icons.error_outline_rounded,
                    iconColor: AppConstants.submittedText,
                    bgColor: AppConstants.submittedBg,
                    onTap: () => incidentProvider.setSelectedStatus(
                      AppConstants.statusSubmitted,
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: _buildStatCard(
                    count: incidentProvider.inProgressCount.toString(),
                    label: 'In Progress',
                    icon: Icons.access_time_filled_rounded,
                    iconColor: AppConstants.inProgressText,
                    bgColor: AppConstants.inProgressBg,
                    onTap: () => incidentProvider.setSelectedStatus(
                      AppConstants.statusInProgress,
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: _buildStatCard(
                    count: incidentProvider.resolvedCount.toString(),
                    label: 'Resolved',
                    icon: Icons.check_circle_rounded,
                    iconColor: AppConstants.resolvedText,
                    bgColor: AppConstants.resolvedBg,
                    onTap: () => incidentProvider.setSelectedStatus(
                      AppConstants.statusResolved,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),

            // 3. Search Bar
            TextField(
              controller: _searchController,
              onChanged: incidentProvider.setSearchQuery,
              decoration: InputDecoration(
                hintText: 'Search incidents by title, block, or category...',
                hintStyle: const TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 13.5,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppConstants.textSecondary,
                ),
                suffixIcon: incidentProvider.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          size: 18.0,
                          color: AppConstants.textSecondary,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          incidentProvider.setSearchQuery('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppConstants.cardWhite,
                contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.0),
                  borderSide: const BorderSide(color: AppConstants.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.0),
                  borderSide: const BorderSide(color: AppConstants.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.0),
                  borderSide: const BorderSide(
                    color: AppConstants.primaryBlue,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12.0),

            // 4. Status Filter Chips
            SizedBox(
              height: 36.0,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: statusOptions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8.0),
                itemBuilder: (BuildContext context, int index) {
                  final String status = statusOptions[index];
                  final bool isSelected =
                      incidentProvider.selectedStatus == status;
                  return _buildFilterChip(
                    label: status,
                    isSelected: isSelected,
                    onTap: () => incidentProvider.setSelectedStatus(status),
                  );
                },
              ),
            ),
            const SizedBox(height: 10.0),

            // 5. Category Filter Chips
            SizedBox(
              height: 34.0,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categoryOptions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8.0),
                itemBuilder: (BuildContext context, int index) {
                  final String category = categoryOptions[index];
                  final bool isSelected =
                      incidentProvider.selectedCategory == category;
                  return _buildFilterChip(
                    label: category == 'All' ? 'All Categories' : category,
                    isSelected: isSelected,
                    onTap: () => incidentProvider.setSelectedCategory(category),
                  );
                },
              ),
            ),
            const SizedBox(height: 18.0),

            // 6. Incident Queue List with Quick Staff Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Incident Queue (${filteredList.length})',
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.textDark,
                  ),
                ),
                const Text(
                  'Tap card for full timeline',
                  style: TextStyle(
                    fontSize: 12.0,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),

            if (incidentProvider.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppConstants.primaryBlue,
                  ),
                ),
              )
            else if (filteredList.isEmpty)
              _buildEmptyState(
                'No campus incidents match your current filter selection.',
              )
            else
              Column(
                children: filteredList.map((IncidentModel incident) {
                  return _buildStaffIncidentItem(
                    incident,
                    incidentProvider.isSubmitting,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  // Wraps IncidentCard with a quick-action footer bar so staff can advance statuses in 1 tap
  Widget _buildStaffIncidentItem(
    IncidentModel incident,
    bool isSubmitting,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
      decoration: BoxDecoration(
        color: AppConstants.cardWhite,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Column(
        children: <Widget>[
          IncidentCard(
            incident: incident,
            onTap: () => _openIncidentDetails(incident),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            decoration: const BoxDecoration(
              color: AppConstants.scaffoldBackground,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(16.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Reported by ${incident.reportedByName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.0,
                      color: AppConstants.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Row(
                  children: <Widget>[
                    if (!incident.isInProgress && !incident.isResolved)
                      TextButton.icon(
                        onPressed: isSubmitting
                            ? null
                            : () => _quickUpdateStatus(
                                  incident,
                                  AppConstants.statusInProgress,
                                ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 4.0,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(
                          Icons.sync_rounded,
                          size: 15.0,
                          color: AppConstants.primaryBlue,
                        ),
                        label: const Text(
                          'Mark In Progress',
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.primaryBlue,
                          ),
                        ),
                      ),
                    if (!incident.isResolved) ...<Widget>[
                      const SizedBox(width: 6.0),
                      TextButton.icon(
                        onPressed: isSubmitting
                            ? null
                            : () => _quickUpdateStatus(
                                  incident,
                                  AppConstants.statusResolved,
                                ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 4.0,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 15.0,
                          color: AppConstants.resolvedText,
                        ),
                        label: const Text(
                          'Resolve',
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.resolvedText,
                          ),
                        ),
                      ),
                    ] else
                      const Row(
                        children: <Widget>[
                          Icon(
                            Icons.verified_rounded,
                            size: 15.0,
                            color: AppConstants.resolvedText,
                          ),
                          SizedBox(width: 4.0),
                          Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w700,
                              color: AppConstants.resolvedText,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  
  // TAB 1: STAFF PROFILE & ACCOUNT OVERVIEW
  
  Widget _buildStaffProfileTab(
    UserModel? user,
    AuthProvider authProvider,
    IncidentProvider incidentProvider,
  ) {
    final String fullName = user?.name ?? 'Authorized Staff';
    final String email = user?.email ?? 'staff@alueducation.com';
    final String department = user?.department ?? 'Facilities Management';
    final String location = user?.location ?? 'Kigali, Rwanda';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text(
                'Staff Profile',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w800,
                  color: AppConstants.textDark,
                ),
              ),
              IconButton(
                tooltip: 'Sign Out',
                onPressed: () async {
                  await authProvider.signOut();
                },
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),

          // Staff Profile Card
          Container(
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              color: AppConstants.cardWhite,
              borderRadius: BorderRadius.circular(18.0),
              border: Border.all(color: AppConstants.borderColor),
            ),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 32.0,
                      backgroundColor: AppConstants.lightBlueSurface,
                      child: Text(
                        fullName.isNotEmpty ? fullName[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.w800,
                          color: AppConstants.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  fullName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17.0,
                                    fontWeight: FontWeight.w700,
                                    color: AppConstants.textDark,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 3.0,
                                ),
                                decoration: BoxDecoration(
                                  color: AppConstants.lightBlueSurface,
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: const Text(
                                  'Staff',
                                  style: TextStyle(
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w700,
                                    color: AppConstants.primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6.0),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 13.0,
                              color: AppConstants.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            '$department • $location',
                            style: const TextStyle(
                              fontSize: 12.5,
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
          ),
          const SizedBox(height: 20.0),

          // Sign Out Button
          SizedBox(
            width: double.infinity,
            height: 48.0,
            child: OutlinedButton.icon(
              onPressed: () async {
                await authProvider.signOut();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.0),
                ),
              ),
              icon: const Icon(Icons.logout_rounded, size: 20.0),
              label: const Text(
                'Sign Out of Staff Portal',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  
  // SHARED HELPERS & BOTTOM NAVIGATION BAR
  
  Widget _buildStatCard({
    required String count,
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 6.0),
        decoration: BoxDecoration(
          color: bgColor.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: bgColor),
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, color: iconColor, size: 22.0),
            const SizedBox(height: 6.0),
            Text(
              count,
              style: const TextStyle(
                fontSize: 17.0,
                fontWeight: FontWeight.w800,
                color: AppConstants.textDark,
              ),
            ),
            const SizedBox(height: 2.0),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryBlue : AppConstants.cardWhite,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: isSelected
                ? AppConstants.primaryBlue
                : AppConstants.borderColor,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? AppConstants.cardWhite
                  : AppConstants.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 20.0),
      decoration: BoxDecoration(
        color: AppConstants.cardWhite,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.inbox_outlined,
            color: AppConstants.primaryBlue,
            size: 38.0,
          ),
          const SizedBox(height: 10.0),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppConstants.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffBottomNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: const BoxDecoration(
        color: AppConstants.cardWhite,
        border: Border(top: BorderSide(color: AppConstants.borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavBarItem(
              icon: Icons.dashboard_rounded,
              label: 'Dashboard',
              isSelected: _selectedTabIndex == 0,
              onTap: () => setState(() => _selectedTabIndex = 0),
            ),
            GestureDetector(
              onTap: _openCreateIncidentScreen,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 44.0,
                    height: 44.0,
                    decoration: BoxDecoration(
                      color: AppConstants.primaryBlue,
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color:
                              AppConstants.primaryBlue.withValues(alpha: 0.3),
                          blurRadius: 8.0,
                          offset: const Offset(0.0, 3.0),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: AppConstants.cardWhite,
                      size: 26.0,
                    ),
                  ),
                  const SizedBox(height: 3.0),
                  const Text(
                    'Log Issue',
                    style: TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            _buildNavBarItem(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              isSelected: _selectedTabIndex == 1,
              onTap: () => setState(() => _selectedTabIndex = 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBarItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              color: isSelected
                  ? AppConstants.primaryBlue
                  : AppConstants.textSecondary,
              size: 24.0,
            ),
            const SizedBox(height: 4.0),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppConstants.primaryBlue
                    : AppConstants.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
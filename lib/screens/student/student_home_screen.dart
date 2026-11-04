import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/incident_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../utils/app_constants.dart';
import '../../widgets/incident_card.dart';
import '../shared/incident_detail_screen.dart';
import 'create_incident_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _selectedTabIndex = 0; // 0: Home, 1: Reports (Browse/Search), 2: Profile (My Reports)
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _openIncidentDetails(IncidentModel incident) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => IncidentDetailScreen(
          initialIncident: incident,
        ),
      ),
    );
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
            _buildHomeTab(currentUser, incidentProvider),
            _buildBrowseReportsTab(incidentProvider),
            _buildProfileMyReportsTab(currentUser, authProvider, incidentProvider),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // =========================================================
  // TAB 0: HOME DASHBOARD (Matches Left Phone in Canvas UI)
  // =========================================================
  Widget _buildHomeTab(
    UserModel? user,
    IncidentProvider incidentProvider,
  ) {
    final String firstName = user?.firstName ?? 'Student';
    final String uid = user?.uid ?? '';

    final int myTotal = uid.isNotEmpty
        ? incidentProvider.getUserTotalCount(uid)
        : incidentProvider.totalCount;
    final int inProgress = incidentProvider.inProgressCount;
    final int resolved = incidentProvider.resolvedCount;
    final int submitted = incidentProvider.submittedCount;

    final List<IncidentModel> recentList = incidentProvider.recentIncidents;

    return RefreshIndicator(
      color: AppConstants.primaryBlue,
      onRefresh: incidentProvider.refreshIncidents,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 1. Top Greeting Header ("Hello, Amina 👋" + Notification + Avatar)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Hello, $firstName 👋',
                        style: const TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.w800,
                          color: AppConstants.textDark,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      const Text(
                        'Help make our campus safer.',
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textDark,
                        ),
                      ),
                      const Text(
                        'Report issues and track their resolution.',
                        style: TextStyle(
                          fontSize: 13.0,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: <Widget>[
                    Container(
                      width: 40.0,
                      height: 40.0,
                      decoration: BoxDecoration(
                        color: AppConstants.cardWhite,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppConstants.borderColor),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: AppConstants.textDark,
                        size: 22.0,
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTabIndex = 2;
                        });
                      },
                      child: CircleAvatar(
                        radius: 20.0,
                        backgroundColor: AppConstants.primaryBlue,
                        child: Text(
                          firstName.isNotEmpty
                              ? firstName[0].toUpperCase()
                              : 'S',
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
              ],
            ),
            const SizedBox(height: 20.0),

            // 2. Hero Action Banner ("See an issue on campus? + Report an Issue")
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[
                    AppConstants.primaryBlue,
                    AppConstants.lightBlueAccent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppConstants.primaryBlue.withValues(alpha: 0.25),
                    blurRadius: 12.0,
                    offset: const Offset(0.0, 6.0),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'See an issue\non campus?',
                              style: TextStyle(
                                color: AppConstants.cardWhite,
                                fontSize: 20.0,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              'Report it and help improve\nour learning environment.',
                              style: TextStyle(
                                color: Color(0xFFE1F5FE),
                                fontSize: 12.5,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 68.0,
                        height: 68.0,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: const Icon(
                          Icons.domain_rounded,
                          color: AppConstants.cardWhite,
                          size: 38.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  InkWell(
                    onTap: _openCreateIncidentScreen,
                    borderRadius: BorderRadius.circular(30.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14.0,
                        vertical: 10.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.cardWhite,
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      child: const Row(
                        children: <Widget>[
                          CircleAvatar(
                            radius: 13.0,
                            backgroundColor: AppConstants.primaryBlue,
                            child: Icon(
                              Icons.add_rounded,
                              color: AppConstants.cardWhite,
                              size: 18.0,
                            ),
                          ),
                          SizedBox(width: 10.0),
                          Expanded(
                            child: Text(
                              'Report an Issue',
                              style: TextStyle(
                                color: AppConstants.primaryBlue,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.0,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: AppConstants.primaryBlue,
                            size: 20.0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            // 3. Report Summary Section (4 Stat Cards)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  'Report Summary',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.textDark,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTabIndex = 1;
                    });
                  },
                  child: const Text(
                    'See all',
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
                  child: _buildSummaryStatCard(
                    count: myTotal.toString(),
                    label: 'My Reports',
                    icon: Icons.description_outlined,
                    iconColor: AppConstants.primaryBlue,
                    bgColor: AppConstants.lightBlueSurface,
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: _buildSummaryStatCard(
                    count: inProgress.toString(),
                    label: 'In Progress',
                    icon: Icons.access_time_filled_rounded,
                    iconColor: AppConstants.inProgressText,
                    bgColor: AppConstants.inProgressBg,
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: _buildSummaryStatCard(
                    count: resolved.toString(),
                    label: 'Resolved',
                    icon: Icons.check_circle_rounded,
                    iconColor: AppConstants.resolvedText,
                    bgColor: AppConstants.resolvedBg,
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: _buildSummaryStatCard(
                    count: submitted.toString(),
                    label: 'Submitted',
                    icon: Icons.error_rounded,
                    iconColor: AppConstants.submittedText,
                    bgColor: AppConstants.submittedBg,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),

            // 4. Recent Reports Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  'Recent Reports',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.textDark,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTabIndex = 1;
                    });
                  },
                  child: const Text(
                    'See all',
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

            if (incidentProvider.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppConstants.primaryBlue,
                  ),
                ),
              )
            else if (recentList.isEmpty)
              _buildEmptyState(
                'No campus incidents reported yet.\nTap "Report an Issue" above to submit the first report!',
              )
            else
              Column(
                children: recentList.map((IncidentModel incident) {
                  return IncidentCard(
                    incident: incident,
                    onTap: () => _openIncidentDetails(incident),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStatCard({
    required String count,
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
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
    );
  }

  // =========================================================
  // TAB 1: BROWSE, SEARCH & FILTER ALL REPORTS
  // =========================================================
  Widget _buildBrowseReportsTab(IncidentProvider incidentProvider) {
    final List<IncidentModel> filteredList = incidentProvider.filteredIncidents;
    final List<String> categoryOptions = <String>[
      'All',
      ...AppConstants.categories,
    ];
    final List<String> statusOptions = <String>[
      'All',
      ...AppConstants.allStatuses,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Title & Clear Filters Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text(
                'Browse Incidents',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w800,
                  color: AppConstants.textDark,
                ),
              ),
              if (incidentProvider.selectedCategory != 'All' ||
                  incidentProvider.selectedStatus != 'All' ||
                  incidentProvider.searchQuery.isNotEmpty)
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    incidentProvider.clearFilters();
                  },
                  child: const Text(
                    'Reset Filters',
                    style: TextStyle(
                      color: AppConstants.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: incidentProvider.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Search by title, location, or keyword...',
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

          // Horizontal Status Filter Pills
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

          // Horizontal Category Filter Pills
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
          const SizedBox(height: 14.0),

          // Filtered Incident List
          Expanded(
            child: filteredList.isEmpty
                ? SingleChildScrollView(
                    child: _buildEmptyState(
                      'No incidents match your current search or filters.',
                    ),
                  )
                : RefreshIndicator(
                    color: AppConstants.primaryBlue,
                    onRefresh: incidentProvider.refreshIncidents,
                    child: ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (BuildContext context, int index) {
                        final IncidentModel incident = filteredList[index];
                        return IncidentCard(
                          incident: incident,
                          onTap: () => _openIncidentDetails(incident),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TAB 2: MY REPORTS & PROFILE (Matches Bottom-Right Phone in Canvas UI)
  // =========================================================
  Widget _buildProfileMyReportsTab(
    UserModel? user,
    AuthProvider authProvider,
    IncidentProvider incidentProvider,
  ) {
    final String uid = user?.uid ?? '';
    final String fullName = user?.name ?? 'Campus Student';
    final String department = user?.department ?? 'Software Engineering';
    final String location = user?.location ?? 'Kigali, Rwanda';
    final String roleLabel = (user?.isStaff ?? false) ? 'Staff' : 'Student';

    final int myTotal = incidentProvider.getUserTotalCount(uid);
    final int myInProgress = incidentProvider.getUserInProgressCount(uid);
    final int myResolved = incidentProvider.getUserResolvedCount(uid);

    final List<IncidentModel> myFilteredReports =
        incidentProvider.getFilteredUserIncidents(uid);

    final List<String> statusTabs = <String>[
      'All',
      ...AppConstants.allStatuses,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 1. Top Bar ("My Reports" + Logout Icon Button)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text(
                'My Reports',
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
          const SizedBox(height: 12.0),

          // 2. Student Profile Card (Avatar + Name + Student Badge + Department + Location)
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppConstants.cardWhite,
              borderRadius: BorderRadius.circular(18.0),
              border: Border.all(color: AppConstants.borderColor),
            ),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 30.0,
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
                                fontSize: 16.5,
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
                            child: Text(
                              roleLabel,
                              style: const TextStyle(
                                fontSize: 11.0,
                                fontWeight: FontWeight.w700,
                                color: AppConstants.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6.0),
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.school_outlined,
                            size: 15.0,
                            color: AppConstants.textSecondary,
                          ),
                          const SizedBox(width: 6.0),
                          Expanded(
                            child: Text(
                              department,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppConstants.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4.0),
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.location_on_outlined,
                            size: 15.0,
                            color: AppConstants.textSecondary,
                          ),
                          const SizedBox(width: 6.0),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppConstants.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // 3. Three Counter Boxes (Total Reports | In Progress | Resolved)
          Row(
            children: <Widget>[
              Expanded(
                child: _buildProfileCounterBox(
                  count: myTotal.toString(),
                  label: 'Total Reports',
                  textColor: AppConstants.primaryBlue,
                  bgColor: AppConstants.lightBlueSurface,
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: _buildProfileCounterBox(
                  count: myInProgress.toString(),
                  label: 'In Progress',
                  textColor: AppConstants.inProgressText,
                  bgColor: AppConstants.inProgressBg,
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: _buildProfileCounterBox(
                  count: myResolved.toString(),
                  label: 'Resolved',
                  textColor: AppConstants.resolvedText,
                  bgColor: AppConstants.resolvedBg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18.0),

          // 4. Filter Tabs (All | Submitted | In Progress | Resolved)
          SizedBox(
            height: 36.0,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: statusTabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8.0),
              itemBuilder: (BuildContext context, int index) {
                final String tab = statusTabs[index];
                final bool isSelected = incidentProvider.selectedStatus == tab;
                return _buildFilterChip(
                  label: tab,
                  isSelected: isSelected,
                  onTap: () => incidentProvider.setSelectedStatus(tab),
                );
              },
            ),
          ),
          const SizedBox(height: 16.0),

          // 5. List of the Student's Submitted Incidents
          if (myFilteredReports.isEmpty)
            _buildEmptyState('You have no incident reports in this category.')
          else
            Column(
              children: myFilteredReports.map((IncidentModel incident) {
                return IncidentCard(
                  incident: incident,
                  onTap: () => _openIncidentDetails(incident),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileCounterBox({
    required String count,
    required String label,
    required Color textColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: bgColor),
      ),
      child: Column(
        children: <Widget>[
          Text(
            count,
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SHARED UI HELPERS & BOTTOM NAVIGATION BAR
  // =========================================================
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

  /// Builds the 4-item Bottom Navigation Bar matching the Canvas UI (Home | Reports | + Report | Profile)
  Widget _buildBottomNavBar() {
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
              icon: Icons.home_rounded,
              label: 'Home',
              isSelected: _selectedTabIndex == 0,
              onTap: () => setState(() => _selectedTabIndex = 0),
            ),
            _buildNavBarItem(
              icon: Icons.description_outlined,
              label: 'Reports',
              isSelected: _selectedTabIndex == 1,
              onTap: () => setState(() => _selectedTabIndex = 1),
            ),
            // Center Circular "+" Report Button
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
                    'Report',
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
              isSelected: _selectedTabIndex == 2,
              onTap: () => setState(() => _selectedTabIndex = 2),
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
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
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
import 'package:ferugson/pages/player/player_self_assessment_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../api/services.dart';
import '../../models/models.dart';
import 'package:google_fonts/google_fonts.dart';

class PlayerDashboard extends StatefulWidget {
  const PlayerDashboard({super.key});

  @override
  State<PlayerDashboard> createState() => _PlayerDashboardState();
}

class _PlayerDashboardState extends State<PlayerDashboard> {
  bool _isLoading = true;
  List<Session> _upcomingSessions = [];
  List<AIInsight> _aiInsights = [];
  List<Performance> _recentPerformances = [];
  FatigueReport? _latestFatigueReport;
  Player? _player;

  // Theme colors
  final primaryColor = Color(0xFFC70101); // Rich red
  final accentColor = Color(0xFFFFFFFF); // White

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _logout() async {
    try {
      // Show confirmation dialog
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('LOGOUT'),
            ),
          ],
        ),
      );

      // If user confirmed logout
      if (shouldLogout == true) {
        setState(() {
          _isLoading = true;
        });

        final firebaseService =
            Provider.of<FirebaseService>(context, listen: false);
        await firebaseService.signOut();

        if (mounted) {
          // Navigate to login page and clear navigation stack
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final userService = UserService(firebaseService);
      final sessionService = SessionService(firebaseService);
      final aiInsightService = AIInsightService(firebaseService);
      final performanceService = PerformanceService(firebaseService);
      final fatigueReportService = FatigueReportService(firebaseService);

      // Get current user
      final user = await userService.getCurrentUser();
      if (user is Player) {
        _player = user;
      } else {
        throw Exception('Current user is not a player');
      }

      // Load upcoming sessions
      _upcomingSessions =
          await sessionService.getUpcomingSessionsForPlayer(_player!.id);

      // Load AI insights
      _aiInsights = await aiInsightService.getAIInsightsForPlayer(_player!.id);

      // Load recent performances
      _recentPerformances =
          await performanceService.getPerformancesForPlayer(_player!.id);
      _recentPerformances = _recentPerformances.take(5).toList();

      // Load latest fatigue report
      _latestFatigueReport = await fatigueReportService
          .getLatestFatigueReportForPlayer(_player!.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading dashboard: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: _player?.photoUrl != null
                        ? NetworkImage(_player!.photoUrl!)
                        : null,
                    child: _player?.photoUrl == null
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _player?.name ?? 'Player',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    _player?.email ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              selected: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Training Sessions'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to training sessions page
              },
            ),
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('My Performance'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to performance page
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Report Fatigue'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to fatigue reporting page
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to settings page
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildFatigueStatusCard(),
                  const SizedBox(height: 24),
                  _buildUpcomingSessions(),
                  const SizedBox(height: 24),
                  _buildAIInsights(),
                  const SizedBox(height: 24),
                  _buildPerformanceMetrics(),
                ],
              ),
            ),
    );
  }

  Widget _buildFatigueStatusCard() {
    int fatigueLevel = (_latestFatigueReport?.fatigueLevel as int?) ?? 0;
    String fatigueDesc = 'No fatigue data';
    Color fatigueColor = Colors.grey;

    if (_latestFatigueReport != null) {
      if (fatigueLevel <= 3) {
        fatigueDesc = 'Low fatigue';
        fatigueColor = Colors.green;
      } else if (fatigueLevel <= 6) {
        fatigueDesc = 'Moderate fatigue';
        fatigueColor = Colors.orange;
      } else {
        fatigueDesc = 'High fatigue';
        fatigueColor = Colors.red;
      }
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: fatigueColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Current Fatigue Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fatigueDesc,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: fatigueColor,
                      ),
                    ),
                    if (_latestFatigueReport != null)
                      Text(
                        'Reported on ${DateFormat('MMM d, yyyy').format(_latestFatigueReport!.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
                if (_latestFatigueReport != null)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: fatigueColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _latestFatigueReport!.fatigueLevel.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: fatigueColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Add fatigue trend visualization based on AI predictions
            if (_aiInsights.isNotEmpty && _latestFatigueReport != null)
              _buildFatiguePrediction(),

            if (_latestFatigueReport == null)
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Navigate to fatigue reporting page
                },
                icon: const Icon(Icons.add),
                label: const Text('Report Fatigue Level'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFatiguePrediction() {
    // Find fatigue-related AI insights
    final fatigueInsights = _aiInsights
        .where((insight) => insight.type == InsightType.fatigueManagement)
        .toList();

    if (fatigueInsights.isEmpty) return const SizedBox.shrink();

    final latestFatigueInsight = fatigueInsights.first;
    final supportingData = latestFatigueInsight.supportingData;

    if (supportingData == null) return const SizedBox.shrink();

    final fatigueLevel = supportingData['fatigue_level'] ?? 0;

    // Create a simple visualization for the AI-predicted fatigue trend
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'AI Fatigue Prediction',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'AI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fatigueLevel / 10,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor:
                AlwaysStoppedAnimation<Color>(_getFatigueColor(fatigueLevel)),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Current: ${_latestFatigueReport!.fatigueLevel}/10',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Predicted: $fatigueLevel/10',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _getFatigueColor(fatigueLevel),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getFatigueColor(int level) {
    if (level <= 3) return Colors.green;
    if (level <= 6) return Colors.orange;
    return Colors.red;
  }

  Widget _buildUpcomingSessions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upcoming Sessions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to all sessions page
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_upcomingSessions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text('No upcoming sessions'),
                ),
              )
            else
              ..._upcomingSessions
                  .take(3)
                  .map((session) => _buildSessionItem(session))
                  .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionItem(Session session) {
    // Check if player has already submitted self-assessment
    void _checkAndNavigateToSelfAssessment() async {
      try {
        final firebaseService =
            Provider.of<FirebaseService>(context, listen: false);
        final selfAssessmentService = SelfAssessmentService(firebaseService);

        // Check if player already has a self-assessment for this session
        final assessment =
            await selfAssessmentService.getSelfAssessmentForSession(
          _player!.id,
          session.id,
        );

        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PlayerSelfAssessmentPage(
                session: session,
                onComplete: (assessment) {
                  // Refresh dashboard data after assessment is submitted
                  _loadDashboardData();
                },
              ),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }

    // Format session date
    final dateFormat = DateFormat('EEE, MMM d, yyyy • h:mm a');
    final sessionDate = dateFormat.format(session.dateTime);

    // Determine player confirmation status
    final confirmationStatus =
        session.confirmationStatus[_player!.id] ?? ConfirmationStatus.pending;

    Color statusColor;
    String statusText;

    switch (confirmationStatus) {
      case ConfirmationStatus.confirmed:
        statusColor = Colors.green;
        statusText = 'Confirmed';
        break;
      case ConfirmationStatus.declined:
        statusColor = Colors.red;
        statusText = 'Declined';
        break;
      case ConfirmationStatus.pending:
      default:
        statusColor = Colors.orange;
        statusText = 'Pending';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () {
          _showSessionDetails(session);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    session.type == SessionType.training
                        ? Icons.fitness_center
                        : Icons.sports_soccer,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      session.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    session.location,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    sessionDate,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _checkAndNavigateToSelfAssessment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      session.confirmationStatus[_player!.id] ==
                              ConfirmationStatus.confirmed
                          ? 'VIEW ASSESSMENT'
                          : 'SUBMIT & CONFIRM',
                      style: GoogleFonts.oswald(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSessionDetails(Session session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _buildSessionDetailsSheet(
          session,
          scrollController,
        ),
      ),
    );
  }

  Widget _buildSessionDetailsSheet(
      Session session, ScrollController scrollController) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final sessionDate = dateFormat.format(session.dateTime);
    final sessionTime = timeFormat.format(session.dateTime);

    return Container(
      padding: const EdgeInsets.all(16),
      child: ListView(
        controller: scrollController,
        children: [
          // Header handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            session.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              session.type == SessionType.training ? 'Training' : 'Match',
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Date & Time
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date & Time',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        sessionDate,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        sessionTime,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Location
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Location',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        session.location,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Training focus or opponent
          if (session.type == SessionType.training &&
              session.trainingFocus != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Training Focus',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      session.trainingFocus
                          .toString()
                          .split('.')
                          .last
                          .toUpperCase(),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.speed, color: Colors.blue, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Intensity: ${session.intensity}/10',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else if (session.type == SessionType.match &&
              session.opponentTeam != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Opponent',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      session.opponentTeam!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Coach comments
          if (session.coachComments != null &&
              session.coachComments!.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Coach Comments',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      session.coachComments!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      final firebaseService =
                          Provider.of<FirebaseService>(context, listen: false);
                      final selfAssessmentService =
                          SelfAssessmentService(firebaseService);

                      Navigator.of(context)
                          .pop(); // Close the session details sheet
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PlayerSelfAssessmentPage(
                            session: session,
                            onComplete: (assessment) {
                              // Refresh dashboard data after assessment is submitted
                              _loadDashboardData();
                            },
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    session.confirmationStatus[_player!.id] ==
                            ConfirmationStatus.confirmed
                        ? 'VIEW ASSESSMENT'
                        : 'SUBMIT & CONFIRM',
                    style: GoogleFonts.oswald(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'AI Insights',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to all insights page
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _aiInsights.isEmpty
            ? const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'No AI insights at this time',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              )
            : Column(
                children: _aiInsights
                    .take(2)
                    .map((insight) => _buildInsightCard(insight))
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildInsightCard(AIInsight insight) {
    IconData insightIcon;
    Color insightColor;

    switch (insight.type) {
      case InsightType.injuryRisk:
        insightIcon = Icons.local_hospital;
        insightColor = Colors.red;
        break;
      case InsightType.fatigueManagement:
        insightIcon = Icons.battery_alert;
        insightColor = Colors.orange;
        break;
      case InsightType.performanceImprovement:
        insightIcon = Icons.trending_up;
        insightColor = Colors.blue;
        break;
      case InsightType.restRecommendation:
        insightIcon = Icons.hotel;
        insightColor = Colors.purple;
        break;
      default:
        insightIcon = Icons.insights;
        insightColor = Colors.teal;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: CircleAvatar(
              backgroundColor: insightColor.withOpacity(0.2),
              child: Icon(
                insightIcon,
                color: insightColor,
              ),
            ),
            title: Text(
              insight.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(insight.description),
            trailing: insight.isAcknowledged
                ? const Icon(Icons.check_circle, color: Colors.green)
                : TextButton(
                    onPressed: () async {
                      try {
                        final firebaseService = Provider.of<FirebaseService>(
                            context,
                            listen: false);
                        final aiInsightService =
                            AIInsightService(firebaseService);
                        await aiInsightService.acknowledgeInsight(insight.id);
                        _loadDashboardData();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Error acknowledging insight: ${e.toString()}')),
                        );
                      }
                    },
                    child: const Text('Got it'),
                  ),
          ),

          // Add visualization based on insight type and supporting data
          if (insight.supportingData != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildInsightVisualization(insight),
            ),
        ],
      ),
    );
  }

  Widget _buildInsightVisualization(AIInsight insight) {
    switch (insight.type) {
      case InsightType.injuryRisk:
        return _buildInjuryRiskViz(insight);
      case InsightType.performanceImprovement:
        return _buildPerformanceImprovementViz(insight);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInjuryRiskViz(AIInsight insight) {
    final data = insight.supportingData;
    if (data == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Risk Factors',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Icon(Icons.healing, color: Colors.red),
                  const SizedBox(height: 4),
                  const Text('Previous Injuries'),
                  Text(
                    '${data['previous_injuries'] ?? 0}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              _buildRiskLevelIndicator(insight.riskLevel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskLevelIndicator(RiskLevel? riskLevel) {
    if (riskLevel == null) return const SizedBox.shrink();

    Color color;
    String label;

    switch (riskLevel) {
      case RiskLevel.low:
        color = Colors.green;
        label = 'Low';
        break;
      case RiskLevel.moderate:
        color = Colors.orange;
        label = 'Moderate';
        break;
      case RiskLevel.high:
        color = Colors.red;
        label = 'High';
        break;
      case RiskLevel.critical:
        color = Colors.purple;
        label = 'Critical';
        break;
    }

    return Column(
      children: [
        const Icon(Icons.warning, color: Colors.red),
        const SizedBox(height: 4),
        const Text('Risk Level'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceImprovementViz(AIInsight insight) {
    final data = insight.supportingData;
    if (data == null) return const SizedBox.shrink();

    final weakestArea = data['weakest_area'] as String? ?? 'unknown';

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Focus Area',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade300),
              ),
              child: Text(
                weakestArea.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    // Build average performance metrics from _recentPerformances
    double avgSpeed = 0;
    double avgStamina = 0;
    double avgAccuracy = 0;
    double avgTactical = 0;

    if (_recentPerformances.isNotEmpty) {
      avgSpeed = _recentPerformances
              .map((p) => p.speedRating)
              .reduce((a, b) => a + b) /
          _recentPerformances.length;
      avgStamina = _recentPerformances
              .map((p) => p.staminaRating)
              .reduce((a, b) => a + b) /
          _recentPerformances.length;
      avgAccuracy = _recentPerformances
              .map((p) => p.accuracyRating)
              .reduce((a, b) => a + b) /
          _recentPerformances.length;
      avgTactical = _recentPerformances
              .map((p) => p.tacticalRating)
              .reduce((a, b) => a + b) /
          _recentPerformances.length;

      // Ensure all values are between 0 and 10
      avgSpeed = avgSpeed.clamp(0, 10);
      avgStamina = avgStamina.clamp(0, 10);
      avgAccuracy = avgAccuracy.clamp(0, 10);
      avgTactical = avgTactical.clamp(0, 10);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Performance Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to detailed performance page
              },
              child: const Text('Details'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _recentPerformances.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No performance data available yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      // Performance visualization
                      SizedBox(
                        height: 160,
                        child: _buildPerformanceRadarChart(
                            avgSpeed, avgStamina, avgAccuracy, avgTactical),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      // Metric bars
                      _buildPerformanceBar('Speed', avgSpeed, Colors.blue),
                      const SizedBox(height: 12),
                      _buildPerformanceBar('Stamina', avgStamina, Colors.green),
                      const SizedBox(height: 12),
                      _buildPerformanceBar(
                          'Accuracy', avgAccuracy, Colors.orange),
                      const SizedBox(height: 12),
                      _buildPerformanceBar(
                          'Tactical', avgTactical, Colors.purple),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceRadarChart(
      double speed, double stamina, double accuracy, double tactical) {
    // This is a placeholder visualization using stacked Container widgets
    // In a real app, you'd use a charting library for a proper radar chart

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
            ),
          ),

          // Mid-level circle
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade300,
            ),
          ),

          // Inner circle
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade400,
            ),
          ),

          // Axes
          ...List.generate(4, (index) {
            final angle = (index * (3.14159 / 2)) + (3.14159 / 4);
            return Transform.rotate(
              angle: angle,
              child: Container(
                width: 160,
                height: 2,
                color: Colors.grey.shade400,
              ),
            );
          }),

          // Data points
          _buildDataPoint('Speed', speed, Colors.blue, 0),
          _buildDataPoint('Stamina', stamina, Colors.green, 1),
          _buildDataPoint('Accuracy', accuracy, Colors.orange, 2),
          _buildDataPoint('Tactical', tactical, Colors.purple, 3),

          // Data polygon
          CustomPaint(
            size: const Size(160, 160),
            painter: PerformanceRadarPainter(
                speed / 10, stamina / 10, accuracy / 10, tactical / 10),
          ),
        ],
      ),
    );
  }

  Widget _buildDataPoint(
      String label, double value, Color color, int position) {
    // Position: 0=top, 1=right, 2=bottom, 3=left

    // Convert value to position (0-10 scale)
    final radius = (value / 10) * 75;

    // Calculate x,y based on position
    double x = 0, y = 0;

    switch (position) {
      case 0: // top
        x = 0;
        y = -radius;
        break;
      case 1: // right
        x = radius;
        y = 0;
        break;
      case 2: // bottom
        x = 0;
        y = radius;
        break;
      case 3: // left
        x = -radius;
        y = 0;
        break;
    }

    return Positioned(
      left: 80 + x - 12,
      top: 80 + y - 12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                value.round().toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (position == 0) // Only show labels for top point to avoid clutter
            Container(
              padding: const EdgeInsets.all(2),
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPerformanceBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('${value.toStringAsFixed(1)}/10'),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / 10,
            minHeight: 8,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// Custom painter for the performance radar chart
class PerformanceRadarPainter extends CustomPainter {
  final double speed;
  final double stamina;
  final double accuracy;
  final double tactical;

  PerformanceRadarPainter(
      this.speed, this.stamina, this.accuracy, this.tactical);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Calculate point positions
    final pointTop = Offset(center.dx, center.dy - (radius * speed));
    final pointRight = Offset(center.dx + (radius * stamina), center.dy);
    final pointBottom = Offset(center.dx, center.dy + (radius * accuracy));
    final pointLeft = Offset(center.dx - (radius * tactical), center.dy);

    // Create a path for the polygon
    final path = Path()
      ..moveTo(pointTop.dx, pointTop.dy)
      ..lineTo(pointRight.dx, pointRight.dy)
      ..lineTo(pointBottom.dx, pointBottom.dy)
      ..lineTo(pointLeft.dx, pointLeft.dy)
      ..close();

    // Draw filled polygon
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    // Draw polygon outline
    final outlinePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

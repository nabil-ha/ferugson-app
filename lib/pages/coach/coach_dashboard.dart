import 'package:ferugson/pages/coach/session_details_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../api/services.dart';
import '../../models/models.dart';
import '../../pages/auth/login_page.dart';
import 'create_session_page.dart';
import 'create_player_page.dart';
import 'rate_performance_page.dart';
import 'ai_insights_page.dart';
import '../../main.dart';

class CoachDashboard extends StatefulWidget {
  final VoidCallback onSwitchToAI;

  const CoachDashboard({
    super.key,
    required this.onSwitchToAI,
  });

  @override
  State<CoachDashboard> createState() => _CoachDashboardState();
}

class _CoachDashboardState extends State<CoachDashboard> {
  bool _isLoading = true;
  List<Session> _sessions = [];
  List<AIInsight> _insights = [];
  List<Player> _players = [];
  Coach? _coach;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final userService = UserService(firebaseService);
      final sessionService = SessionService(firebaseService);

      // Load current coach
      final user = await userService.getCurrentUser();
      if (user is! Coach) {
        throw Exception('Current user is not a coach');
      }
      _coach = user;

      // Load all sessions for the coach
      final sessions =
          await sessionService.getUpcomingSessionsForCoach(_coach!.id);

      // Sort sessions by date (newest first)
      sessions.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      setState(() {
        _sessions = sessions;
      });

      // Load players
      final players = await userService.getAllPlayers();
      setState(() {
        _players = players;
      });

      // Load insights
      final aiInsightService = AIInsightService(firebaseService);
      final insights = await aiInsightService.getInjuryRiskAlerts();
      setState(() {
        _insights = insights;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      _buildUpcomingSessions(),
                      _buildQuickStats(),
                      _buildPlayersSlider(),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const CreatePlayerPage()),
        ),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Add New Player',
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hello,',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
              ),
              Text(
                _coach?.name ?? 'Coach',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications, size: 28),
                    if (_coach?.pendingNotifications.isNotEmpty ?? false)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${_coach!.pendingNotifications.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  // TODO: Navigate to notifications page
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout, size: 28),
                onPressed: _logout,
                tooltip: 'Logout',
              ),
            ],
          ),
        ],
      ),
    );
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

  Widget _buildUpcomingSessions() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Training Sessions',
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
          const SizedBox(height: 16),
          _sessions.isEmpty
              ? const Center(
                  child: Text('No upcoming sessions'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _sessions.length > 3 ? 3 : _sessions.length,
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    return InkWell(
                      onTap: () => Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  SessionDetailsPage(sessionId: session.id),
                            ),
                          )
                          .then((_) => _loadDashboardData()),
                      borderRadius: BorderRadius.circular(12),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
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
                                    session.type == SessionType.training
                                        ? Icons.fitness_center
                                        : Icons.sports_soccer,
                                    color: Colors.blue,
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
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.access_time,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('EEE, MMM d, yyyy • h:mm a')
                                        .format(session.dateTime),
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    session.location,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.flag,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    session.type == SessionType.training
                                        ? session.trainingFocus
                                            .toString()
                                            .split('.')
                                            .last
                                        : 'Match vs ${session.opponentTeam}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.people,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${session.invitedPlayersIds.length} players',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),

                              // Add Rate Performance button if the session is in the past
                              if (session.dateTime
                                  .isBefore(DateTime.now())) ...[
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.rate_review,
                                          size: 16),
                                      label: const Text('Rate Performance'),
                                      onPressed: () => Navigator.of(context)
                                          .push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  RatePerformancePage(
                                                sessionId: session.id,
                                              ),
                                            ),
                                          )
                                          .then((_) => _loadDashboardData()),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Team Performance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: widget.onSwitchToAI,
                child: const Text('More Insights'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Team stats at top
                Row(
                  children: [
                    _buildStatCard(
                      Icons.directions_run,
                      '${_players.length}',
                      'Active Players',
                      Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      Icons.event,
                      '${_sessions.length}',
                      'Upcoming Sessions',
                      Colors.green,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      Icons.warning_amber_rounded,
                      '${_insights.length}',
                      'Injury Alerts',
                      Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // AI insights preview
                const Text(
                  'AI Analysis',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                if (_insights.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'No injury or fatigue alerts detected',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  _buildAIAlertsList(),

                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: widget.onSwitchToAI,
                  icon: const Icon(Icons.analytics),
                  label: const Text('Generate AI Insights'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: color.withOpacity(.8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIAlertsList() {
    // Get a limited number of insights to display
    final alerts = _insights.take(2).toList();

    return Column(
      children: alerts.map((insight) {
        // Find the player this insight is about
        final playerId = insight.playerId;
        final player = playerId != null
            ? _players.firstWhere(
                (p) => p.id == playerId,
                orElse: () => Player(
                  id: 'unknown',
                  name: 'Unknown Player',
                  email: 'unknown@example.com',
                  position: PlayerPosition.midfielder,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              )
            : null;

        // Determine color based on risk level
        Color color;
        switch (insight.riskLevel) {
          case RiskLevel.high:
          case RiskLevel.critical:
            color = Colors.red;
            break;
          case RiskLevel.moderate:
            color = Colors.orange;
            break;
          case RiskLevel.low:
          default:
            color = Colors.blue;
            break;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: player?.photoUrl != null
                    ? NetworkImage(player!.photoUrl!)
                    : null,
                backgroundColor: Colors.grey.shade200,
                child: player?.photoUrl == null
                    ? Text(player?.name.substring(0, 1) ?? 'U')
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player?.name ?? 'Unknown Player',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insight.title.replaceAll('${player?.name}', '').trim(),
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Risk level indicator
              if (insight.riskLevel != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    insight.riskLevel.toString().split('.').last,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlayersSlider() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Players',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to players page
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _players.isEmpty
              ? const Center(
                  child: Text('No players found'),
                )
              : SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _players.length,
                    itemBuilder: (context, index) {
                      final player = _players[index];
                      return Container(
                        width: 90,
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundImage: player.photoUrl != null
                                  ? NetworkImage(player.photoUrl!)
                                  : null,
                              backgroundColor: Colors.grey.shade200,
                              child: player.photoUrl == null
                                  ? const Icon(Icons.person,
                                      size: 30, color: Colors.grey)
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              player.name.split(' ')[0],
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              player.position.toString().split('.').last,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}

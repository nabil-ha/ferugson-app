import 'package:ferugson/pages/coach/session_details_page.dart';
import 'package:ferugson/pages/coach/sessions_page.dart';
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
import 'package:google_fonts/google_fonts.dart';

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
      final sessions = await sessionService.getUpcomingSessionsForCoach();

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
              Text(
                'Hello,',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Colors.white70,
                ),
              ),
              Text(
                _coach?.name ?? 'Coach',
                style: GoogleFonts.oswald(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Colors.white,
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
          Text(
            'UPCOMING SESSIONS',
            style: GoogleFonts.oswald(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // Sessions cards
          _sessions.isEmpty
              ? Center(
                  child: Text(
                    'No upcoming sessions',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
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
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              session.type == SessionType.training
                                  ? Color(0xFF1E1E1E)
                                  : Color(0xFF290000),
                              session.type == SessionType.training
                                  ? Color(0xFF2A2A2A)
                                  : Color(0xFF3D0101),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: session.type == SessionType.training
                                      ? Color(0xFFC70101).withOpacity(0.2)
                                      : Color(0xFFC70101).withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  session.type == SessionType.training
                                      ? Icons.fitness_center
                                      : Icons.sports_soccer,
                                  color: Color(0xFFC70101),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      session.title,
                                      style: GoogleFonts.oswald(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 14,
                                          color: Colors.white70,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatDate(session.dateTime),
                                          style: GoogleFonts.montserrat(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.people,
                                          size: 14,
                                          color: Colors.white70,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${session.invitedPlayersIds.length} Players',
                                          style: GoogleFonts.montserrat(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: session.type == SessionType.training
                                      ? Colors.blue.withOpacity(0.2)
                                      : Color(0xFFC70101).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: session.type == SessionType.training
                                        ? Colors.blue.withOpacity(0.5)
                                        : Color(0xFFC70101).withOpacity(0.5),
                                  ),
                                ),
                                child: Text(
                                  session.type == SessionType.training
                                      ? 'TRAINING'
                                      : 'MATCH',
                                  style: GoogleFonts.oswald(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                    color: session.type == SessionType.training
                                        ? Colors.blue
                                        : Color(0xFFC70101),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

          // View all sessions button - always show this
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextButton(
              onPressed: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (context) => const SessionsPage(),
                      ),
                    )
                    .then((_) => _loadDashboardData());
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'VIEW ALL SESSIONS',
                    style: GoogleFonts.oswald(
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC70101),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Color(0xFFC70101),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final redColor = Color(0xFFC70101);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUICK STATS',
            style: GoogleFonts.oswald(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(Icons.people, _players.length.toString(),
                  'Players', redColor),
              const SizedBox(width: 12),
              _buildStatCard(Icons.sports_soccer, _sessions.length.toString(),
                  'Sessions', Colors.blue),
              const SizedBox(width: 12),
              _buildStatCard(Icons.notifications_active,
                  _insights.length.toString(), 'Alerts', Colors.amber),
            ],
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
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.oswald(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: color.withOpacity(.9),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.white70,
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

  String _formatDate(DateTime dateTime) {
    return DateFormat('EEE, MMM d, yyyy • h:mm a').format(dateTime);
  }
}

import 'package:ferugson/pages/coach/create_session_page.dart';
import 'package:ferugson/pages/coach/session_details_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../api/services.dart';
import '../../../models/models.dart';

class SessionsPage extends StatefulWidget {
  const SessionsPage({Key? key}) : super(key: key);

  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Session> _upcomingSessions = [];
  List<Session> _pastSessions = [];
  String? _errorMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSessions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final userService = UserService(firebaseService);
      final sessionService = SessionService(firebaseService);

      // Get current user (coach)
      final user = await userService.getCurrentUser();
      if (user is! Coach) {
        throw Exception('Only coaches can access this page');
      }

      // Get all sessions
      final now = DateTime.now();
      final snapshot = await firebaseService.sessionsCollection
          .where('coachId', isEqualTo: user.id)
          .orderBy('dateTime', descending: true)
          .get();

      final upcomingSessions = <Session>[];
      final pastSessions = <Session>[];

      for (final doc in snapshot.docs) {
        final session = Session.fromJson(doc.data() as Map<String, dynamic>);
        if (session.dateTime.isAfter(now)) {
          upcomingSessions.add(session);
        } else {
          pastSessions.add(session);
        }
      }

      // Sort upcoming sessions by date (nearest first)
      upcomingSessions.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      // Sort past sessions by date (most recent first)
      pastSessions.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      setState(() {
        _upcomingSessions = upcomingSessions;
        _pastSessions = pastSessions;
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
      appBar: AppBar(
        title: const Text('Sessions'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_errorMessage',
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSessions,
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSessions,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSessionsList(_upcomingSessions, isUpcoming: true),
                      _buildSessionsList(_pastSessions, isUpcoming: false),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(
              builder: (context) => CreateSessionPage(
                onSessionCreated: _loadSessions,
              ),
            ))
            .then((_) => _loadSessions()),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Create Session',
      ),
    );
  }

  Widget _buildSessionsList(List<Session> sessions,
      {required bool isUpcoming}) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.event_available : Icons.history,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? 'No upcoming sessions' : 'No past sessions',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            if (isUpcoming)
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(
                      builder: (context) => CreateSessionPage(
                        onSessionCreated: _loadSessions,
                      ),
                    ))
                    .then((_) => _loadSessions()),
                icon: const Icon(Icons.add),
                label: const Text('Create Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _buildSessionCard(session);
      },
    );
  }

  Widget _buildSessionCard(Session session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(
              builder: (context) => SessionDetailsPage(sessionId: session.id),
            ))
            .then((_) => _loadSessions()),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      session.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: session.type == SessionType.training
                          ? Colors.green.shade100
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      session.type == SessionType.training
                          ? 'Training'
                          : 'Match',
                      style: TextStyle(
                        color: session.type == SessionType.training
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('EEE, MMM d, yyyy').format(session.dateTime),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('h:mm a').format(session.dateTime),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      session.location,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.flag, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    session.type == SessionType.training &&
                            session.trainingFocus != null
                        ? session.trainingFocus.toString().split('.').last
                        : session.type == SessionType.match &&
                                session.opponentTeam != null
                            ? 'vs ${session.opponentTeam}'
                            : session.type == SessionType.training
                                ? 'Mixed'
                                : 'Match',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.people, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          '${session.invitedPlayersIds.length} players',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(width: 8),
                        // Show confirmation counts
                        Text(
                          '(${_getConfirmationSummary(session)})',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // If session is in the past, show performance rating button
              if (session.dateTime.isBefore(DateTime.now())) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context)
                          .push(MaterialPageRoute(
                            builder: (context) => SessionDetailsPage(
                              sessionId: session.id,
                            ),
                          ))
                          .then((_) => _loadSessions()),
                      icon: const Icon(Icons.rate_review, size: 16),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getConfirmationSummary(Session session) {
    int confirmed = 0;
    int pending = 0;
    int declined = 0;

    session.confirmationStatus.forEach((_, status) {
      if (status == ConfirmationStatus.confirmed) {
        confirmed++;
      } else if (status == ConfirmationStatus.pending) {
        pending++;
      } else if (status == ConfirmationStatus.declined) {
        declined++;
      }
    });

    return '$confirmed confirmed, $pending pending, $declined declined';
  }
}

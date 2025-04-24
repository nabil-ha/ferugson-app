// lib/pages/coach/session_details_page.dart
import 'package:ferugson/pages/coach/rate_performance_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../api/services.dart';
import '../../models/models.dart';

class SessionDetailsPage extends StatefulWidget {
  final String sessionId;
  final bool showRiskResults;
  final Map<String, int>? injuryRisks;

  const SessionDetailsPage({
    Key? key,
    required this.sessionId,
    this.showRiskResults = false,
    this.injuryRisks,
  }) : super(key: key);

  @override
  _SessionDetailsPageState createState() => _SessionDetailsPageState();
}

class _SessionDetailsPageState extends State<SessionDetailsPage> {
  bool _isLoading = true;
  late Session _session;
  List<Player> _players = [];
  List<Performance> _performances = [];

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  Future<void> _loadSessionData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final sessionService = SessionService(firebaseService);
      final userService = UserService(firebaseService);
      final performanceService = PerformanceService(firebaseService);

      final session = await sessionService.getSessionById(widget.sessionId);
      if (session == null) {
        throw Exception('Session not found');
      }
      _session = session;

      final players = <Player>[];
      for (final playerId in _session.invitedPlayersIds) {
        final user = await userService.getUserById(playerId);
        if (user is Player) {
          players.add(user);
        }
      }

      _players = players;

      _performances =
          await performanceService.getPerformancesForSession(widget.sessionId);

      if (widget.showRiskResults && widget.injuryRisks != null && mounted) {
        Future.delayed(Duration.zero, () {
          _showRiskResultsDialog();
        });
      } else if (mounted &&
          _session.playerInjuryRisks != null &&
          _session.playerInjuryRisks!.isNotEmpty) {
        Future.delayed(Duration.zero, () {
          _showRiskResultsDialog();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading session data: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToPlayerAnalysis() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => RatePerformancePage(sessionId: widget.sessionId),
      ),
    )
        .then((_) {
      _loadSessionData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSessionDetailsCard(),
                  const SizedBox(height: 16),
                  _buildPlayersList(),
                  const SizedBox(height: 16),
                  _buildPerformanceSection(),
                ],
              ),
            ),
      floatingActionButton: !_isLoading &&
              (_performances.length < _players.length || _performances.isEmpty)
          ? FloatingActionButton.extended(
              onPressed: _navigateToPlayerAnalysis,
              icon: const Icon(Icons.rate_review),
              label: const Text('Rate Performance'),
              backgroundColor: Colors.blue,
            )
          : null,
    );
  }

  Widget _buildSessionDetailsCard() {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _session.type == SessionType.training
                      ? Icons.fitness_center
                      : Icons.sports_soccer,
                  color: Colors.blue,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _session.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
                Icons.calendar_today, dateFormat.format(_session.dateTime)),
            const SizedBox(height: 8),
            _buildInfoRow(
                Icons.access_time, timeFormat.format(_session.dateTime)),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, _session.location),
            const SizedBox(height: 8),
            if (_session.type == SessionType.training &&
                _session.trainingFocus != null)
              _buildInfoRow(Icons.sports,
                  'Focus: ${_session.trainingFocus.toString().split('.').last}')
            else if (_session.type == SessionType.match &&
                _session.opponentTeam != null)
              _buildInfoRow(Icons.people, 'Opponent: ${_session.opponentTeam}'),
            if (_session.coachComments != null &&
                _session.coachComments!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Coach Comments:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(_session.coachComments!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayersList() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Invited Players (${_players.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.injuryRisks != null)
                  Tooltip(
                    message: 'Risk assessment available',
                    child: Icon(Icons.analytics, color: Colors.blue),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _players.isEmpty
                ? const Center(
                    child: Text(
                      'No players invited to this session',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _players.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final player = _players[index];
                      final hasPerformance = _performances.any(
                          (performance) => performance.playerId == player.id);
                      final riskLevel = widget.injuryRisks != null
                          ? widget.injuryRisks![player.id]
                          : null;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: player.photoUrl != null
                              ? NetworkImage(player.photoUrl!)
                              : null,
                          child: player.photoUrl == null
                              ? Text(player.name.substring(0, 1))
                              : null,
                        ),
                        title: Text(player.name),
                        subtitle: Text(
                          player.position.toString().split('.').last,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (riskLevel != null) _buildRiskBadge(riskLevel),
                            if (hasPerformance)
                              const Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskBadge(int riskLevel) {
    Color color;
    String tooltip;

    switch (riskLevel) {
      case 2:
        color = Colors.red;
        tooltip = 'High injury risk';
        break;
      case 1:
        color = Colors.orange;
        tooltip = 'Medium injury risk';
        break;
      default:
        color = Colors.green;
        tooltip = 'Low injury risk';
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: color),
        ),
        child: Icon(
          Icons.warning,
          color: color,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildPerformanceSection() {
    final hasPerformances = _performances.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Performance Analysis (${_performances.length}/${_players.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (hasPerformances && _performances.length < _players.length)
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add More'),
                onPressed: _navigateToPlayerAnalysis,
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (!hasPerformances)
          Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No performance analysis data yet.\nUse the button below to rate player performances.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _performances.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final performance = _performances[index];
                final player = _players.firstWhere(
                  (p) => p.id == performance.playerId,
                  orElse: () => Player(
                    id: 'unknown',
                    name: 'Unknown Player',
                    email: 'unknown@example.com',
                    position: PlayerPosition.midfielder,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                );

                return ExpansionTile(
                  leading: CircleAvatar(
                    backgroundImage: player.photoUrl != null
                        ? NetworkImage(player.photoUrl!)
                        : null,
                    backgroundColor: Colors.grey.shade200,
                    child: player.photoUrl == null
                        ? Text(player.name.substring(0, 1))
                        : null,
                  ),
                  title: Text(player.name),
                  subtitle: Text(
                      'Avg: ${_calculateAverage(performance).toStringAsFixed(1)}/10'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildRatingBar(
                              'Speed', performance.speedRating, Colors.blue),
                          const SizedBox(height: 8),
                          _buildRatingBar('Stamina', performance.staminaRating,
                              Colors.green),
                          const SizedBox(height: 8),
                          _buildRatingBar('Accuracy',
                              performance.accuracyRating, Colors.orange),
                          const SizedBox(height: 8),
                          _buildRatingBar('Tactical',
                              performance.tacticalRating, Colors.purple),
                          if (performance.strengthRating != null) ...[
                            const SizedBox(height: 8),
                            _buildRatingBar('Strength',
                                performance.strengthRating!, Colors.red),
                          ],
                          if (performance.coachComments != null &&
                              performance.coachComments!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Coach Comments:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(performance.coachComments!),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRatingBar(String label, int value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: value / 10,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$value',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  double _calculateAverage(Performance performance) {
    final total = performance.speedRating +
        performance.staminaRating +
        performance.accuracyRating +
        performance.tacticalRating;
    return total / 4;
  }

  Future<void> _showRiskResultsDialog() async {
    if (!mounted) return;

    final Map<String, int> riskData;
    if (widget.injuryRisks != null && widget.injuryRisks!.isNotEmpty) {
      riskData = widget.injuryRisks!;
    } else if (_session.playerInjuryRisks != null &&
        _session.playerInjuryRisks!.isNotEmpty) {
      riskData = _session.playerInjuryRisks!;
    } else {
      return;
    }

    int highRisk = 0;
    int mediumRisk = 0;
    int lowRisk = 0;

    riskData.forEach((_, risk) {
      if (risk == 2)
        highRisk++;
      else if (risk == 1)
        mediumRisk++;
      else
        lowRisk++;
    });

    final playerNames = <String, String>{};
    for (final player in _players) {
      if (riskData.containsKey(player.id)) {
        playerNames[player.id] = player.name;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('AI Risk Assessment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session risk analysis complete:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildRiskSummary(highRisk, mediumRisk, lowRisk),
            SizedBox(height: 16),
            Text('Players are marked with risk indicators in the player list.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskSummary(int highRisk, int mediumRisk, int lowRisk) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildRiskIndicator('High', highRisk, Colors.red),
        _buildRiskIndicator('Medium', mediumRisk, Colors.orange),
        _buildRiskIndicator('Low', lowRisk, Colors.green),
      ],
    );
  }

  Widget _buildRiskIndicator(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }
}

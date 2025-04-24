import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/services.dart';
import '../../models/models.dart';
import 'package:intl/intl.dart';
import 'session_details_page.dart';

class AIInsightsPage extends StatefulWidget {
  const AIInsightsPage({super.key});

  @override
  State<AIInsightsPage> createState() => _AIInsightsPageState();
}

class _AIInsightsPageState extends State<AIInsightsPage> {
  bool _isLoading = true;
  List<Session> _sessions = [];
  List<Player> _players = [];
  Map<String, Map<String, dynamic>> _playerAnalytics = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final userService = UserService(firebaseService);
      final sessionService = SessionService(firebaseService);
      final aiService = AIService(firebaseService);

      // Load players and sessions
      _players = await userService.getAllPlayers();
      _sessions = await sessionService.getUpcomingSessionsForCoach();

      // Process analytics data for each player
      _playerAnalytics = {};
      for (final player in _players) {
        if (_sessions.isNotEmpty) {
          // Get risk level for the next session
          final riskLevel =
              await aiService.predictInjuryRisk(player, _sessions.first);

          // Calculate fatigue percentage if player has provided self-assessment data
          int fatiguePercent = 50; // Default value
          try {
            fatiguePercent = await aiService.calculateFatiguePercentage(
              6, // Default or average speed
              5, // Default or average stamina
              7, // Default or average strength
            );
          } catch (e) {
            print('Error calculating fatigue for ${player.name}: $e');
          }

          _playerAnalytics[player.id] = {
            'injuryRisk': riskLevel,
            'fatiguePercent': fatiguePercent,
          };
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: ${e.toString()}')),
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
        title: const Text('AI Analytics'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header information
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.blue.withOpacity(0.1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Risk Assessment',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'AI-powered analysis of injury risks and fatigue levels for upcoming sessions',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildRiskIndicator('Low', Colors.green),
                            const SizedBox(width: 16),
                            _buildRiskIndicator('Medium', Colors.orange),
                            const SizedBox(width: 16),
                            _buildRiskIndicator('High', Colors.red),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: _players.isEmpty
                        ? _buildEmptyState()
                        : _buildPlayerAnalyticsList(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No player data available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add players and create sessions to generate AI insights',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRiskIndicator(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerAnalyticsList() {
    // Sort players by risk level (highest first)
    final sortedPlayers = List<Player>.from(_players);
    sortedPlayers.sort((a, b) {
      final riskA = _playerAnalytics[a.id]?['injuryRisk'] as int? ?? 0;
      final riskB = _playerAnalytics[b.id]?['injuryRisk'] as int? ?? 0;
      return riskB.compareTo(riskA); // Descending order
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedPlayers.length,
      itemBuilder: (context, index) {
        final player = sortedPlayers[index];
        final analytics = _playerAnalytics[player.id];
        if (analytics == null) return const SizedBox.shrink();

        return _buildPlayerCard(player, analytics);
      },
    );
  }

  Widget _buildPlayerCard(Player player, Map<String, dynamic> analytics) {
    final injuryRisk = analytics['injuryRisk'] as int? ?? 0;
    final fatiguePercent = analytics['fatiguePercent'] as int? ?? 50;

    Color riskColor;
    String riskText;

    switch (injuryRisk) {
      case 0:
        riskColor = Colors.green;
        riskText = 'Low';
        break;
      case 1:
        riskColor = Colors.orange;
        riskText = 'Medium';
        break;
      case 2:
        riskColor = Colors.red;
        riskText = 'High';
        break;
      default:
        riskColor = Colors.grey;
        riskText = 'Unknown';
    }

    Color fatigueColor;
    if (fatiguePercent < 30) {
      fatigueColor = Colors.green;
    } else if (fatiguePercent < 70) {
      fatigueColor = Colors.orange;
    } else {
      fatigueColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: player.photoUrl != null
                      ? NetworkImage(player.photoUrl!)
                      : null,
                  backgroundColor: Colors.grey[200],
                  child: player.photoUrl == null
                      ? Text(
                          player.name.isNotEmpty
                              ? player.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 20),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        player.position.toString().split('.').last,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: riskColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.emergency, size: 16, color: riskColor),
                      const SizedBox(width: 4),
                      Text(
                        riskText,
                        style: TextStyle(
                          color: riskColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Analytics',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),

            // Injury risk factors
            _buildRiskFactors(player, injuryRisk),

            const SizedBox(height: 16),

            // Fatigue meter
            _buildFatigueMeter(player, fatiguePercent, fatigueColor),

            const SizedBox(height: 16),
            // Recommendations
            _buildRecommendations(player, injuryRisk, fatiguePercent),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskFactors(Player player, int riskLevel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Injury Risk Factors',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildRiskFactor(
                'BMI',
                player.bmi?.toStringAsFixed(1) ?? 'N/A',
                player.bmi != null && (player.bmi! < 18.5 || player.bmi! > 25),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRiskFactor(
                'Previous Injuries',
                player.hasPreviousInjuries ? 'Yes' : 'No',
                player.hasPreviousInjuries,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRiskFactor(
                'Intensity',
                _sessions.isNotEmpty
                    ? '${_sessions.first.intensity}/10'
                    : 'N/A',
                _sessions.isNotEmpty && _sessions.first.intensity > 7,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRiskFactor(String label, String value, bool isRiskFactor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isRiskFactor
            ? Colors.red.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isRiskFactor
              ? Colors.red.withOpacity(0.3)
              : Colors.green.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isRiskFactor ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFatigueMeter(
      Player player, int fatiguePercent, Color fatigueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Fatigue Assessment',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            Text(
              '$fatiguePercent%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: fatigueColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fatiguePercent / 100,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(fatigueColor),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                'Low',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ),
            Expanded(
              child: Text(
                'Moderate',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Text(
                'High',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecommendations(
      Player player, int riskLevel, int fatiguePercent) {
    List<String> recommendations = [];

    if (riskLevel == 2) {
      recommendations
          .add('Consider reducing training intensity for this player');
      recommendations.add('Ensure proper warm-up and stretching routines');
      if (player.hasPreviousInjuries) {
        recommendations.add('Monitor closely due to previous injury history');
      }
    } else if (riskLevel == 1) {
      recommendations
          .add('Keep an eye on this player during high-intensity drills');
    }

    if (fatiguePercent > 70) {
      recommendations
          .add('Player shows signs of high fatigue - consider rest days');
    } else if (fatiguePercent > 50) {
      recommendations.add('Moderate fatigue detected - monitor workload');
    }

    if (recommendations.isEmpty) {
      recommendations.add('No specific recommendations at this time');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb_outline, size: 18, color: Colors.amber),
            const SizedBox(width: 4),
            const Text(
              'Recommendations',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(rec)),
                ],
              ),
            )),
      ],
    );
  }
}

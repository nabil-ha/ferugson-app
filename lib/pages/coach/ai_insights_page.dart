import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../api/services.dart';
import '../../api/ai_api_service.dart';
import '../../models/models.dart';

class AIInsightsPage extends StatefulWidget {
  const AIInsightsPage({super.key});

  @override
  State<AIInsightsPage> createState() => _AIInsightsPageState();
}

class _AIInsightsPageState extends State<AIInsightsPage> {
  bool _isLoading = true;
  bool _isGeneratingInsights = false;
  List<AIInsight> _insights = [];
  List<Player> _players = [];
  final AIApiService _aiApiService = AIApiService();

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final userService = UserService(firebaseService);
      final aiInsightService = AIInsightService(firebaseService);

      // Load insights and players
      _insights = await aiInsightService.getAllInsights();
      _players = await userService.getAllPlayers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading insights: ${e.toString()}')),
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
        title: const Text('AI Insights'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInsights,
            tooltip: 'Refresh Insights',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInsights,
              child: Column(
                children: [
                  _buildActionButtons(),
                  Expanded(
                    child: _players.isEmpty
                        ? const Center(child: Text('No player data available'))
                        : _insights.isEmpty
                            ? const Center(
                                child: Text(
                                    'No insights available yet.\nGenerate some using the buttons above.'))
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _insights.length,
                                itemBuilder: (context, index) {
                                  final insight = _insights[index];
                                  return _buildInsightCard(insight);
                                },
                              ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed:
                  _isGeneratingInsights ? null : _generateInjuryPredictions,
              icon: const Icon(Icons.healing),
              label: const Text('Check Injury Risk'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed:
                  _isGeneratingInsights ? null : _generateFatiguePredictions,
              icon: const Icon(Icons.battery_alert),
              label: const Text('Check Fatigue Level'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(AIInsight insight) {
    // Find player if this is a player-specific insight
    final player = insight.playerId != null
        ? _players.firstWhere((p) => p.id == insight.playerId,
            orElse: () => Player(
                  id: 'unknown',
                  name: 'Unknown Player',
                  email: 'unknown@example.com',
                  position: PlayerPosition.midfielder,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ))
        : null;

    // Determine the card color based on insight type
    Color cardColor;
    IconData iconData;

    switch (insight.type) {
      case InsightType.injuryRisk:
        cardColor = Colors.red.shade50;
        iconData = Icons.healing;
        break;
      case InsightType.fatigueManagement:
        cardColor = Colors.orange.shade50;
        iconData = Icons.battery_alert;
        break;
      case InsightType.performanceImprovement:
        cardColor = Colors.green.shade50;
        iconData = Icons.trending_up;
        break;
      case InsightType.restRecommendation:
        cardColor = Colors.blue.shade50;
        iconData = Icons.bedtime;
        break;
      case InsightType.teamPerformance:
        cardColor = Colors.purple.shade50;
        iconData = Icons.groups;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(iconData, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    insight.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (insight.riskLevel != null)
                  _buildRiskLevelBadge(insight.riskLevel!),
              ],
            ),
            if (player != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: player.photoUrl != null
                          ? NetworkImage(player.photoUrl!)
                          : null,
                      backgroundColor: Colors.grey.shade200,
                      radius: 16,
                      child: player.photoUrl == null
                          ? Text(player.name.substring(0, 1))
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      player.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        player.position.toString().split('.').last,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Text(
              insight.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Add visualization based on insight type
            if (insight.supportingData != null)
              _buildInsightVisualization(insight),

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Expires: ${_formatDate(insight.expirationDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (!insight.isAcknowledged)
                  ElevatedButton(
                    onPressed: () => _acknowledgeInsight(insight.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('Acknowledge'),
                  )
                else
                  Chip(
                    label: const Text('Acknowledged'),
                    backgroundColor: Colors.green.shade100,
                    labelStyle: TextStyle(
                      color: Colors.green.shade800,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // New widget to visualize insight data from AI models
  Widget _buildInsightVisualization(AIInsight insight) {
    switch (insight.type) {
      case InsightType.injuryRisk:
        return _buildInjuryRiskVisualization(insight);
      case InsightType.fatigueManagement:
        return _buildFatigueVisualization(insight);
      case InsightType.performanceImprovement:
        return _buildPerformanceVisualization(insight);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInjuryRiskVisualization(AIInsight insight) {
    // Extract data from supporting data
    final data = insight.supportingData;
    if (data == null) return const SizedBox.shrink();

    final previousInjuries = data['previous_injuries'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Prediction Factors:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Card(
                color: Colors.red.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      const Icon(Icons.healing),
                      const SizedBox(height: 4),
                      const Text('Previous Injuries'),
                      Text(
                        '$previousInjuries',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                color: Colors.red.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      const Icon(Icons.priority_high),
                      const SizedBox(height: 4),
                      const Text('Risk Level'),
                      Text(
                        insight.riskLevel.toString().split('.').last,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFatigueVisualization(AIInsight insight) {
    // Extract data from supporting data
    final data = insight.supportingData;
    if (data == null) return const SizedBox.shrink();

    final fatigueLevel = data['fatigue_level'] ?? 0;
    final staminaRating = data['stamina_rating'] ?? 0;
    final speedRating = data['speed_rating'] ?? 0;

    // Calculate percentage for gauge visualization
    final fatiguePercentage = (fatigueLevel / 10).clamp(0.0, 1.0);

    // Find color for gauge based on fatigue level
    Color gaugeColor;
    if (fatigueLevel <= 3)
      gaugeColor = Colors.green;
    else if (fatigueLevel <= 6)
      gaugeColor = Colors.orange;
    else
      gaugeColor = Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fatigue Analysis:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Fatigue Level'),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: fatiguePercentage,
                      minHeight: 20,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(gaugeColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Low', style: TextStyle(fontSize: 12)),
                      Text('$fatigueLevel/10',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          )),
                      const Text('High', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Contributing Factors:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      )),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Speed:'),
                      Text('$speedRating/10'),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Stamina:'),
                      Text('$staminaRating/10'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceVisualization(AIInsight insight) {
    // Extract data from supporting data
    final data = insight.supportingData;
    if (data == null) return const SizedBox.shrink();

    final avgSpeed = data['avg_speed'] ?? 0.0;
    final avgStamina = data['avg_stamina'] ?? 0.0;
    final avgAccuracy = data['avg_accuracy'] ?? 0.0;
    final avgTactical = data['avg_tactical'] ?? 0.0;
    final weakestArea = data['weakest_area'] ?? 'unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance Analysis:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPerformanceRatingBar('Speed', avgSpeed, Colors.blue),
                  const SizedBox(height: 4),
                  _buildPerformanceRatingBar(
                      'Stamina', avgStamina, Colors.green),
                  const SizedBox(height: 4),
                  _buildPerformanceRatingBar(
                      'Accuracy', avgAccuracy, Colors.orange),
                  const SizedBox(height: 4),
                  _buildPerformanceRatingBar(
                      'Tactical', avgTactical, Colors.purple),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 100,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Column(
                children: [
                  const Text(
                    'Focus Area',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    weakestArea.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceRatingBar(String label, double value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: value / 10,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(
          width: 30,
          child: Text(
            value.toStringAsFixed(1),
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildRiskLevelBadge(RiskLevel level) {
    Color color;
    String text;

    switch (level) {
      case RiskLevel.low:
        color = Colors.green;
        text = 'Low Risk';
        break;
      case RiskLevel.moderate:
        color = Colors.orange;
        text = 'Moderate Risk';
        break;
      case RiskLevel.high:
        color = Colors.red;
        text = 'High Risk';
        break;
      case RiskLevel.critical:
        color = Colors.purple;
        text = 'Critical Risk';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference > 1 && difference < 7) {
      return 'In $difference days';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  Future<void> _acknowledgeInsight(String insightId) async {
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final aiInsightService = AIInsightService(firebaseService);

      await aiInsightService.acknowledgeInsight(insightId);

      // Update the local insights list
      setState(() {
        final index =
            _insights.indexWhere((insight) => insight.id == insightId);
        if (index >= 0) {
          _insights[index] = _insights[index].copyWith(isAcknowledged: true);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insight acknowledged')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error acknowledging insight: ${e.toString()}')),
      );
    }
  }

  Future<void> _generateInjuryPredictions() async {
    if (_players.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No players available to analyze')),
      );
      return;
    }

    setState(() {
      _isGeneratingInsights = true;
    });

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final aiInsightService = AIInsightService(firebaseService);
      final aiApiService = AIApiService();

      // Clear existing injury insights
      _insights =
          _insights.where((i) => i.type != InsightType.injuryRisk).toList();

      // Generate injury predictions for each player
      for (final player in _players) {
        final isHighRisk = await aiApiService.predictInjuryRisk(player);
        if (isHighRisk) {
          final insight = AIInsight(
            id: const Uuid().v4(),
            playerId: player.id,
            type: InsightType.injuryRisk,
            title: 'Injury Risk Detected',
            description: 'AI predicts ${player.name} is at risk of injury.',
            riskLevel: RiskLevel.high,
            supportingData: {
              'previous_injuries': player.previousInjuries ?? 0,
            },
            expirationDate: DateTime.now().add(const Duration(days: 7)),
          );
          await aiInsightService.createAIInsight(insight);
        }
      }

      // Reload insights after generation
      await _loadInsights();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Injury risk analysis complete')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking injury risk: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingInsights = false;
        });
      }
    }
  }

  Future<void> _generateFatiguePredictions() async {
    if (_players.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No players available to analyze')),
      );
      return;
    }

    setState(() {
      _isGeneratingInsights = true;
    });

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final aiInsightService = AIInsightService(firebaseService);
      final aiApiService = AIApiService();

      // Clear existing fatigue insights
      _insights = _insights
          .where((i) => i.type != InsightType.fatigueManagement)
          .toList();

      // Generate fatigue predictions for each player
      for (final player in _players) {
        final performanceSnapshot = await firebaseService.performancesCollection
            .where('playerId', isEqualTo: player.id)
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

        if (performanceSnapshot.docs.isNotEmpty) {
          final latestPerformance = Performance.fromJson(
              performanceSnapshot.docs.first.data() as Map<String, dynamic>);

          final fatigueLevel =
              await aiApiService.predictFatigueLevel(latestPerformance);
          if (fatigueLevel == 1) {
            // High fatigue
            final insight = AIInsight(
              id: const Uuid().v4(),
              playerId: player.id,
              type: InsightType.fatigueManagement,
              title: 'High Fatigue Detected',
              description:
                  'AI predicts ${player.name} is experiencing high fatigue.',
              riskLevel: RiskLevel.high,
              supportingData: {
                'fatigue_level': fatigueLevel,
                'stamina_rating': latestPerformance.staminaRating,
                'speed_rating': latestPerformance.speedRating,
              },
              expirationDate: DateTime.now().add(const Duration(days: 7)),
            );
            await aiInsightService.createAIInsight(insight);
          }
        }
      }

      // Reload insights after generation
      await _loadInsights();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fatigue analysis complete')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking fatigue: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingInsights = false;
        });
      }
    }
  }
}

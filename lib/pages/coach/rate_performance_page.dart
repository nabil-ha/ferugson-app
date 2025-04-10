// lib/pages/coach/rate_performance_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/services.dart';
import '../../models/models.dart';

class RatePerformancePage extends StatefulWidget {
  final String sessionId;
  const RatePerformancePage({Key? key, required this.sessionId})
      : super(key: key);

  @override
  _RatePerformancePageState createState() => _RatePerformancePageState();
}

class _RatePerformancePageState extends State<RatePerformancePage> {
  bool _isLoading = true;
  bool _isSaving = false;
  late Session _session;
  List<Player> _players = [];
  List<Performance> _existingPerformances = [];
  Map<String, Map<String, int>> _ratings = {};
  Map<String, TextEditingController> _commentControllers = {};

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  @override
  void dispose() {
    _commentControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
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

      // Load session details
      final session = await sessionService.getSessionById(widget.sessionId);
      if (session == null) {
        throw Exception('Session not found');
      }
      _session = session;

      // Load existing performances
      _existingPerformances =
          await performanceService.getPerformancesForSession(widget.sessionId);

      // Load player details for all invited players
      final players = <Player>[];
      for (final playerId in _session.invitedPlayersIds) {
        // If the player has already been rated, skip them
        if (_existingPerformances.any((p) => p.playerId == playerId)) {
          continue;
        }

        final user = await userService.getUserById(playerId);
        if (user is Player && (_session.invitedPlayersIds.contains(playerId))) {
          players.add(user);

          // Initialize ratings for this player
          _ratings[playerId] = {
            'speed': 5,
            'stamina': 5,
            'accuracy': 5,
            'tactical': 5,
            'strength': 5,
          };

          // Initialize comment controller
          _commentControllers[playerId] = TextEditingController();
        }
      }

      _players = players;
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

  Future<void> _savePerformanceRatings() async {
    if (_players.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No players to evaluate')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final performanceService = PerformanceService(firebaseService);

      int savedCount = 0;

      // Save performance evaluations for each player
      for (final player in _players) {
        final playerRatings = _ratings[player.id];
        if (playerRatings != null) {
          final performance = Performance(
            playerId: player.id,
            sessionId: widget.sessionId,
            playerPosition: player.position.toString().split('.').last,
            speedRating: playerRatings['speed']!,
            staminaRating: playerRatings['stamina']!,
            accuracyRating: playerRatings['accuracy']!,
            tacticalRating: playerRatings['tactical']!,
            strengthRating: playerRatings['strength'],
            coachComments: _commentControllers[player.id]?.text.trim(),
          );

          await performanceService.createPerformance(performance);
          savedCount++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Saved performance ratings for $savedCount players')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Error saving performance ratings: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Player Performance'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && !_isSaving && _players.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _savePerformanceRatings,
              tooltip: 'Save All Ratings',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _players.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle,
                            size: 64, color: Colors.green.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          'All players have been evaluated for this session!',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Return to Session Details'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildRatingForm(),
      bottomNavigationBar: !_isLoading && !_isSaving && _players.isNotEmpty
          ? BottomAppBar(
              child: ElevatedButton(
                onPressed: _savePerformanceRatings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(_isSaving ? 'Saving...' : 'SAVE ALL RATINGS'),
              ),
            )
          : null,
    );
  }

  Widget _buildRatingForm() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _players.length,
      itemBuilder: (context, index) {
        final player = _players[index];
        return _buildPlayerRatingCard(player);
      },
    );
  }

  Widget _buildPlayerRatingCard(Player player) {
    final playerRatings = _ratings[player.id]!;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Player header
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: player.photoUrl != null
                      ? NetworkImage(player.photoUrl!)
                      : null,
                  backgroundColor: Colors.grey.shade200,
                  radius: 24,
                  child: player.photoUrl == null
                      ? Text(player.name.substring(0, 1),
                          style: const TextStyle(fontSize: 18))
                      : null,
                ),
                const SizedBox(width: 16),
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
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text(
              'Performance Ratings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),

            // Rating sliders
            _buildRatingSlider(
              'Speed',
              playerRatings['speed']!,
              (value) {
                setState(() {
                  _ratings[player.id]!['speed'] = value.round();
                });
              },
              Colors.blue,
            ),

            _buildRatingSlider(
              'Stamina',
              playerRatings['stamina']!,
              (value) {
                setState(() {
                  _ratings[player.id]!['stamina'] = value.round();
                });
              },
              Colors.green,
            ),

            _buildRatingSlider(
              'Accuracy',
              playerRatings['accuracy']!,
              (value) {
                setState(() {
                  _ratings[player.id]!['accuracy'] = value.round();
                });
              },
              Colors.orange,
            ),

            _buildRatingSlider(
              'Tactical',
              playerRatings['tactical']!,
              (value) {
                setState(() {
                  _ratings[player.id]!['tactical'] = value.round();
                });
              },
              Colors.purple,
            ),

            _buildRatingSlider(
              'Strength',
              playerRatings['strength']!,
              (value) {
                setState(() {
                  _ratings[player.id]!['strength'] = value.round();
                });
              },
              Colors.red,
            ),

            const SizedBox(height: 16),

            // Comment field
            TextField(
              controller: _commentControllers[player.id],
              decoration: const InputDecoration(
                labelText: 'Comments',
                hintText: 'Add specific feedback for this player',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSlider(
      String label, int value, Function(double) onChanged, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color),
                ),
                child: Text(
                  '$value/10',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: color,
            inactiveColor: color.withOpacity(0.3),
            onChanged: onChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Poor',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text('Excellent',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }
}

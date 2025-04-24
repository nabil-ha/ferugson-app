import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../api/services.dart';
import '../../models/models.dart';
import 'session_details_page.dart';

class CreateSessionPage extends StatefulWidget {
  final VoidCallback onSessionCreated;

  const CreateSessionPage({
    super.key,
    required this.onSessionCreated,
  });

  @override
  State<CreateSessionPage> createState() => _CreateSessionPageState();
}

class _CreateSessionPageState extends State<CreateSessionPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _commentsController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  SessionType _sessionType = SessionType.training;
  TrainingFocus? _trainingFocus = TrainingFocus.mixed;
  int _intensity = 5;
  String? _opponentTeam;

  List<Player> _availablePlayers = [];
  List<String> _selectedPlayers = [];

  bool _isLoading = false;
  bool _isLoadingPlayers = true;
  bool _processingAI = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayers() async {
    setState(() {
      _isLoadingPlayers = true;
    });

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final userService = UserService(firebaseService);

      _availablePlayers = await userService.getAllPlayers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading players: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPlayers = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<Map<String, int>> _processInjuryRisks(Session session) async {
    setState(() {
      _processingAI = true;
    });

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final aiService = AIService(firebaseService);

      final risks = await aiService.processSessionInjuryRisks(session);

      await aiService.storeInjuryInsights(session, risks);

      return risks;
    } catch (e) {
      print('Error processing injury risks: $e');
      return {};
    } finally {
      if (mounted) {
        setState(() {
          _processingAI = false;
        });
      }
    }
  }

  Future<void> _createSession() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPlayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one player')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final userService = UserService(firebaseService);
      final sessionService = SessionService(firebaseService);

      final user = await userService.getCurrentUser();
      if (user is! Coach) {
        throw Exception('Only coaches can create sessions');
      }

      final sessionDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final session = Session(
        title: _titleController.text.trim(),
        type: _sessionType,
        dateTime: sessionDateTime,
        location: _locationController.text.trim(),
        coachId: user.id,
        invitedPlayersIds: _selectedPlayers,
        trainingFocus:
            _sessionType == SessionType.training ? _trainingFocus : null,
        intensity: _intensity,
        opponentTeam: _sessionType == SessionType.match ? _opponentTeam : null,
        coachComments: _commentsController.text.trim(),
      );

      final sessionId = await sessionService.createSession(session);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session created successfully')),
        );

        _processRisksAndNavigate(session.copyWith(id: sessionId));
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _processRisksAndNavigate(Session session) async {
    try {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SessionDetailsPage(
              sessionId: session.id,
            ),
          ),
        );
      }

      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final sessionService = SessionService(firebaseService);
      final aiService = AIService(firebaseService);

      final injuryRisks = await _processInjuryRisks(session);

      if (injuryRisks.isNotEmpty) {
        await sessionService.updateSession(
          session.copyWith(
            playerInjuryRisks: injuryRisks,
          ),
        );

        await aiService.storeInjuryInsights(session, injuryRisks);
      }
    } catch (e) {
      print('Error processing injury risks: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showInjuryRiskResults(
      List<AIInsight> insights, Map<String, String> playerNames) async {
    if (!mounted) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Injury Risk Assessment'),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text(
                  'AI analysis identified potential injury risks for ${insights.length} player(s):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                ...insights.map((insight) {
                  final playerName =
                      playerNames[insight.playerId] ?? 'Unknown Player';
                  final riskLevel = insight.riskLevel ?? RiskLevel.low;

                  Color riskColor;
                  switch (riskLevel) {
                    case RiskLevel.moderate:
                      riskColor = Colors.orange;
                      break;
                    case RiskLevel.high:
                      riskColor = Colors.red;
                      break;
                    case RiskLevel.critical:
                      riskColor = Colors.purple;
                      break;
                    default:
                      riskColor = Colors.green;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: riskColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person, color: riskColor, size: 20),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                playerName,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(insight.title),
                              SizedBox(height: 4),
                              Text(
                                insight.description,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('CLOSE'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_sessionType == SessionType.training
            ? 'Create Training Session'
            : 'Create Match'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Creating session...'),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Session Type',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<SessionType>(
                            segments: const [
                              ButtonSegment<SessionType>(
                                value: SessionType.training,
                                label: Text('Training'),
                                icon: Icon(Icons.fitness_center),
                              ),
                              ButtonSegment<SessionType>(
                                value: SessionType.match,
                                label: Text('Match'),
                                icon: Icon(Icons.sports_soccer),
                              ),
                            ],
                            selected: {_sessionType},
                            onSelectionChanged:
                                (Set<SessionType> newSelection) {
                              setState(() {
                                _sessionType = newSelection.first;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_sessionType == SessionType.training)
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Training Intensity',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('Low',
                                    style: TextStyle(fontSize: 12)),
                                Expanded(
                                  child: Slider(
                                    value: _intensity.toDouble(),
                                    min: 0,
                                    max: 10,
                                    divisions: 10,
                                    label: _intensity.toString(),
                                    onChanged: (double value) {
                                      setState(() {
                                        _intensity = value.toInt();
                                      });
                                    },
                                  ),
                                ),
                                const Text('High',
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                            Text(
                              'Intensity Level: $_intensity/10',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _intensity > 7
                                    ? Colors.red
                                    : _intensity > 4
                                        ? Colors.orange
                                        : Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Note: Higher intensity may increase injury risk for some players.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Session Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.title, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _titleController,
                                  decoration: const InputDecoration(
                                    labelText: 'Title',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a title';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.access_time, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectDate(context),
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Date',
                                      border: OutlineInputBorder(),
                                    ),
                                    child: Text(
                                      DateFormat('yyyy-MM-dd')
                                          .format(_selectedDate),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectTime(context),
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Time',
                                      border: OutlineInputBorder(),
                                    ),
                                    child: Text(
                                      _selectedTime.format(context),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _locationController,
                                  decoration: const InputDecoration(
                                    labelText: 'Location',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a location';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_sessionType == SessionType.training)
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Training Goal',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.flag, color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonFormField<TrainingFocus>(
                                    decoration: const InputDecoration(
                                      labelText: 'Focus Area',
                                      border: OutlineInputBorder(),
                                    ),
                                    value: _trainingFocus,
                                    items: TrainingFocus.values.map((focus) {
                                      return DropdownMenuItem<TrainingFocus>(
                                        value: focus,
                                        child: Text(
                                            focus.toString().split('.').last),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _trainingFocus = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_sessionType == SessionType.match)
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Match Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.sports_soccer,
                                    color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: 'Opponent Team',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _opponentTeam =
                                            value.isEmpty ? null : value;
                                      });
                                    },
                                    validator: (value) {
                                      if (_sessionType == SessionType.match &&
                                          (value == null || value.isEmpty)) {
                                        return 'Please enter opponent team name';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Select Players',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_selectedPlayers.length} selected',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.people, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _isLoadingPlayers
                                    ? const Center(
                                        child: CircularProgressIndicator())
                                    : _availablePlayers.isEmpty
                                        ? const Center(
                                            child: Text('No players available'),
                                          )
                                        : ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemCount: _availablePlayers.length,
                                            itemBuilder: (context, index) {
                                              final player =
                                                  _availablePlayers[index];
                                              final isSelected =
                                                  _selectedPlayers
                                                      .contains(player.id);

                                              return CheckboxListTile(
                                                title: Text(player.name),
                                                subtitle: Text(
                                                  player.position
                                                      .toString()
                                                      .split('.')
                                                      .last,
                                                ),
                                                value: isSelected,
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    if (value == true) {
                                                      _selectedPlayers
                                                          .add(player.id);
                                                    } else {
                                                      _selectedPlayers
                                                          .remove(player.id);
                                                    }
                                                  });
                                                },
                                              );
                                            },
                                          ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedPlayers = [];
                                  });
                                },
                                child: const Text('Clear All'),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedPlayers = _availablePlayers
                                        .map((p) => p.id)
                                        .toList();
                                  });
                                },
                                child: const Text('Select All'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Coach\'s Comments',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.comment, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _commentsController,
                                  decoration: const InputDecoration(
                                    labelText: 'Comments (Optional)',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 3,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _createSession,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'CREATE SESSION',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../api/services.dart';
import '../../models/models.dart';

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
  String? _opponentTeam;

  List<Player> _availablePlayers = [];
  List<String> _selectedPlayers = [];

  bool _isLoading = false;
  bool _isLoadingPlayers = true;
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

      // Get current user (coach)
      final user = await userService.getCurrentUser();
      if (user is! Coach) {
        throw Exception('Only coaches can create sessions');
      }

      // Create session datetime
      final sessionDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Create session
      final session = Session(
        title: _titleController.text.trim(),
        type: _sessionType,
        dateTime: sessionDateTime,
        location: _locationController.text.trim(),
        coachId: user.id,
        invitedPlayersIds: _selectedPlayers,
        trainingFocus:
            _sessionType == SessionType.training ? _trainingFocus : null,
        opponentTeam: _sessionType == SessionType.match ? _opponentTeam : null,
        coachComments: _commentsController.text.trim(),
      );

      await sessionService.createSession(session);

      // Return to homepage on success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session created successfully')),
        );
        widget.onSessionCreated();
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
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
        title: Text(_sessionType == SessionType.training
            ? 'Create Training Session'
            : 'Create Match'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Session Type Selection
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

                  // Title, Date, Time, Location
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
                          // Title
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
                          // Date & Time
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
                          // Location
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

                  // Type-specific details
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

                  // Players selection
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

                  // Coach's comments
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

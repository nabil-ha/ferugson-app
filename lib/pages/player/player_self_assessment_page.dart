import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api/services.dart';
import '../../models/models.dart';

class PlayerSelfAssessmentPage extends StatefulWidget {
  final Session session;
  final Function(SelfAssessment assessment)? onComplete;

  const PlayerSelfAssessmentPage({
    super.key,
    required this.session,
    this.onComplete,
  });

  @override
  State<PlayerSelfAssessmentPage> createState() =>
      _PlayerSelfAssessmentPageState();
}

class _PlayerSelfAssessmentPageState extends State<PlayerSelfAssessmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _commentsController = TextEditingController();

  int _speed = 5;
  int _stamina = 5;
  int _strength = 5;
  int _fatiguePercentage = 0; // Default value
  bool _isLoading = false;
  bool _isSubmitting = false;
  SelfAssessment? _existingAssessment;

  // Theme colors
  final primaryColor = Color(0xFFC70101); // Rich red
  final accentColor = Color(0xFFFFFFFF); // White
  final backgroundColor = Color(0xFF121212); // Dark background
  final surfaceColor = Color(0xFF1E1E1E); // Slightly lighter surface

  @override
  void initState() {
    super.initState();
    _checkExistingAssessment();
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingAssessment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final selfAssessmentService = SelfAssessmentService(firebaseService);
      final userService = UserService(firebaseService);

      final currentUser = await userService.getCurrentUser();
      if (currentUser == null || currentUser is! Player) {
        throw Exception('Not authenticated as a player');
      }

      // Check if this player already submitted an assessment for this session
      final assessment =
          await selfAssessmentService.getSelfAssessmentForSession(
        currentUser.id,
        widget.session.id,
      );

      if (assessment != null) {
        setState(() {
          _existingAssessment = assessment;
          _speed = assessment.speed;
          _stamina = assessment.stamina;
          _strength = assessment.strength;
          _fatiguePercentage = assessment.fatiguePercentage;
          _commentsController.text = assessment.comments ?? '';
        });
      }
      // Removed the call to _updateFatiguePreview() since we don't want to show prediction before submission
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Get fatigue preview from API - Not called until submission
  Future<int> _calculateFatigueLevel() async {
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final aiService = AIService(firebaseService);

      final fatigue = await aiService.calculateFatiguePercentage(
        _speed,
        _stamina,
        _strength,
      );

      return fatigue;
    } catch (e) {
      // Silently handle error for preview
      print('Error calculating fatigue level: $e');
      return 50; // Default value in case of error
    }
  }

  Future<void> _submitAssessment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final selfAssessmentService = SelfAssessmentService(firebaseService);
      final userService = UserService(firebaseService);
      final sessionService = SessionService(firebaseService);

      final currentUser = await userService.getCurrentUser();
      if (currentUser == null || currentUser is! Player) {
        throw Exception('Not authenticated as a player');
      }

      // Calculate fatigue level only on submission
      final fatigue = await _calculateFatigueLevel();

      SelfAssessment assessment;

      if (_existingAssessment != null) {
        // Update existing assessment
        assessment = _existingAssessment!.copyWith(
          speed: _speed,
          stamina: _stamina,
          strength: _strength,
          fatiguePercentage: fatigue, // Use the calculated value
          comments: _commentsController.text.isNotEmpty
              ? _commentsController.text
              : null,
          updatedAt: DateTime.now(),
        );

        await selfAssessmentService.updateSelfAssessment(assessment);
      } else {
        // Create new assessment
        assessment = await selfAssessmentService.createSelfAssessment(
          playerId: currentUser.id,
          sessionId: widget.session.id,
          speed: _speed,
          stamina: _stamina,
          strength: _strength,
          comments: _commentsController.text.isNotEmpty
              ? _commentsController.text
              : null,
        );
      }

      // Automatically confirm the player's attendance when submitting assessment
      await sessionService.updatePlayerConfirmation(
          widget.session.id, currentUser.id, ConfirmationStatus.confirmed);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assessment submitted and session confirmed'),
            backgroundColor: primaryColor,
          ),
        );

        // Pass the assessment back to the caller
        if (widget.onComplete != null) {
          widget.onComplete!(assessment);
        }

        // Return to previous page
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PLAYER SELF-ASSESSMENT',
          style: GoogleFonts.oswald(
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Session Info Card
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.session.title,
                              style: GoogleFonts.oswald(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 16,
                                    color: accentColor.withOpacity(0.7)),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDate(widget.session.dateTime),
                                  style: GoogleFonts.montserrat(
                                    color: accentColor.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 16,
                                    color: accentColor.withOpacity(0.7)),
                                const SizedBox(width: 8),
                                Text(
                                  widget.session.location,
                                  style: GoogleFonts.montserrat(
                                    color: accentColor.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'HOW DO YOU FEEL?',
                      style: GoogleFonts.oswald(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rate your physical condition from 1 (very poor) to 10 (excellent)',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: accentColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Speed Rating
                    _buildRatingSlider(
                      'Speed',
                      'How fast you can move',
                      Icons.speed,
                      _speed,
                      (value) {
                        setState(() {
                          _speed = value.round();
                        });
                      },
                      Colors.blue,
                    ),

                    const SizedBox(height: 16),

                    // Stamina Rating
                    _buildRatingSlider(
                      'Stamina',
                      'How much energy you have',
                      Icons.battery_full,
                      _stamina,
                      (value) {
                        setState(() {
                          _stamina = value.round();
                        });
                      },
                      Colors.green,
                    ),

                    const SizedBox(height: 16),

                    // Strength Rating
                    _buildRatingSlider(
                      'Strength',
                      'How powerful you feel',
                      Icons.fitness_center,
                      _strength,
                      (value) {
                        setState(() {
                          _strength = value.round();
                        });
                      },
                      primaryColor,
                    ),

                    const SizedBox(height: 24),

                    // Only show fatigue card if assessment already exists
                    if (_existingAssessment != null) ...[
                      // Fatigue Percentage Card
                      Card(
                        color: _calculateFatigueColor(),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI FATIGUE ASSESSMENT',
                                style: GoogleFonts.oswald(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Based on your ratings, your fatigue level is:',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: Text(
                                  '$_fatiguePercentage%',
                                  style: GoogleFonts.oswald(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  _getFatigueMessage(),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Comments field
                    TextFormField(
                      controller: _commentsController,
                      style: TextStyle(color: accentColor),
                      decoration: InputDecoration(
                        labelText: 'Additional Comments',
                        labelStyle:
                            TextStyle(color: accentColor.withOpacity(0.7)),
                        hintText: 'Any specific areas of concern?',
                        hintStyle:
                            TextStyle(color: accentColor.withOpacity(0.5)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: primaryColor.withOpacity(0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor),
                        ),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitAssessment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: accentColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: accentColor,
                                  strokeWidth: 2.0,
                                ),
                              )
                            : Text(
                                _existingAssessment != null
                                    ? 'UPDATE ASSESSMENT'
                                    : 'SUBMIT ASSESSMENT',
                                style: GoogleFonts.oswald(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                      ),
                    ),

                    // Add note about the AI calculation
                    if (_existingAssessment == null) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'Once submitted, AI will analyze your fatigue level',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: accentColor.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildRatingSlider(
    String title,
    String description,
    IconData icon,
    int value,
    Function(double) onChanged,
    Color color,
  ) {
    return Card(
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
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.oswald(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              description,
              style: GoogleFonts.montserrat(
                color: accentColor.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('1',
                    style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        color: accentColor.withOpacity(0.7))),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: color,
                      inactiveTrackColor: color.withOpacity(0.2),
                      thumbColor: color,
                      overlayColor: color.withOpacity(0.2),
                      valueIndicatorColor: color,
                      valueIndicatorTextStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Slider(
                      value: value.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: value.toString(),
                      onChanged: onChanged,
                    ),
                  ),
                ),
                Text('10',
                    style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        color: accentColor.withOpacity(0.7))),
              ],
            ),
            Center(
              child: Text(
                _getRatingDescription(title, value),
                style: GoogleFonts.montserrat(
                  fontStyle: FontStyle.italic,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingDescription(String type, int value) {
    if (value <= 3) return 'Poor';
    if (value <= 5) return 'Average';
    if (value <= 8) return 'Good';
    return 'Excellent';
  }

  Color _calculateFatigueColor() {
    if (_fatiguePercentage < 30) return Colors.green.shade700;
    if (_fatiguePercentage < 60) return Colors.orange.shade800;
    return primaryColor;
  }

  String _getFatigueMessage() {
    if (_fatiguePercentage < 30) return 'You seem to be in good shape!';
    if (_fatiguePercentage < 60) return 'You should get some rest.';
    return 'You need to recover properly!';
  }
}

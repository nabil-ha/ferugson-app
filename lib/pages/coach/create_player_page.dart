import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../api/services.dart';
import '../../models/models.dart';

class CreatePlayerPage extends StatefulWidget {
  const CreatePlayerPage({super.key});

  @override
  _CreatePlayerPageState createState() => _CreatePlayerPageState();
}

class _CreatePlayerPageState extends State<CreatePlayerPage> {
  final _formKey = GlobalKey<FormState>();

  // Basic player info fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  PlayerPosition _selectedPosition = PlayerPosition.midfielder;

  // Physical attributes for AI predictions
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _previousInjuriesController = TextEditingController();
  DateTime? _selectedBirthdate;

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _previousInjuriesController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthdate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthdate ??
          DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedBirthdate) {
      setState(() {
        _selectedBirthdate = picked;
      });
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    // Simple email validation
    if (!value.contains('@') || !value.contains('.')) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    return null;
  }

  String? _validateNumber(String? value, String fieldName) {
    if (value != null && value.isNotEmpty) {
      try {
        int.parse(value);
        return null;
      } catch (e) {
        return '$fieldName must be a number';
      }
    }
    return null;
  }

  Future<void> _createPlayer() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userService = Provider.of<UserService>(context, listen: false);

        // Parse optional physical attributes
        int? height = _heightController.text.isNotEmpty
            ? int.tryParse(_heightController.text)
            : null;

        int? weight = _weightController.text.isNotEmpty
            ? int.tryParse(_weightController.text)
            : null;

        int? previousInjuries = _previousInjuriesController.text.isNotEmpty
            ? int.tryParse(_previousInjuriesController.text)
            : null;

        // Create player with physical attributes for AI predictions
        await userService.createPlayer(
          _nameController.text,
          _emailController.text,
          'Password123', // Default password that should be changed on first login
          _selectedPosition,
          birthdate: _selectedBirthdate,
          height: height,
          weight: weight,
          previousInjuries: previousInjuries,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Player created successfully')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating player: ${e.toString()}')),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Player'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Basic Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: _validateName,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<PlayerPosition>(
                      decoration: const InputDecoration(
                        labelText: 'Position',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedPosition,
                      items: PlayerPosition.values.map((position) {
                        return DropdownMenuItem<PlayerPosition>(
                          value: position,
                          child: Text(position.toString().split('.').last),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedPosition = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 32),
                    const Text(
                      'Physical Attributes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'These data help our AI provide better injury risk and performance predictions',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Birthdate picker
                    InkWell(
                      onTap: _selectBirthdate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date of Birth',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _selectedBirthdate != null
                              ? DateFormat('dd/MM/yyyy')
                                  .format(_selectedBirthdate!)
                              : 'Select birthdate',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Height field
                    TextFormField(
                      controller: _heightController,
                      decoration: const InputDecoration(
                        labelText: 'Height (cm)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => _validateNumber(value, 'Height'),
                    ),
                    const SizedBox(height: 16),

                    // Weight field
                    TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => _validateNumber(value, 'Weight'),
                    ),
                    const SizedBox(height: 16),

                    // Previous injuries field
                    TextFormField(
                      controller: _previousInjuriesController,
                      decoration: const InputDecoration(
                        labelText: 'Previous Injuries Count',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          _validateNumber(value, 'Previous injuries'),
                    ),

                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _createPlayer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Create Player'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

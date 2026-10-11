import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddDoctorScreen extends StatefulWidget {
  const AddDoctorScreen({super.key});

  @override
  State<AddDoctorScreen> createState() => _AddDoctorScreenState();
}

class _AddDoctorScreenState extends State<AddDoctorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specializationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _feeController = TextEditingController();

  bool _isSaving = false;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _saveDoctor() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final experienceText = _experienceController.text.trim();
      final feeText = _feeController.text.trim();

      final experience = experienceText.isEmpty
          ? null
          : int.tryParse(experienceText);

      final consultationFee =
          feeText.isEmpty ? null : double.tryParse(feeText);

      if (experienceText.isNotEmpty && experience == null) {
        _showError('Please enter a valid experience in years.');
        return;
      }

      if (feeText.isNotEmpty && consultationFee == null) {
        _showError('Please enter a valid consultation fee.');
        return;
      }

      final response = await _client.functions.invoke(
        'create-doctor',
        body: {
          'full_name': _nameController.text.trim(),
          'email': _emailController.text.trim().toLowerCase(),
          'phone': _phoneController.text.trim(),
          'specialization': _specializationController.text.trim(),
          'experience': experience,
          'consultation_fee': consultationFee,
        },
      );

      final responseData = response.data;

      if (responseData is Map) {
        final success = responseData['success'] == true;

        if (!success) {
          final errorMessage =
              responseData['error']?.toString() ??
              'Unable to create doctor.';

          final details = responseData['details']?.toString();

          if (details != null && details.isNotEmpty) {
            _showError('$errorMessage\n$details');
          } else {
            _showError(errorMessage);
          }

          return;
        }

        if (!mounted) {
          return;
        }

        final doctorData = responseData['doctor'];

        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Doctor Added'),
                  ),
                ],
              ),
              content: Text(
                doctorData is Map
                    ? 'Dr. ${doctorData['full_name'] ?? _nameController.text.trim()} '
                        'has been added successfully.\n\n'
                        'A login invitation has been sent to '
                        '${doctorData['email'] ?? _emailController.text.trim()}.'
                    : 'Doctor has been added successfully.\n\n'
                        'A login invitation has been sent to '
                        '${_emailController.text.trim()}.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );

        if (!mounted) {
          return;
        }

        Navigator.of(context).pop(true);
        return;
      }

      _showError('Unexpected response from the server.');
    } on FunctionException catch (error) {
      final details = error.details;

      if (details is Map) {
        final message =
            details['error']?.toString() ??
            details['message']?.toString() ??
            'Unable to create doctor.';

        final extraDetails = details['details']?.toString();

        if (extraDetails != null && extraDetails.isNotEmpty) {
          _showError('$message\n$extraDetails');
        } else {
          _showError(message);
        }
      } else {
        _showError(
          error.reasonPhrase ??
          'Unable to create doctor.',
        );
      }
    } catch (error) {
      _showError(
        'Unable to create doctor.\n$error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
    );
  }

  String? _requiredValidator(
    String? value,
    String fieldName,
  ) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final email = value.trim();

    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Doctor'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              enabled: !_isSaving,
              decoration: _inputDecoration(
                'Doctor Name',
                Icons.person_outline,
              ),
              validator: (value) {
                return _requiredValidator(
                  value,
                  'Doctor name',
                );
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              enabled: !_isSaving,
              decoration: _inputDecoration(
                'Email',
                Icons.email_outlined,
              ),
              validator: _emailValidator,
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              enabled: !_isSaving,
              decoration: _inputDecoration(
                'Phone',
                Icons.phone_outlined,
              ),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _specializationController,
              textCapitalization: TextCapitalization.words,
              enabled: !_isSaving,
              decoration: _inputDecoration(
                'Specialization',
                Icons.medical_services_outlined,
              ),
              validator: (value) {
                return _requiredValidator(
                  value,
                  'Specialization',
                );
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _experienceController,
              keyboardType: TextInputType.number,
              enabled: !_isSaving,
              decoration: _inputDecoration(
                'Experience',
                Icons.work_outline,
              ).copyWith(
                suffixText: 'years',
              ),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _feeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              enabled: !_isSaving,
              decoration: _inputDecoration(
                'Consultation Fee',
                Icons.currency_rupee,
              ).copyWith(
                prefixText: '₹ ',
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveDoctor,
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Save Doctor',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
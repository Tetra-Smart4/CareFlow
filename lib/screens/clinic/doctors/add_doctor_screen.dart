import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../repositories/clinic_repository.dart';

class AddDoctorScreen extends StatefulWidget {
  final bool? isClinicApprovedForTesting;

  const AddDoctorScreen({super.key, this.isClinicApprovedForTesting});

  @override
  State<AddDoctorScreen> createState() => _AddDoctorScreenState();
}

class _AddDoctorScreenState extends State<AddDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clinicRepo = ClinicRepository();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specializationController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _feeController = TextEditingController();

  bool _isSaving = false;
  bool _isCheckingClinic = true;
  bool _isClinicApproved = true;
  String? _clinicStatusMessage;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    if (widget.isClinicApprovedForTesting != null) {
      _isClinicApproved = widget.isClinicApprovedForTesting!;
      _isCheckingClinic = false;
      if (!_isClinicApproved) {
        _clinicStatusMessage =
            'Your clinic registration is awaiting platform administrator approval.';
      }
    } else {
      _checkClinicApproval();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _regNumberController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _checkClinicApproval() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        setState(() {
          _isCheckingClinic = false;
          _isClinicApproved = false;
          _clinicStatusMessage = 'User not authenticated.';
        });
        return;
      }

      final clinicId = await _clinicRepo.getCurrentUserClinicId() ?? user.id;
      final clinic = await _clinicRepo.getById(clinicId);

      final status = (clinic?['status'] ?? 'approved').toString().toLowerCase();
      if (status != 'approved') {
        setState(() {
          _isCheckingClinic = false;
          _isClinicApproved = false;
          _clinicStatusMessage =
              'Your clinic registration status is currently "$status". Only platform-approved clinics can invite and add doctors.';
        });
        return;
      }

      setState(() {
        _isCheckingClinic = false;
        _isClinicApproved = true;
      });
    } catch (_) {
      setState(() {
        _isCheckingClinic = false;
        _isClinicApproved = true;
      });
    }
  }

  Future<void> _saveDoctor() async {
    if (!_isClinicApproved) {
      _showError(_clinicStatusMessage ?? 'Clinic is not approved to add doctors.');
      return;
    }

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
          'action': 'create',
          'full_name': _nameController.text.trim(),
          'email': _emailController.text.trim().toLowerCase(),
          'phone': _phoneController.text.trim(),
          'specialization': _specializationController.text.trim(),
          'qualification': _qualificationController.text.trim(),
          'experience': experience,
          'registration_number': _regNumberController.text.trim(),
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
        final message = responseData['message']?.toString() ??
            'Doctor invited successfully.';

        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: ColorTokens.careGreen,
                    size: 28,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Doctor Onboarded',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: const TextStyle(fontSize: 14, color: ColorTokens.darkNavy),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColorTokens.lightBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Doctor: Dr. ${doctorData is Map ? (doctorData['full_name'] ?? _nameController.text.trim()) : _nameController.text.trim()}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Email: ${_emailController.text.trim().toLowerCase()}',
                          style: const TextStyle(fontSize: 12, color: ColorTokens.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Status: Invited (Pending Password Setup)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ColorTokens.careGreen),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorTokens.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Done'),
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
        backgroundColor: ColorTokens.error,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: ColorTokens.primaryBlue, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ColorTokens.border),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingClinic) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Doctor')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isClinicApproved) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Doctor')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_clock_rounded, size: 64, color: ColorTokens.warning),
                const SizedBox(height: 16),
                const Text(
                  'Clinic Approval Required',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ColorTokens.darkNavy),
                ),
                const SizedBox(height: 8),
                Text(
                  _clinicStatusMessage ??
                      'Your clinic registration is awaiting platform administrator approval.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: ColorTokens.muted, fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to Clinic Dashboard'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Invite & Add Doctor'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Informational Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ColorTokens.lightBlue,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ColorTokens.primaryBlue.withValues(alpha: 0.2)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.mail_outline_rounded, color: ColorTokens.primaryBlue, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'The doctor will receive a secure email invitation with a single-use activation link. They will verify their email and set their own password.',
                      style: TextStyle(fontSize: 12.5, color: ColorTokens.darkNavy, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Doctor Name
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              enabled: !_isSaving,
              decoration: _inputDecoration(
                'Doctor Full Name *',
                Icons.person_outline,
                hint: 'e.g., Dr. Jane Doe',
              ),
              validator: (value) => _requiredValidator(value, 'Doctor full name'),
            ),
            const SizedBox(height: 14),

            // Email Address
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              enabled: !_isSaving,
              decoration: _inputDecoration(
                'Email Address (Invitation Recipient) *',
                Icons.email_outlined,
                hint: 'doctor@careflow.com',
              ),
              validator: _emailValidator,
            ),
            const SizedBox(height: 14),

            // Phone Number
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              enabled: !_isSaving,
              decoration: _inputDecoration(
                'Contact Phone',
                Icons.phone_outlined,
                hint: '+91 9876543210',
              ),
            ),
            const SizedBox(height: 14),

            // Specialization
            TextFormField(
              controller: _specializationController,
              textCapitalization: TextCapitalization.words,
              enabled: !_isSaving,
              decoration: _inputDecoration(
                'Specialization *',
                Icons.medical_services_outlined,
                hint: 'e.g., Cardiologist, General Physician',
              ),
              validator: (value) => _requiredValidator(value, 'Specialization'),
            ),
            const SizedBox(height: 14),

            // Qualification
            TextFormField(
              controller: _qualificationController,
              textCapitalization: TextCapitalization.characters,
              enabled: !_isSaving,
              decoration: _inputDecoration(
                'Qualification',
                Icons.school_outlined,
                hint: 'e.g., MBBS, MD, MS',
              ),
            ),
            const SizedBox(height: 14),

            // Medical Registration Number
            TextFormField(
              controller: _regNumberController,
              textCapitalization: TextCapitalization.characters,
              enabled: !_isSaving,
              decoration: _inputDecoration(
                'Medical Council Registration Number',
                Icons.badge_outlined,
                hint: 'e.g., MCI-2018-98421',
              ),
            ),
            const SizedBox(height: 14),

            // Experience
            TextFormField(
              controller: _experienceController,
              keyboardType: TextInputType.number,
              enabled: !_isSaving,
              decoration: _inputDecoration(
                'Years of Experience',
                Icons.work_outline,
              ).copyWith(suffixText: 'years'),
            ),
            const SizedBox(height: 14),

            // Consultation Fee
            TextFormField(
              controller: _feeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enabled: !_isSaving,
              decoration: _inputDecoration(
                'Initial Consultation Fee (₹)',
                Icons.currency_rupee,
                hint: '500',
              ).copyWith(prefixText: '₹ '),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveDoctor,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _isSaving
                    ? const SizedBox.shrink()
                    : const Icon(Icons.send_rounded, size: 20),
                label: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Send Doctor Invitation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
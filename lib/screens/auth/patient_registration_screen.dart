import 'package:flutter/material.dart';
import '../../core/theme/color_tokens.dart';
import '../../services/auth_service.dart';

class PatientRegistrationScreen extends StatefulWidget {
  const PatientRegistrationScreen({super.key});

  @override
  State<PatientRegistrationScreen> createState() => _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState extends State<PatientRegistrationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // ACCOUNT DETAILS
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // PERSONAL DETAILS
  final TextEditingController _dobController = TextEditingController();
  DateTime? _selectedDob;
  String _selectedGender = 'Male';
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _acceptedTerms = true;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ColorTokens.primaryBlue,
              onPrimary: Colors.white,
              onSurface: ColorTokens.darkNavy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _handleRegister() async {
    if (_isLoading) return;

    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    if (!_acceptedTerms) {
      setState(() {
        _errorMessage = 'Please accept the Terms of Service to create an account.';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AuthService().registerPatient(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        dateOfBirth: _selectedDob,
        gender: _selectedGender,
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
      );

      if (!mounted) return;

      if (!result.success) {
        setState(() {
          _isLoading = false;
          _errorMessage = result.error ?? 'Unable to create your account. Please try again.';
        });
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: ColorTokens.careGreen,
          content: Text('Registration successful! Welcome to CareFlow.'),
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        result.destinationRoute ?? '/patient/dashboard',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Registration error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ColorTokens.darkNavy),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Patient Registration',
          style: TextStyle(
            color: ColorTokens.darkNavy,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: ColorTokens.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: ColorTokens.lightBlue,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.person_add_rounded,
                                color: ColorTokens.primaryBlue,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Create Patient Account',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: ColorTokens.darkNavy,
                                    ),
                                  ),
                                  Text(
                                    'Connect directly to appointments and doctors',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: ColorTokens.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Error Banner
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: ColorTokens.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: ColorTokens.error.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: ColorTokens.error, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: ColorTokens.error,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // SECTION 1: ACCOUNT DETAILS
                        _buildSectionHeader('1. Account Details', Icons.lock_outline_rounded),
                        const SizedBox(height: 14),

                        _buildLabel('Full Name *'),
                        TextFormField(
                          key: const Key('patient_name_field'),
                          controller: _fullNameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: _inputDecoration('e.g. John Doe', Icons.person_outline),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Full Name is required.' : null,
                        ),
                        const SizedBox(height: 14),

                        _buildLabel('Email Address *'),
                        TextFormField(
                          key: const Key('patient_email_field'),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration('e.g. john@example.com', Icons.email_outlined),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Email is required.';
                            final email = v.trim();
                            if (!email.contains('@') || !email.contains('.')) return 'Please enter a valid email address.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        _buildLabel('Phone Number *'),
                        TextFormField(
                          key: const Key('patient_phone_field'),
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: _inputDecoration('e.g. +91 9876543210', Icons.phone_outlined),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Phone number is required.';
                            if (v.trim().length < 8) return 'Please enter a valid phone number.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Password *'),
                                  TextFormField(
                                    key: const Key('patient_password_field'),
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    decoration: _inputDecoration(
                                      'Min 6 chars',
                                      Icons.lock_outline,
                                      suffix: IconButton(
                                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Password required.';
                                      if (v.length < 6) return 'Min 6 characters.';
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Confirm Password *'),
                                  TextFormField(
                                    key: const Key('patient_confirm_password_field'),
                                    controller: _confirmPasswordController,
                                    obscureText: _obscureConfirmPassword,
                                    decoration: _inputDecoration(
                                      'Repeat password',
                                      Icons.lock_outline,
                                      suffix: IconButton(
                                        icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, size: 18),
                                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Confirm password.';
                                      if (v != _passwordController.text) return 'Passwords do not match.';
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // SECTION 2: PERSONAL DETAILS
                        _buildSectionHeader('2. Personal Details', Icons.badge_outlined),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Date of Birth *'),
                                  TextFormField(
                                    key: const Key('patient_dob_field'),
                                    controller: _dobController,
                                    readOnly: true,
                                    onTap: _pickDateOfBirth,
                                    decoration: _inputDecoration(
                                      'YYYY-MM-DD',
                                      Icons.calendar_today_outlined,
                                      suffix: const Icon(Icons.arrow_drop_down),
                                    ),
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'DOB is required.' : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Gender *'),
                                  DropdownButtonFormField<String>(
                                    key: const Key('patient_gender_field'),
                                    initialValue: _selectedGender,
                                    decoration: _inputDecoration('', Icons.people_outline),
                                    items: const [
                                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedGender = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        _buildLabel('Street Address *'),
                        TextFormField(
                          key: const Key('patient_address_field'),
                          controller: _addressController,
                          decoration: _inputDecoration('House / Flat, Street name', Icons.home_outlined),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Address is required.' : null,
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('City *'),
                                  TextFormField(
                                    key: const Key('patient_city_field'),
                                    controller: _cityController,
                                    decoration: _inputDecoration('City', Icons.location_city_outlined),
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'City required.' : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('State *'),
                                  TextFormField(
                                    key: const Key('patient_state_field'),
                                    controller: _stateController,
                                    decoration: _inputDecoration('State', Icons.map_outlined),
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'State required.' : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Pincode *'),
                                  TextFormField(
                                    key: const Key('patient_pincode_field'),
                                    controller: _pincodeController,
                                    keyboardType: TextInputType.number,
                                    decoration: _inputDecoration('Pincode', Icons.pin_drop_outlined),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return 'Pincode required.';
                                      if (v.trim().length < 4) return 'Invalid pincode.';
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Important UX Notice (Emergency contacts configured post-login)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ColorTokens.lightBlue.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: ColorTokens.border),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: ColorTokens.primaryBlue, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Emergency contacts and medical history will be safely added inside your account profile after login.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ColorTokens.darkNavy,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Terms Checkbox
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: _acceptedTerms,
                          onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
                          title: const Text(
                            'I agree to CareFlow Terms of Service and Privacy Policy.',
                            style: TextStyle(fontSize: 13, color: ColorTokens.textSecondary),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // [ SUBMIT REGISTRATION ]
                        ElevatedButton(
                          key: const Key('submit_patient_registration_button'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorTokens.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _isLoading ? null : _handleRegister,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Register as Patient',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 20),

                        // Back to login
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, '/auth/login'),
                            child: const Text(
                              'Already have an account? Login',
                              style: TextStyle(
                                color: ColorTokens.primaryBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: ColorTokens.primaryBlue),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: ColorTokens.darkNavy,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: ColorTokens.darkNavy,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: ColorTokens.textMuted),
      suffixIcon: suffix,
      filled: true,
      fillColor: ColorTokens.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ColorTokens.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ColorTokens.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ColorTokens.primaryBlue, width: 1.5),
      ),
    );
  }
}

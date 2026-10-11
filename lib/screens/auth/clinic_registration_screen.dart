import 'package:flutter/material.dart';
import '../../core/theme/color_tokens.dart';
import '../../services/auth_service.dart';

class ClinicRegistrationScreen extends StatefulWidget {
  const ClinicRegistrationScreen({super.key});

  @override
  State<ClinicRegistrationScreen> createState() => _ClinicRegistrationScreenState();
}

class _ClinicRegistrationScreenState extends State<ClinicRegistrationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // CLINIC DETAILS
  final TextEditingController _clinicNameController = TextEditingController();
  final TextEditingController _clinicEmailController = TextEditingController();
  final TextEditingController _clinicPhoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  String _selectedClinicType = 'Multi-Specialty Clinic';
  final TextEditingController _aboutController = TextEditingController();

  // AUTHORIZED ACCOUNT CONTACT
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _acceptedTerms = true;
  String? _errorMessage;

  @override
  void dispose() {
    _clinicNameController.dispose();
    _clinicEmailController.dispose();
    _clinicPhoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _aboutController.dispose();
    _contactNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_isLoading) return;

    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    if (!_acceptedTerms) {
      setState(() {
        _errorMessage = 'Please accept the healthcare platform terms to continue.';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final contactEmail = _contactEmailController.text.trim().isNotEmpty
          ? _contactEmailController.text.trim()
          : _clinicEmailController.text.trim();
      final contactPhone = _contactPhoneController.text.trim().isNotEmpty
          ? _contactPhoneController.text.trim()
          : _clinicPhoneController.text.trim();
      final contactName = _contactNameController.text.trim().isNotEmpty
          ? _contactNameController.text.trim()
          : 'Clinic Administrator';

      final result = await AuthService().registerClinic(
        email: contactEmail,
        password: _passwordController.text,
        clinicName: _clinicNameController.text.trim(),
        contactName: contactName,
        phone: contactPhone,
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        clinicType: _selectedClinicType,
        about: _aboutController.text.trim(),
      );

      if (!mounted) return;

      if (!result.success) {
        setState(() {
          _isLoading = false;
          _errorMessage = result.error ?? 'Unable to register clinic. Please try again.';
        });
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: ColorTokens.careGreen,
          content: Text('Clinic registration submitted successfully for review.'),
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        result.destinationRoute ?? '/clinic/pending',
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
          'Clinic Registration',
          style: TextStyle(
            color: ColorTokens.darkNavy,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth >= 520;
              final double cardPaddingH = constraints.maxWidth < 400 ? 16.0 : 26.0;
              final double cardPaddingV = constraints.maxWidth < 400 ? 20.0 : 28.0;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth < 360 ? 10.0 : 16.0,
                  vertical: 16.0,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: const BorderSide(color: ColorTokens.border),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: cardPaddingH,
                        vertical: cardPaddingV,
                      ),
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
                                    color: ColorTokens.careGreen.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.local_hospital_rounded,
                                    color: ColorTokens.careGreen,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Register Your Clinic',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: ColorTokens.darkNavy,
                                        ),
                                      ),
                                      Text(
                                        'Applications are reviewed by platform administration',
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
                                  border: Border.all(
                                    color: ColorTokens.error.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: ColorTokens.error,
                                      size: 20,
                                    ),
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

                            // ==========================================
                            // SECTION 1: CLINIC DETAILS
                            // ==========================================
                            _buildSectionHeader('1. Clinic Details', Icons.business_rounded),
                            const SizedBox(height: 16),

                            // ROW 1: Clinic Name | Email Address
                            _buildResponsiveRow(
                              isWide,
                              [
                                _buildField(
                                  'Clinic Name *',
                                  TextFormField(
                                    key: const Key('clinic_name_field'),
                                    controller: _clinicNameController,
                                    textCapitalization: TextCapitalization.words,
                                    decoration: _inputDecoration(
                                      'e.g. City Health Clinic',
                                      Icons.apartment_outlined,
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty) ? 'Clinic Name is required.' : null,
                                  ),
                                ),
                                _buildField(
                                  'Email Address *',
                                  TextFormField(
                                    key: const Key('clinic_email_field'),
                                    controller: _clinicEmailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: _inputDecoration(
                                      'clinic@example.com',
                                      Icons.email_outlined,
                                    ),
                                    onChanged: (val) {
                                      if (_contactEmailController.text.isEmpty) {
                                        _contactEmailController.text = val;
                                      }
                                    },
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return 'Clinic email is required.';
                                      if (!v.contains('@') || !v.contains('.')) {
                                        return 'Please enter a valid email address.';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // ROW 2: Phone Number | Password
                            _buildResponsiveRow(
                              isWide,
                              [
                                _buildField(
                                  'Phone Number *',
                                  TextFormField(
                                    key: const Key('clinic_phone_field'),
                                    controller: _clinicPhoneController,
                                    keyboardType: TextInputType.phone,
                                    decoration: _inputDecoration(
                                      '+91 9876543210',
                                      Icons.phone_outlined,
                                    ),
                                    onChanged: (val) {
                                      if (_contactPhoneController.text.isEmpty) {
                                        _contactPhoneController.text = val;
                                      }
                                    },
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty) ? 'Clinic phone required.' : null,
                                  ),
                                ),
                                _buildField(
                                  'Password *',
                                  TextFormField(
                                    key: const Key('clinic_password_field'),
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    decoration: _inputDecoration(
                                      'Min 6 chars',
                                      Icons.lock_outline,
                                      suffix: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                          size: 18,
                                        ),
                                        onPressed: () =>
                                            setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Password required.';
                                      if (v.length < 6) return 'Min 6 characters.';
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // ROW 3: Confirm Password | Clinic Type
                            _buildResponsiveRow(
                              isWide,
                              [
                                _buildField(
                                  'Confirm Password *',
                                  TextFormField(
                                    key: const Key('clinic_confirm_password_field'),
                                    controller: _confirmPasswordController,
                                    obscureText: _obscureConfirmPassword,
                                    decoration: _inputDecoration(
                                      'Repeat password',
                                      Icons.lock_outline,
                                      suffix: IconButton(
                                        icon: Icon(
                                          _obscureConfirmPassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          size: 18,
                                        ),
                                        onPressed: () => setState(
                                            () => _obscureConfirmPassword = !_obscureConfirmPassword),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Confirm password.';
                                      if (v != _passwordController.text) return 'Passwords do not match.';
                                      return null;
                                    },
                                  ),
                                ),
                                _buildField(
                                  'Clinic Type *',
                                  DropdownButtonFormField<String>(
                                    key: const Key('clinic_type_field'),
                                    initialValue: _selectedClinicType,
                                    isExpanded: true,
                                    decoration: _inputDecoration('', Icons.category_outlined),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Multi-Specialty Clinic',
                                        child: Text('Multi-Specialty Clinic'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'General Practice',
                                        child: Text('General Practice'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Dental Clinic',
                                        child: Text('Dental Clinic'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Eye Care / Ophthalmology',
                                        child: Text('Eye Care / Ophthalmology'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Diagnostic Center',
                                        child: Text('Diagnostic Center'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Pediatric Clinic',
                                        child: Text('Pediatric Clinic'),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedClinicType = val);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // ROW 4: Street Address — full width
                            _buildField(
                              'Street Address *',
                              TextFormField(
                                key: const Key('clinic_address_field'),
                                controller: _addressController,
                                decoration: _inputDecoration(
                                  'Street Address, Building, Floor',
                                  Icons.location_on_outlined,
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty) ? 'Address is required.' : null,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // ROW 5: City | State | Pincode
                            _buildResponsiveRow(
                              isWide,
                              [
                                _buildField(
                                  'City *',
                                  TextFormField(
                                    key: const Key('clinic_city_field'),
                                    controller: _cityController,
                                    decoration: _inputDecoration(
                                      'City',
                                      Icons.location_city_outlined,
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty) ? 'City required.' : null,
                                  ),
                                ),
                                _buildField(
                                  'State *',
                                  TextFormField(
                                    key: const Key('clinic_state_field'),
                                    controller: _stateController,
                                    decoration: _inputDecoration(
                                      'State',
                                      Icons.map_outlined,
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty) ? 'State required.' : null,
                                  ),
                                ),
                                _buildField(
                                  'Pincode *',
                                  TextFormField(
                                    key: const Key('clinic_pincode_field'),
                                    controller: _pincodeController,
                                    keyboardType: TextInputType.number,
                                    decoration: _inputDecoration(
                                      'Pincode',
                                      Icons.pin_drop_outlined,
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty) ? 'Pincode required.' : null,
                                  ),
                                ),
                              ],
                              spacing: 12.0,
                            ),
                            const SizedBox(height: 24),

                            // ==========================================
                            // SECTION 2: AUTHORIZED ACCOUNT CONTACT
                            // ==========================================
                            _buildSectionHeader('2. Authorized Account Contact', Icons.badge_outlined),
                            const SizedBox(height: 16),

                            // ROW 6: Contact Person Full Name | Contact Email
                            _buildResponsiveRow(
                              isWide,
                              [
                                _buildField(
                                  'Contact Person Full Name *',
                                  TextFormField(
                                    key: const Key('contact_name_field'),
                                    controller: _contactNameController,
                                    textCapitalization: TextCapitalization.words,
                                    decoration: _inputDecoration(
                                      'e.g. Dr. Jane Smith / Administrator',
                                      Icons.person_outline,
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty) ? 'Contact Name is required.' : null,
                                  ),
                                ),
                                _buildField(
                                  'Contact Email (Login ID) *',
                                  TextFormField(
                                    key: const Key('contact_email_field'),
                                    controller: _contactEmailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: _inputDecoration(
                                      'contact@example.com',
                                      Icons.email_outlined,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Contact email is required.';
                                      }
                                      if (!v.contains('@')) return 'Invalid email.';
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // ROW 7: Contact Phone | About / Description
                            _buildResponsiveRow(
                              isWide,
                              [
                                _buildField(
                                  'Contact Phone *',
                                  TextFormField(
                                    key: const Key('contact_phone_field'),
                                    controller: _contactPhoneController,
                                    keyboardType: TextInputType.phone,
                                    decoration: _inputDecoration(
                                      '+91 9876543210',
                                      Icons.phone_outlined,
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty) ? 'Contact phone required.' : null,
                                  ),
                                ),
                                _buildField(
                                  'About / Description',
                                  TextFormField(
                                    key: const Key('clinic_about_field'),
                                    controller: _aboutController,
                                    maxLines: 1,
                                    decoration: _inputDecoration(
                                      'Facilities & specialties overview',
                                      Icons.info_outline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Pending Status Notice (Section 15 & 16)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: ColorTokens.warning.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: ColorTokens.warning.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.hourglass_top_rounded,
                                    color: ColorTokens.warning,
                                    size: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Clinic registrations enter PENDING status and must be reviewed and approved by Platform Administration before normal operations commence.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: ColorTokens.darkNavy,
                                        fontWeight: FontWeight.w600,
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
                                'I confirm that I am authorized to register this medical facility and agree to terms.',
                                style: TextStyle(fontSize: 13, color: ColorTokens.textSecondary),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // [ SUBMIT REGISTRATION ]
                            ElevatedButton(
                              key: const Key('submit_clinic_registration_button'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorTokens.careGreen,
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
                                      'Submit Clinic Registration',
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
                                onPressed: () =>
                                    Navigator.pushReplacementNamed(context, '/auth/login'),
                                child: const Text(
                                  'Already registered? Login',
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
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveRow(
    bool isWide,
    List<Widget> children, {
    double spacing = 14.0,
  }) {
    if (!isWide || children.length <= 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: spacing),
            children[i],
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          Expanded(child: children[i]),
        ],
      ],
    );
  }

  Widget _buildField(String label, Widget input) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLabel(label),
        input,
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: ColorTokens.careGreen),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: ColorTokens.darkNavy,
            ),
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
        borderSide: const BorderSide(color: ColorTokens.careGreen, width: 1.5),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum LoginRole {
  patient,
  doctor,
  clinic,
}

class LoginScreen extends StatefulWidget {
  final LoginRole initialRole;

  const LoginScreen({
    super.key,
    this.initialRole = LoginRole.patient,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  late LoginRole _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _roleTitle {
    switch (_selectedRole) {
      case LoginRole.patient:
        return 'Patient';
      case LoginRole.doctor:
        return 'Doctor';
      case LoginRole.clinic:
        return 'Clinic';
    }
  }

  String get _roleDescription {
    switch (_selectedRole) {
      case LoginRole.patient:
        return 'Access your appointments, medical records and health information.';
      case LoginRole.doctor:
        return 'Manage appointments, patients and consultations.';
      case LoginRole.clinic:
        return 'Manage your clinic, doctors, patients and daily operations.';
    }
  }

  String get _loginButtonText {
    return 'Login as $_roleTitle';
  }

  String _roleToDatabaseValue(LoginRole role) {
    switch (role) {
      case LoginRole.patient:
        return 'patient';
      case LoginRole.doctor:
        return 'doctor';
      case LoginRole.clinic:
        return 'clinic';
    }
  }

  LoginRole? _databaseRoleToLoginRole(String? role) {
    switch (role?.trim().toLowerCase()) {
      case 'patient':
        return LoginRole.patient;
      case 'doctor':
        return LoginRole.doctor;
      case 'clinic':
        return LoginRole.clinic;
      case 'admin':
        return LoginRole.clinic;
      default:
        return null;
    }
  }

  Future<void> _login() async {
    if (_isLoading) {
      return;
    }

    final form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    bool loginCompleted = false;

    try {
      final authResponse = await Supabase.instance.client.auth
          .signInWithPassword(
        email: email,
        password: password,
      );

      final user = authResponse.user;

      if (user == null) {
        throw const AuthException(
          'Login succeeded, but no authenticated user was returned.',
        );
      }

      if (!mounted) {
        return;
      }

      final profile = await Supabase.instance.client
          .from('profiles')
          .select('id, full_name, role, clinic_name')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) {
        return;
      }

      if (profile == null) {
        await Supabase.instance.client.auth.signOut();

        _showError(
          'Your account profile was not found. Please contact the clinic administrator.',
        );

        return;
      }

      final databaseRole = profile['role']?.toString().trim().toLowerCase();

      final actualRole = _databaseRoleToLoginRole(databaseRole);

      if (actualRole == null) {
        await Supabase.instance.client.auth.signOut();

        _showError(
          'This account has an invalid role. Please contact the administrator.',
        );

        return;
      }

      final selectedDatabaseRole =
          _roleToDatabaseValue(_selectedRole);

      final actualDatabaseRole =
          _roleToDatabaseValue(actualRole);

      if (selectedDatabaseRole != actualDatabaseRole) {
        await Supabase.instance.client.auth.signOut();

        final actualRoleName = actualRole == LoginRole.clinic
            ? 'Clinic'
            : actualRole == LoginRole.doctor
                ? 'Doctor'
                : 'Patient';

        _showError(
          'This account is registered as $actualRoleName, not $_roleTitle.',
        );

        return;
      }

      String destination;

      switch (actualRole) {
        case LoginRole.patient:
          destination = '/patient/dashboard';
          break;

        case LoginRole.doctor:
          destination = '/doctor/dashboard';
          break;

        case LoginRole.clinic:
          destination = '/admin/dashboard';
          break;
      }

      loginCompleted = true;

      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        destination,
        (route) => false,
      );
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }

      _showError(error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(
        'Unable to login right now. Please try again.',
      );
    } finally {
      if (mounted && !loginCompleted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  void _openForgotPassword() {
    Navigator.pushNamed(
      context,
      '/auth/forgot',
    );
  }

  void _openRegister() {
    Navigator.pushNamed(
      context,
      '/auth/register',
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1976D2);
    const Color primaryGreen = Color(0xFF26A69A);
    const Color background = Color(0xFFF7FAFC);
    const Color textPrimary = Color(0xFF172033);
    const Color textSecondary = Color(0xFF667085);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 460,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  primaryBlue,
                                  primaryGreen,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius:
                                  BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryBlue.withValues(
                                    alpha: 0.18,
                                  ),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: 42,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'CareFlow',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Connected care, better health.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: 0.06,
                            ),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Welcome back',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            _roleDescription,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: textSecondary,
                            ),
                          ),

                          const SizedBox(height: 24),

                          const Text(
                            'Login as',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: _RoleButton(
                                  title: 'Patient',
                                  icon: Icons.person_outline,
                                  selected:
                                      _selectedRole ==
                                          LoginRole.patient,
                                  onTap: () {
                                    if (_isLoading) {
                                      return;
                                    }

                                    setState(() {
                                      _selectedRole =
                                          LoginRole.patient;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _RoleButton(
                                  title: 'Doctor',
                                  icon:
                                      Icons.medical_services_outlined,
                                  selected:
                                      _selectedRole ==
                                          LoginRole.doctor,
                                  onTap: () {
                                    if (_isLoading) {
                                      return;
                                    }

                                    setState(() {
                                      _selectedRole =
                                          LoginRole.doctor;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _RoleButton(
                                  title: 'Clinic',
                                  icon:
                                      Icons.local_hospital_outlined,
                                  selected:
                                      _selectedRole ==
                                          LoginRole.clinic,
                                  onTap: () {
                                    if (_isLoading) {
                                      return;
                                    }

                                    setState(() {
                                      _selectedRole =
                                          LoginRole.clinic;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          const Text(
                            'Email',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),

                          const SizedBox(height: 8),

                          TextFormField(
                            controller: _emailController,
                            enabled: !_isLoading,
                            keyboardType:
                                TextInputType.emailAddress,
                            textInputAction:
                                TextInputAction.next,
                            autofillHints: const [
                              AutofillHints.email,
                            ],
                            decoration: _inputDecoration(
                              hintText: 'Enter your email',
                              prefixIcon:
                                  Icons.email_outlined,
                              primaryBlue: primaryBlue,
                            ),
                            validator: (value) {
                              final email =
                                  value?.trim() ?? '';

                              if (email.isEmpty) {
                                return 'Please enter your email';
                              }

                              final emailRegex = RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              );

                              if (!emailRegex.hasMatch(email)) {
                                return 'Please enter a valid email';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 18),

                          const Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),

                          const SizedBox(height: 8),

                          TextFormField(
                            controller: _passwordController,
                            enabled: !_isLoading,
                            obscureText: _obscurePassword,
                            textInputAction:
                                TextInputAction.done,
                            autofillHints: const [
                              AutofillHints.password,
                            ],
                            onFieldSubmitted: (_) {
                              if (!_isLoading) {
                                _login();
                              }
                            },
                            decoration: _inputDecoration(
                              hintText:
                                  'Enter your password',
                              prefixIcon:
                                  Icons.lock_outline,
                              primaryBlue: primaryBlue,
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Show password'
                                    : 'Hide password',
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons
                                          .visibility_outlined
                                      : Icons
                                          .visibility_off_outlined,
                                ),
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _obscurePassword =
                                              !_obscurePassword;
                                        });
                                      },
                              ),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty) {
                                return 'Please enter your password';
                              }

                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 8),

                          Align(
                            alignment:
                                Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : _openForgotPassword,
                              child: const Text(
                                'Forgot password?',
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed:
                                  _isLoading ? null : _login,
                              style:
                                  ElevatedButton.styleFrom(
                                backgroundColor:
                                    primaryBlue,
                                foregroundColor:
                                    Colors.white,
                                disabledBackgroundColor:
                                    primaryBlue.withValues(
                                  alpha: 0.5,
                                ),
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _loginButtonText,
                                      style:
                                          const TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                            FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              const Flexible(
                                child: Text(
                                  "Don't have an account? ",
                                  style: TextStyle(
                                    color: textSecondary,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : _openRegister,
                                child: const Text(
                                  'Create account',
                                  style: TextStyle(
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Your health information is protected and securely managed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    required Color primaryBlue,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(prefixIcon),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE4EAF0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: primaryBlue,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE53935),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE53935),
          width: 2,
        ),
      ),
      filled: true,
      fillColor: const Color(0xFFF9FBFD),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleButton({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1976D2);
    const Color primaryGreen = Color(0xFF26A69A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFEAF4FF)
              : const Color(0xFFF9FBFD),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? primaryBlue
                : const Color(0xFFE4EAF0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: selected
                  ? primaryBlue
                  : const Color(0xFF667085),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: selected
                      ? primaryBlue
                      : const Color(0xFF667085),
                ),
              ),
            ),
            if (selected) ...[
              const SizedBox(height: 4),
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
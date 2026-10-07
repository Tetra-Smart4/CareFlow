import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
  });

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {
  final GlobalKey<FormState> formKey =
      GlobalKey<FormState>();

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool loading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool acceptedTerms = false;

  static const Color primaryBlue =
      Color(0xFF1479D1);

  static const Color background =
      Color(0xFFF7FBFF);

  static const Color border =
      Color(0xFFD6E6F3);

  static const Color textDark =
      Color(0xFF12304A);

  static const Color textGrey =
      Color(0xFF6B7C8D);

  static const Color lightBlue =
      Color(0xFFEAF6FF);

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  // ============================================================
  // REGISTER
  // ============================================================

  Future<void> register() async {
    FocusScope.of(context).unfocus();

    if (!formKey.currentState!.validate()) {
      return;
    }

    if (!acceptedTerms) {
      _showMessage(
        'Please accept the terms and privacy policy.',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await AuthService().signUp(
        emailController.text.trim(),
        passwordController.text,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Account created successfully. Please sign in.',
      );

      Navigator.pushReplacementNamed(
        context,
        '/auth/patient-login',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _cleanErrorMessage(e),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  String _cleanErrorMessage(Object error) {
    return error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,

      labelStyle: const TextStyle(
        color: textGrey,
        fontSize: 14,
      ),

      prefixIcon: Icon(
        icon,
        color: primaryBlue,
      ),

      suffixIcon: suffixIcon,

      filled: true,
      fillColor: Colors.white,

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(13),
        borderSide:
            const BorderSide(
          color: border,
        ),
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(13),
        borderSide:
            const BorderSide(
          color: border,
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(13),
        borderSide:
            const BorderSide(
          color: primaryBlue,
          width: 1.5,
        ),
      ),

      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(13),
        borderSide:
            const BorderSide(
          color: Colors.redAccent,
        ),
      ),

      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(13),
        borderSide:
            const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: textDark,
        elevation: 0,

        title: const Text(
          'Create Account',
          style: TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),

        centerTitle: true,
      ),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 480,
            ),

            child: Form(
              key: formKey,

              child: ListView(
                padding:
                    const EdgeInsets.fromLTRB(
                  24,
                  25,
                  24,
                  30,
                ),

                children: [
                  // ------------------------------------------------
                  // ICON
                  // ------------------------------------------------

                  Center(
                    child: Container(
                      width: 76,
                      height: 76,

                      decoration:
                          BoxDecoration(
                        color: lightBlue,
                        borderRadius:
                            BorderRadius
                                .circular(
                          23,
                        ),
                      ),

                      child: const Icon(
                        Icons
                            .person_add_alt_1_rounded,
                        size: 38,
                        color:
                            primaryBlue,
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'Join CareFlow',
                    textAlign:
                        TextAlign.center,

                    style: TextStyle(
                      fontSize: 28,
                      fontWeight:
                          FontWeight.w800,
                      color: textDark,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Create your account and start managing your health journey.',
                    textAlign:
                        TextAlign.center,

                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: textGrey,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ------------------------------------------------
                  // FULL NAME
                  // ------------------------------------------------

                  TextFormField(
                    controller:
                        nameController,

                    textCapitalization:
                        TextCapitalization
                            .words,

                    keyboardType:
                        TextInputType
                            .name,

                    textInputAction:
                        TextInputAction
                            .next,

                    decoration:
                        inputDecoration(
                      label:
                          'Full Name',
                      icon: Icons
                          .person_outline_rounded,
                    ),

                    validator: (value) {
                      final String name =
                          value?.trim() ??
                              '';

                      if (name.isEmpty) {
                        return 'Please enter your full name.';
                      }

                      if (name.length < 3) {
                        return 'Name must contain at least 3 characters.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // ------------------------------------------------
                  // EMAIL
                  // ------------------------------------------------

                  TextFormField(
                    controller:
                        emailController,

                    keyboardType:
                        TextInputType
                            .emailAddress,

                    textInputAction:
                        TextInputAction
                            .next,

                    decoration:
                        inputDecoration(
                      label:
                          'Email Address',
                      icon: Icons
                          .email_outlined,
                    ),

                    validator: (value) {
                      final String email =
                          value?.trim() ??
                              '';

                      if (email.isEmpty) {
                        return 'Please enter your email.';
                      }

                      final bool valid =
                          RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch(email);

                      if (!valid) {
                        return 'Please enter a valid email.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // ------------------------------------------------
                  // PASSWORD
                  // ------------------------------------------------

                  TextFormField(
                    controller:
                        passwordController,

                    obscureText:
                        obscurePassword,

                    textInputAction:
                        TextInputAction
                            .next,

                    decoration:
                        inputDecoration(
                      label:
                          'Password',

                      icon: Icons
                          .lock_outline_rounded,

                      suffixIcon:
                          IconButton(
                        onPressed: () {
                          setState(() {
                            obscurePassword =
                                !obscurePassword;
                          });
                        },

                        icon: Icon(
                          obscurePassword
                              ? Icons
                                  .visibility_outlined
                              : Icons
                                  .visibility_off_outlined,
                          color:
                              textGrey,
                        ),
                      ),
                    ),

                    validator: (value) {
                      final String password =
                          value ?? '';

                      if (password.isEmpty) {
                        return 'Please enter a password.';
                      }

                      if (password.length < 6) {
                        return 'Password must contain at least 6 characters.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // ------------------------------------------------
                  // CONFIRM PASSWORD
                  // ------------------------------------------------

                  TextFormField(
                    controller:
                        confirmPasswordController,

                    obscureText:
                        obscureConfirmPassword,

                    textInputAction:
                        TextInputAction.done,

                    decoration:
                        inputDecoration(
                      label:
                          'Confirm Password',

                      icon: Icons
                          .lock_reset_outlined,

                      suffixIcon:
                          IconButton(
                        onPressed: () {
                          setState(() {
                            obscureConfirmPassword =
                                !obscureConfirmPassword;
                          });
                        },

                        icon: Icon(
                          obscureConfirmPassword
                              ? Icons
                                  .visibility_outlined
                              : Icons
                                  .visibility_off_outlined,
                          color:
                              textGrey,
                        ),
                      ),
                    ),

                    validator: (value) {
                      if (value == null ||
                          value.isEmpty) {
                        return 'Please confirm your password.';
                      }

                      if (value !=
                          passwordController
                              .text) {
                        return 'Passwords do not match.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  // ------------------------------------------------
                  // TERMS
                  // ------------------------------------------------

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Checkbox(
                        value:
                            acceptedTerms,

                        activeColor:
                            primaryBlue,

                        onChanged:
                            (value) {
                          setState(() {
                            acceptedTerms =
                                value ??
                                    false;
                          });
                        },
                      ),

                      const Expanded(
                        child: Padding(
                          padding:
                              EdgeInsets.only(
                            top: 11,
                          ),
                          child: Text(
                            'I agree to the CareFlow Terms of Service and Privacy Policy.',
                            style:
                                TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color:
                                  textGrey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ------------------------------------------------
                  // CREATE ACCOUNT
                  // ------------------------------------------------

                  SizedBox(
                    height: 54,

                    child:
                        ElevatedButton(
                      onPressed:
                          loading
                              ? null
                              : register,

                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            primaryBlue,
                        foregroundColor:
                            Colors.white,
                        elevation: 0,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            13,
                          ),
                        ),
                      ),

                      child: loading
                          ? const SizedBox(
                              width: 23,
                              height: 23,
                              child:
                                  CircularProgressIndicator(
                                color:
                                    Colors.white,
                                strokeWidth:
                                    2.5,
                              ),
                            )
                          : const Text(
                              'Create Account',
                              style:
                                  TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    FontWeight
                                        .w700,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ------------------------------------------------
                  // LOGIN
                  // ------------------------------------------------

                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          '/auth/patient-login',
                        );
                      },

                      child: RichText(
                        text:
                            const TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                textGrey,
                          ),

                          children: [
                            TextSpan(
                              text:
                                  'Already have an account? ',
                            ),
                            TextSpan(
                              text:
                                  'Sign In',
                              style:
                                  TextStyle(
                                color:
                                    primaryBlue,
                                fontWeight:
                                    FontWeight
                                        .w700,
                              ),
                            ),
                          ],
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
  }
}
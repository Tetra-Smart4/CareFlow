import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
  });

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final TextEditingController emailController =
      TextEditingController();

  bool loading = false;
  bool sent = false;

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
    emailController.dispose();
    super.dispose();
  }

  Future<void> sendResetLink() async {
    final String email =
        emailController.text.trim();

    if (email.isEmpty) {
      _showMessage(
        'Please enter your email address.',
      );
      return;
    }

    if (!email.contains('@')) {
      _showMessage(
        'Please enter a valid email address.',
      );
      return;
    }

    setState(() {
      loading = true;
      sent = false;
    });

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'careflow://reset-callback',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        sent = true;
      });

      _showMessage(
        'Password reset link sent successfully.',
      );
    } on AuthException catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        e.message,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to send reset link. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: textDark,
        elevation: 0,

        title: const Text(
          'Forgot Password',
          style: TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 480,
            ),

            child: ListView(
              padding:
                  const EdgeInsets.fromLTRB(
                24,
                35,
                24,
                30,
              ),

              children: [
                // ------------------------------------------------
                // ICON
                // ------------------------------------------------

                Center(
                  child: Container(
                    width: 82,
                    height: 82,

                    decoration:
                        BoxDecoration(
                      color: lightBlue,
                      borderRadius:
                          BorderRadius.circular(
                        25,
                      ),
                    ),

                    child: const Icon(
                      Icons
                          .lock_reset_rounded,
                      size: 44,
                      color: primaryBlue,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'Reset your password',
                  textAlign:
                      TextAlign.center,

                  style: TextStyle(
                    fontSize: 27,
                    fontWeight:
                        FontWeight.w800,
                    color: textDark,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Enter the email address associated with your CareFlow account. We will send you a secure password reset link.',
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
                // EMAIL
                // ------------------------------------------------

                TextField(
                  controller:
                      emailController,

                  keyboardType:
                      TextInputType
                          .emailAddress,

                  textInputAction:
                      TextInputAction.done,

                  onSubmitted: (_) {
                    if (!loading) {
                      sendResetLink();
                    }
                  },

                  decoration:
                      InputDecoration(
                    labelText:
                        'Email Address',

                    prefixIcon:
                        const Icon(
                      Icons
                          .email_outlined,
                      color:
                          primaryBlue,
                    ),

                    filled: true,
                    fillColor:
                        Colors.white,

                    contentPadding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),

                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        13,
                      ),
                      borderSide:
                          const BorderSide(
                        color: border,
                      ),
                    ),

                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        13,
                      ),
                      borderSide:
                          const BorderSide(
                        color: border,
                      ),
                    ),

                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        13,
                      ),
                      borderSide:
                          const BorderSide(
                        color:
                            primaryBlue,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // ------------------------------------------------
                // SEND BUTTON
                // ------------------------------------------------

                SizedBox(
                  height: 54,

                  child:
                      ElevatedButton(
                    onPressed:
                        loading
                            ? null
                            : sendResetLink,

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
                            'Send Reset Link',
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

                const SizedBox(height: 20),

                // ------------------------------------------------
                // SUCCESS MESSAGE
                // ------------------------------------------------

                if (sent)
                  Container(
                    padding:
                        const EdgeInsets.all(
                      15,
                    ),

                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFEAF8F0,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        13,
                      ),
                      border:
                          Border.all(
                        color:
                            const Color(
                          0xFFB9E3C8,
                        ),
                      ),
                    ),

                    child: const Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        Icon(
                          Icons
                              .check_circle_outline,
                          color:
                              Colors.green,
                          size: 20,
                        ),

                        SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            'Check your inbox for the password reset link.',
                            style:
                                TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color:
                                  Color(
                                0xFF23643A,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 25),

                // ------------------------------------------------
                // BACK TO LOGIN
                // ------------------------------------------------

                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                      );
                    },

                    child: const Text(
                      'Back to Sign In',
                      style: TextStyle(
                        color:
                            primaryBlue,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
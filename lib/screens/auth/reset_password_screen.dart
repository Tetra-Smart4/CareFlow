import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/color_tokens.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _success = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );

      // If user is a doctor activating their account, update status to active
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        try {
          final profileData = await Supabase.instance.client
              .from('profiles')
              .select('role, status')
              .eq('id', currentUser.id)
              .maybeSingle();

          if (profileData != null && profileData['role'] == 'doctor') {
            await Supabase.instance.client.rpc('careflow_activate_doctor_account', params: {
              'p_doctor_id': currentUser.id,
            });
          }
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() => _success = true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully. Account activated.'),
          backgroundColor: ColorTokens.careGreen,
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: ColorTokens.error),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update password. Please check your internet connection and try again.'),
          backgroundColor: ColorTokens.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_success) {
      return Scaffold(
        backgroundColor: ColorTokens.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, color: ColorTokens.careGreen, size: 80),
                  const SizedBox(height: 24),
                  const Text(
                    'Your password has been set up successfully.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ColorTokens.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your CareFlow account is now active and ready to use.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: ColorTokens.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () async {
                      final nav = Navigator.of(context);
                      try {
                        final authUser = Supabase.instance.client.auth.currentUser;
                        if (authUser != null) {
                          final prof = await Supabase.instance.client
                              .from('profiles')
                              .select('role')
                              .eq('id', authUser.id)
                              .maybeSingle();

                          if (prof != null && prof['role'] == 'doctor') {
                            nav.pushNamedAndRemoveUntil(
                              '/doctor/dashboard',
                              (route) => false,
                            );
                            return;
                          }
                        }
                      } catch (_) {}

                      nav.pushNamedAndRemoveUntil(
                        '/auth/login',
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorTokens.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Continue to Dashboard', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/auth/login',
                        (route) => false,
                      );
                    },
                    child: const Text('Back to Sign In'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Create New Password',
          style: TextStyle(fontWeight: FontWeight.w700, color: ColorTokens.darkNavy),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Create New Password',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: ColorTokens.darkNavy),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Please enter your new password below.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: ColorTokens.textSecondary),
                    ),
                    const SizedBox(height: 30),
                    
                    // New Password
                    const Text('New Password', style: TextStyle(fontWeight: FontWeight.w700, color: ColorTokens.darkNavy)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Enter new password',
                        prefixIcon: const Icon(Icons.lock_outline, color: ColorTokens.primaryBlue),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: ColorTokens.textMuted),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: ColorTokens.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: ColorTokens.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: ColorTokens.primaryBlue)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Password cannot be empty.';
                        if (value.length < 6) return 'Password must be at least 6 characters.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    
                    // Confirm Password
                    const Text('Confirm New Password', style: TextStyle(fontWeight: FontWeight.w700, color: ColorTokens.darkNavy)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        hintText: 'Confirm new password',
                        prefixIcon: const Icon(Icons.lock_outline, color: ColorTokens.primaryBlue),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: ColorTokens.textMuted),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: ColorTokens.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: ColorTokens.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: ColorTokens.primaryBlue)),
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) return 'Passwords do not match.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    
                    // Update Button
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updatePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorTokens.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 23, height: 23, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text('Update Password', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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
}

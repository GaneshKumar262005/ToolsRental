import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/app_theme.dart';
import '../widgets/gradient_button.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _authenticateAdmin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
    });

    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    // 1. Strict Validation: Non-Gmail Corporate Email Requirement
    if (email.toLowerCase().endsWith('@gmail.com') || email.toLowerCase().endsWith('@yahoo.com') || email.toLowerCase().endsWith('@hotmail.com')) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access Denied: Admin authentication requires an authorized corporate domain (e.g. admin.control@constructpro-secure.com). Public webmails are not permitted.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    // 2. Credentials Verification
    final bool isValidEmail = (email.toLowerCase() == 'admin.control@constructpro-secure.com' || email.toLowerCase() == 'admin@constructpro-secure.com');
    final bool isValidPassword = (password == 'BuildMaster@2026#' || password == 'admin.pass2026');

    if (!isValidEmail || !isValidPassword) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid Admin credentials. Please check corporate email and password.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 3. Save Authenticated Admin Session securely in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final String secureToken = 'secure_admin_token_${DateTime.now().millisecondsSinceEpoch}_hash_sha256';
    await prefs.setBool('admin_authenticated', true);
    await prefs.setString('role', 'admin');
    await prefs.setString('admin_email', email);
    await prefs.setString('token', secureToken);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin authentication successful! Accessing Secure Admin Portal...'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        title: const Text('Secure Admin Gateway'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shield Lock Header Icon
                    Center(
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: AppTheme.accentOrange,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentOrange.withOpacity(0.4),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          size: 44,
                          color: Colors.white,
                        ),
                      ).animate().scale().fadeIn(),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Admin Portal Authentication',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ).animate().fadeIn(delay: const Duration(milliseconds: 200)),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Restricted area for authorized ConstructPro System Administrators only',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.mediumGray,
                            ),
                      ).animate().fadeIn(delay: const Duration(milliseconds: 300)),
                    ),
                    const SizedBox(height: 32),

                    // Admin Login Card Container
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.accentOrange.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Corporate Admin Email',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: 'Enter corporate admin email',
                              hintStyle: TextStyle(color: AppTheme.mediumGray.withOpacity(0.6)),
                              prefixIcon: const Icon(Icons.shield_outlined, color: AppTheme.accentOrange),
                              fillColor: const Color(0xFF141414),
                              filled: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (val) {
                              if (val?.isEmpty ?? true) return 'Please enter corporate admin email';
                              if (val!.endsWith('@gmail.com')) return 'Gmail addresses not allowed for Admin Panel';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Secure Password',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: 'Enter BuildMaster password',
                              hintStyle: TextStyle(color: AppTheme.mediumGray.withOpacity(0.6)),
                              prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.accentOrange),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppTheme.accentOrange),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              fillColor: const Color(0xFF141414),
                              filled: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (val) {
                              if (val?.isEmpty ?? true) return 'Please enter admin password';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          GradientButton(
                            text: _isLoading ? 'Authenticating Admin...' : 'Authenticate & Access Portal',
                            onPressed: _isLoading ? null : _authenticateAdmin,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: const Duration(milliseconds: 400)),
                    const SizedBox(height: 40),
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

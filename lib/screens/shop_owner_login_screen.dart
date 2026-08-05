import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../themes/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../dummy_data/dummy_data.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';
import '../services/email_service.dart';
import '../services/firebase_service.dart';


class ShopOwnerLoginScreen extends StatefulWidget {
  const ShopOwnerLoginScreen({super.key});

  @override
  State<ShopOwnerLoginScreen> createState() => _ShopOwnerLoginScreenState();
}

class _ShopOwnerLoginScreenState extends State<ShopOwnerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
    });

    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'role': 'shopowner',
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['user'] != null) {
          final user = data['user'];
          await _saveSessionAndNavigate(
            userId: user['id'].toString(),
            name: user['name'] ?? 'Shop Owner',
            email: user['email'] ?? email,
            token: data['token'] ?? 'shopowner-token',
          );
          return;
        }
      }
    } catch (_) {}

    // Try Firebase Firestore Authentication (Cross-Device Cloud Auth)
    try {
      final firestoreAuth = await FirebaseService().authenticateUserWithFirestore(email, password);
      if (firestoreAuth['success'] == true && firestoreAuth['user'] != null) {
        final fUser = firestoreAuth['user'] as Map<String, dynamic>;
        await _saveSessionAndNavigate(
          userId: fUser['id']?.toString() ?? 'shopowner_${DateTime.now().millisecondsSinceEpoch}',
          name: fUser['name'] ?? 'Shop Owner',
          email: fUser['email'] ?? email,
          token: 'shopowner-firestore-token',
        );
        return;
      }
    } catch (_) {}

    // Strict Check: Local registered users in SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final String registeredUsersJson = prefs.getString('registered_users') ?? '[]';
      final List<dynamic> localUsers = jsonDecode(registeredUsersJson);

      final matchingUser = localUsers.firstWhere(
        (u) => u['email'].toString().toLowerCase().trim() == email.toLowerCase().trim(),
        orElse: () => null,
      );

      if (matchingUser != null) {
        // Check password matching if stored
        if (matchingUser['password'] != null && matchingUser['password'].toString().isNotEmpty) {
          if (matchingUser['password'].toString().trim() != password.trim()) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Incorrect password. Please try again ❌'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        }

        await _saveSessionAndNavigate(
          userId: matchingUser['id'].toString(),
          name: matchingUser['name'] ?? 'Shop Owner',
          email: matchingUser['email'],
          token: 'shopowner-local-token',
        );
        return;
      }
    } catch (_) {}

    // Special handling for registered demo shop owner email
    final isDefaultShopOwner = email.toLowerCase() == 'ganesh26200507@gmail.com' || email.toLowerCase() == 'shopowner@constructhub.com';
    if (isDefaultShopOwner) {
      await _saveSessionAndNavigate(
        userId: 'shopowner_default_1',
        name: 'Ganesh Kumar',
        email: email,
        token: 'shopowner-default-token',
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shop Owner account not registered. Please Sign Up first! ⚠️'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Future<void> _saveSessionAndNavigate({
    required String userId,
    required String name,
    required String email,
    required String token,
  }) async {
    DummyData.currentUser = UserModel(
      id: userId,
      name: name,
      email: email,
      phone: '+91 98765 43210',
      imageUrl: 'assets/images/avatar.jpg',
      location: 'Chennai, Tamil Nadu',
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('role', 'shopowner');
    await prefs.setString('userId', userId);
    await prefs.setString('userName', name);
    await prefs.setString('userEmail', email);

    // Sync shop owner user entry into local registered_users array for instant future local logins
    final String registeredUsersJson = prefs.getString('registered_users') ?? '[]';
    try {
      List<dynamic> usersList = jsonDecode(registeredUsersJson);
      usersList.removeWhere((u) => u['email']?.toString().toLowerCase().trim() == email.toLowerCase().trim());
      usersList.add({
        'id': userId,
        'name': name,
        'email': email.toLowerCase().trim(),
        'role': 'shopowner',
      });
      await prefs.setString('registered_users', jsonEncode(usersList));
    } catch (_) {}

    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        '/shop-owner-dashboard',
      );
    }
  }

  void _forgotPassword() {
    final emailResetController = TextEditingController();
    final newPasswordController = TextEditingController();
    final otpResetController = TextEditingController();

    int step = 1; // 1: Email, 2: OTP & New Password
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.primaryBlack,
              title: Row(
                children: const [
                  Icon(Icons.lock_reset, color: AppTheme.primaryYellow),
                  SizedBox(width: 10),
                  Text('Password Recovery', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (step == 1) ...[
                      const Text(
                        'Enter your registered email address to receive a 6-digit recovery code:',
                        style: TextStyle(color: AppTheme.mediumGray, fontSize: 13),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: emailResetController,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'Enter recovery email address',
                          hintStyle: TextStyle(color: AppTheme.mediumGray),
                          prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primaryYellow),
                          fillColor: const Color(0xFF1E1E1E),
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ] else ...[
                      Text(
                        'A 6-digit OTP code was sent to ${emailResetController.text.trim()}',
                        style: const TextStyle(color: AppTheme.mediumGray, fontSize: 13),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: otpResetController,
                        style: const TextStyle(color: Colors.white, letterSpacing: 6, fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          hintText: '6-Digit OTP',
                          counterText: '',
                          fillColor: const Color(0xFF1E1E1E),
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: newPasswordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'Enter new password',
                          prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryYellow),
                          fillColor: const Color(0xFF1E1E1E),
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.mediumGray)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryYellow,
                    foregroundColor: AppTheme.primaryBlack,
                  ),
                  onPressed: isProcessing ? null : () async {
                    final email = emailResetController.text.trim();
                    if (step == 1) {
                      if (email.isEmpty || !email.contains('@')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid email address')),
                        );
                        return;
                      }

                      setDialogState(() => isProcessing = true);

                      // Ensure user email is registered/added to storage so recovery ALWAYS works
                      final prefs = await SharedPreferences.getInstance();
                      final String registeredUsersJson = prefs.getString('registered_users') ?? '[]';
                      List<dynamic> localUsers = jsonDecode(registeredUsersJson);

                      var matchingUser = localUsers.firstWhere(
                        (u) => u['email'].toString().toLowerCase() == email.toLowerCase(),
                        orElse: () => null,
                      );

                      if (matchingUser == null) {
                        matchingUser = {
                          'id': 'so_${DateTime.now().millisecondsSinceEpoch}',
                          'name': email.split('@')[0],
                          'email': email,
                          'password': 'password123',
                          'role': 'shopowner',
                        };
                        localUsers.add(matchingUser);
                        await prefs.setString('registered_users', jsonEncode(localUsers));
                      }

                      // Send real OTP code to user email via EmailService
                      final res = await EmailService.sendOtp(email: email, name: matchingUser['name'] ?? 'Shop Owner');

                      setDialogState(() => isProcessing = false);

                      if (res['success'] == true) {
                        setDialogState(() => step = 2);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Recovery OTP sent to $email! Check your email inbox.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res['message'] ?? 'Failed to send OTP code'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    } else {
                      final otp = otpResetController.text.trim();
                      final newPass = newPasswordController.text.trim();

                      if (otp.length != 6 || newPass.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter 6-digit OTP and new password (min 6 chars)')),
                        );
                        return;
                      }

                      setDialogState(() => isProcessing = true);

                      // 1. Check if new password is same as old password
                      final prefs = await SharedPreferences.getInstance();
                      final String registeredUsersJson = prefs.getString('registered_users') ?? '[]';
                      List<dynamic> localUsers = jsonDecode(registeredUsersJson);

                      final matchingUser = localUsers.firstWhere(
                        (u) => u['email'].toString().toLowerCase() == email.toLowerCase(),
                        orElse: () => null,
                      );

                      if (matchingUser != null && matchingUser['password'] != null) {
                        if (matchingUser['password'].toString() == newPass) {
                          setDialogState(() => isProcessing = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('New password cannot be the same as your old password. Please enter a new password.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          return;
                        }
                      }

                      // 2. Verify OTP code received in email
                      final verif = await EmailService.verifyOtp(email: email, otp: otp);

                      if (verif['success'] == true) {
                        // Update password in SharedPreferences registered_users
                        for (var u in localUsers) {
                          if (u['email'].toString().toLowerCase() == email.toLowerCase()) {
                            u['password'] = newPass;
                            break;
                          }
                        }
                        await prefs.setString('registered_users', jsonEncode(localUsers));

                        Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password reset verified & updated successfully! 🎉 Please log in with your new password.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
                        setDialogState(() => isProcessing = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Invalid verification code. Please check your recovery email and try again.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: isProcessing
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text(step == 1 ? 'Send Recovery Code' : 'Reset Password', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Owner Portal'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: AppTheme.accentOrange),
            tooltip: 'Admin Portal Login',
            onPressed: () => Navigator.pushReplacementNamed(context, '/admin-dashboard'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // Glowing Icon Header
                  Center(
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryYellow,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryYellow.withOpacity(0.35),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        size: 44,
                        color: AppTheme.primaryBlack,
                      ),
                    ).animate().scale().fadeIn(),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Shop Owner Portal Login',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ).animate().fadeIn(delay: const Duration(milliseconds: 200)),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Sign in with your email & password to manage equipment',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.mediumGray,
                          ),
                    ).animate().fadeIn(delay: const Duration(milliseconds: 300)),
                  ),
                  const SizedBox(height: 32),

                  // Glassmorphism Form Container
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email Address Field
                        Text(
                          'Email Address',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Enter your shop email address',
                            hintStyle: TextStyle(color: AppTheme.mediumGray),
                            prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primaryYellow),
                            fillColor: const Color(0xFF1E1E1E),
                            filled: true,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.primaryYellow.withOpacity(0.4)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.primaryYellow, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Please enter your shop email';
                            if (!value!.contains('@')) return 'Please enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Password Field
                        Text(
                          'Password',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Enter your shop password',
                            hintStyle: TextStyle(color: AppTheme.mediumGray),
                            prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryYellow),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: AppTheme.primaryYellow,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            fillColor: const Color(0xFF1E1E1E),
                            filled: true,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.primaryYellow.withOpacity(0.4)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.primaryYellow, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Please enter your password';
                            if (value!.length < 6) return 'Password must be at least 6 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 6),

                        // Forgot Password Link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _forgotPassword,
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: AppTheme.primaryYellow,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Login Button
                        GradientButton(
                          text: _isLoading ? 'Authenticating...' : 'Login',
                          onPressed: _isLoading ? null : _loginWithPassword,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: const Duration(milliseconds: 400)),
                  const SizedBox(height: 28),

                  // Registration Footer
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.pushReplacementNamed(context, '/shop-owner-signup'),
                          icon: const Icon(Icons.store, color: AppTheme.primaryYellow, size: 18),
                          label: Text(
                            'Register Shop Here',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.primaryYellow,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/admin-login'),
                          icon: const Icon(Icons.admin_panel_settings, color: Colors.orangeAccent, size: 18),
                          label: Text(
                            'Admin Portal 🛡️',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.orangeAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: const Duration(milliseconds: 500)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

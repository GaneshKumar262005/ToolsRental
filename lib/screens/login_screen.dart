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


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  final List<Map<String, String>> _blogReviews = [
    {
      'title': 'Scaffolding Rental Saved Our Project Timeline',
      'category': 'Construction Review',
      'author': 'Rajesh Kumar (Site Engineer)',
      'rating': '5.0',
      'content': 'Renting industrial scaffolding from ConstructHub was seamless. Quality heavy steel equipment delivered within 2 hours to our Velachery construction site.',
    },
    {
      'title': 'Top 5 Power Drills for Heavy Commercial Duty',
      'category': 'Equipment Guide',
      'author': 'ConstructHub Tech Team',
      'rating': '4.9',
      'content': 'Discover why Bosch Rotary Hammer Drills and DeWalt Cutters remain the highest rated rental tools in Chennai with maximum torque & safety features.',
    },
    {
      'title': 'Verified Shop Vendors Offer Fast Delivery',
      'category': 'Vendor Partner Review',
      'author': 'Priya Sundaram',
      'rating': '5.0',
      'content': 'BuildRight Hardware provided verified equipment with complete safety compliance certificates. Highly recommended for all contractors!',
    },
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
    });

    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    // 1. Protected System Admin Credentials
    final isCorporateAdminEmail = email.toLowerCase() == 'admin.control@constructpro-secure.com' ||
        email.toLowerCase() == 'admin@constructpro-secure.com' ||
        email.toLowerCase() == 'admin@constructhub.com' ||
        email.toLowerCase() == 'admin.master@constructhub.com';
    final isCorporateAdminPass = password == 'BuildMaster@2026#' || password == 'AdminSecurePass#2026' || password == 'admin.pass2026';

    if (isCorporateAdminEmail && isCorporateAdminPass) {
      await _saveUserSessionAndNavigate(
        email: email,
        name: 'System Admin',
        role: 'admin',
        isAdmin: true,
      );
      return;
    }


    // 2. Try Backend API Authentication
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['user'] != null) {
          final user = data['user'];
          final String role = user['role'] ?? 'user';

          await _saveUserSessionAndNavigate(
            email: user['email'],
            name: user['name'] ?? 'User',
            role: role,
            userId: user['id'].toString(),
            token: data['token'],
            isAdmin: role == 'admin',
            isShopOwner: role == 'shopowner',
          );
          return;
        }
      }
    } catch (_) {}

    // 3. Try Firebase Firestore Authentication
    try {
      final firestoreAuth = await FirebaseService().authenticateUserWithFirestore(email, password);
      if (firestoreAuth['success'] == true && firestoreAuth['user'] != null) {
        final fUser = firestoreAuth['user'] as Map<String, dynamic>;
        final String role = fUser['role'] ?? 'user';
        await _saveUserSessionAndNavigate(
          email: fUser['email'] ?? email,
          name: fUser['name'] ?? 'User',
          role: role,
          userId: fUser['id']?.toString() ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
          isAdmin: role == 'admin',
          isShopOwner: role == 'shopowner',
        );
        return;
      }
    } catch (_) {}

    // 4. Strict Check: Local registered users in SharedPreferences


    try {
      final prefs = await SharedPreferences.getInstance();
      final String registeredUsersJson = prefs.getString('registered_users') ?? '[]';
      final List<dynamic> localUsers = jsonDecode(registeredUsersJson);

      final matchingUser = localUsers.firstWhere(
        (u) => u['email'].toString().toLowerCase() == email.toLowerCase(),
        orElse: () => null,
      );

      if (matchingUser == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account not registered. Please Sign Up first! ⚠️'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Validate password if stored
      if (matchingUser['password'] != null && matchingUser['password'].toString().isNotEmpty) {
        if (matchingUser['password'] != password) {
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

      final String userRole = matchingUser['role'] ?? 'user';
      await _saveUserSessionAndNavigate(
        email: matchingUser['email'],
        name: matchingUser['name'] ?? 'User',
        role: userRole,
        userId: matchingUser['id'].toString(),
        isAdmin: userRole == 'admin',
        isShopOwner: userRole == 'shopowner',
      );
      return;
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account not registered. Please Sign Up first! ⚠️'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Future<void> _saveUserSessionAndNavigate({
    required String email,
    required String name,
    required String role,
    String? userId,
    String? token,
    bool isAdmin = false,
    bool isShopOwner = false,
  }) async {
    final uid = userId ?? 'u_${DateTime.now().millisecondsSinceEpoch}';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token ?? 'user-token');
    await prefs.setString('role', role);
    await prefs.setString('userId', uid);
    await prefs.setString('userName', name);
    await prefs.setString('userEmail', email);

    DummyData.currentUser = UserModel(
      id: uid,
      name: name,
      email: email,
      phone: '+91 98765 43210',
      imageUrl: 'assets/images/avatar.jpg',
      location: 'Chennai, Tamil Nadu',
    );

    if (mounted) {
      if (isAdmin) {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else if (isShopOwner || role == 'shopowner') {
        Navigator.pushReplacementNamed(context, '/shop-owner-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/home', arguments: {'userName': name});
      }
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
                  Text('Password Recovery', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (step == 1) ...[
                      const Text(
                        'Enter your email address to receive a 6-digit recovery OTP code:',
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

                      // Ensure user email exists in storage so recovery ALWAYS works for ganesh26200507@gmail.com
                      final prefs = await SharedPreferences.getInstance();
                      final String registeredUsersJson = prefs.getString('registered_users') ?? '[]';
                      List<dynamic> localUsers = jsonDecode(registeredUsersJson);

                      var matchingUser = localUsers.firstWhere(
                        (u) => u['email'].toString().toLowerCase() == email.toLowerCase(),
                        orElse: () => null,
                      );

                      if (matchingUser == null) {
                        matchingUser = {
                          'id': 'u_${DateTime.now().millisecondsSinceEpoch}',
                          'name': email.split('@')[0],
                          'email': email,
                          'password': 'password123',
                          'role': 'user',
                        };
                        localUsers.add(matchingUser);
                        await prefs.setString('registered_users', jsonEncode(localUsers));
                      }

                      // Send real OTP code to user email via EmailService
                      final res = await EmailService.sendOtp(email: email, name: matchingUser['name'] ?? 'User');

                      setDialogState(() => isProcessing = false);

                      if (res['success'] == true) {
                        setDialogState(() => step = 2);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Recovery OTP sent to $email! Please check your inbox.'),
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

  void _showArticleDialog(String title, String category, String author, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryYellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.star, color: AppTheme.primaryYellow),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('⭐⭐⭐⭐⭐ 5.0 Rating', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryYellow)),
                  const SizedBox(width: 8),
                  Text('• $category', style: TextStyle(color: AppTheme.mediumGray, fontSize: 11)),
                ],
              ),
              const Divider(height: 20, color: Colors.white12),
              Text(content, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.white70)),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryYellow, foregroundColor: AppTheme.primaryBlack),
            child: const Text('Close Story', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ConstructHub'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                  // Logo Header
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryYellow,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryYellow.withOpacity(0.35),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.construction,
                        size: 38,
                        color: AppTheme.primaryBlack,
                      ),
                    ).animate().scale().fadeIn(),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Welcome Back!',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ).animate().fadeIn(delay: const Duration(milliseconds: 200)),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Login to continue renting tools',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.mediumGray,
                          ),
                    ).animate().fadeIn(delay: const Duration(milliseconds: 300)),
                  ),
                  const SizedBox(height: 32),

                  // Email Address Field
                  Text(
                    'Email Address',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: 'Enter your email address',
                      prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryYellow),
                      fillColor: Color(0xFF1E1E1E),
                      filled: true,
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Please enter your email';
                      if (!value!.contains('@')) return 'Please enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  Text(
                    'Password',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryYellow),
                      fillColor: const Color(0xFF1E1E1E),
                      filled: true,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppTheme.primaryYellow),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Please enter your password';
                      if (value!.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Remember Me & Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (val) => setState(() => _rememberMe = val ?? false),
                            activeColor: AppTheme.primaryYellow,
                          ),
                          Text('Remember me', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
                        ],
                      ),
                      TextButton(
                        onPressed: _forgotPassword,
                        child: Text(
                          'Forgot Password?',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryYellow,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  GradientButton(
                    text: _isLoading ? 'Authenticating...' : 'Login',
                    onPressed: _isLoading ? null : _login,
                  ),
                  const SizedBox(height: 24),

                  // Register Links
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.mediumGray,
                              ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/signup'),
                          child: Text(
                            'Register as Customer',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.primaryYellow,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/shop-owner-login'),
                          icon: const Icon(Icons.storefront, color: AppTheme.primaryYellow, size: 18),
                          label: Text(
                            'Shop Owner Login Portal →',
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
                  ),

                  const SizedBox(height: 24),

                  // Aesthetic Blog & Customer Reviews Cards
                  Text(
                    'Featured Stories & Customer Reviews',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _blogReviews.length,
                      itemBuilder: (context, index) {
                        final item = _blogReviews[index];
                        return GestureDetector(
                          onTap: () => _showArticleDialog(
                            item['title']!,
                            item['category']!,
                            item['author']!,
                            item['content']!,
                          ),
                          child: Container(
                            width: 250,
                            margin: const EdgeInsets.only(right: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(20),
                                topRight: const Radius.circular(8),
                                bottomLeft: const Radius.circular(8),
                                bottomRight: const Radius.circular(20),
                              ),
                              border: Border.all(color: AppTheme.primaryYellow.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text('⭐⭐⭐⭐⭐', style: TextStyle(fontSize: 10)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        item['category']!,
                                        style: const TextStyle(color: AppTheme.primaryYellow, fontSize: 10, fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item['title']!,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                Text(
                                  item['author']!,
                                  style: TextStyle(color: AppTheme.mediumGray, fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
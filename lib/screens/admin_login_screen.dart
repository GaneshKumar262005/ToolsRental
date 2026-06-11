import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import '../themes/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../dummy_data/dummy_data.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'admin@constructhub.com');
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final String email = _emailController.text.trim();
        final String password = _passwordController.text.trim();

        // The admin login uses the same endpoint but checks for admin credentials
        final response = await http.post(
          Uri.parse(ApiConfig.loginUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': 'Admin', // Placeholder for admin
            'email': email,
            'password': password,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] && data['isAdmin'] == true) {
            // Update DummyData.currentUser with backend response
            final userData = data['user'];
            DummyData.currentUser = UserModel(
              id: userData['id'].toString(),
              name: userData['name'],
              email: userData['email'],
              phone: userData['phone'] ?? '+91 98765 43210',
              imageUrl: 'assets/images/download.jpg',
              location: userData['location'] ?? 'Chennai, Tamil Nadu',
            );

            // Navigate to admin dashboard
            if (mounted) {
              Navigator.pushReplacementNamed(
                context,
                '/admin-dashboard',
              );
            }
          } else {
            // Not an admin or login failed
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(data['message'] ?? 'Admin access denied'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid admin credentials'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${error.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryYellow,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryYellow.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      size: 60,
                      color: AppTheme.primaryBlack,
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                  
                  const SizedBox(height: 32),
                  
                  Text(
                    'Admin Portal',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.primaryWhite,
                          fontWeight: FontWeight.bold,
                        ),
                  ).animate().fadeIn(delay: 200.ms),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Secure login for administrators',
                    style: TextStyle(color: Colors.white.withOpacity(0.6)),
                  ).animate().fadeIn(delay: 300.ms),
                  
                  const SizedBox(height: 48),
                  
                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Admin Email',
                      labelStyle: const TextStyle(color: AppTheme.primaryYellow),
                      prefixIcon: const Icon(Icons.email, color: AppTheme.primaryYellow),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppTheme.primaryYellow),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) => value!.isEmpty ? 'Enter email' : null,
                  ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),
                  
                  const SizedBox(height: 20),
                  
                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Secret Password',
                      labelStyle: const TextStyle(color: AppTheme.primaryYellow),
                      prefixIcon: const Icon(Icons.lock, color: AppTheme.primaryYellow),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppTheme.primaryYellow,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppTheme.primaryYellow),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) => value!.isEmpty ? 'Enter password' : null,
                  ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1),
                  
                  const SizedBox(height: 40),
                  
                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      text: _isLoading ? 'Authenticating...' : 'Access Dashboard',
                      onPressed: _isLoading ? null : _login,
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
                  
                  const SizedBox(height: 24),
                  
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Back to User Login',
                      style: TextStyle(color: Colors.white70),
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

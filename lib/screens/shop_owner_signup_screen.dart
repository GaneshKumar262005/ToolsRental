import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import '../themes/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../config/api_config.dart';
import '../dummy_data/dummy_data.dart';
import '../models/user_model.dart';

class ShopOwnerSignupScreen extends StatefulWidget {
  const ShopOwnerSignupScreen({super.key});

  @override
  State<ShopOwnerSignupScreen> createState() => _ShopOwnerSignupScreenState();
}

class _ShopOwnerSignupScreenState extends State<ShopOwnerSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please agree to the terms and conditions')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final String name = _nameController.text.trim();
        final String email = _emailController.text.trim();
        final String phone = _phoneController.text.trim();
        final String location = _locationController.text.trim();
        final String password = _passwordController.text.trim();

        final response = await http.post(
          Uri.parse(ApiConfig.loginUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'email': email,
            'phone': phone,
            'location': location,
            'password': password,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success']) {
            // Update DummyData.currentUser with backend response
            final userData = data['user'];
            DummyData.currentUser = UserModel(
              id: userData['id'].toString(),
              name: userData['name'],
              email: userData['email'],
              phone: userData['phone'] ?? phone,
              imageUrl: 'assets/images/download.jpg',
              location: userData['location'] ?? location,
            );

            // Sign up successful - route to shop owner dashboard
            Navigator.pushReplacementNamed(
              context,
              '/shop-owner-dashboard',
            );
          } else {
            // Sign up failed
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Sign up failed'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Server error. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Back button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(height: 10),
                  // Title
                  Text(
                    'Shop Owner Registration',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ).animate().fadeIn(),
                  const SizedBox(height: 8),
                  Text(
                    'Register as a shop owner to manage tool rentals',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.mediumGray,
                        ),
                  ).animate().fadeIn(delay: const Duration(milliseconds: 100)),
                  const SizedBox(height: 24),
                  // Name field
                  Text(
                    'Full Name',
                    style: Theme.of(context).textTheme.titleSmall,
                  ).animate().fadeIn(delay: const Duration(milliseconds: 200)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your full name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: const Duration(milliseconds: 200)),
                  const SizedBox(height: 20),
                  // Email field
                  Text(
                    'Email',
                    style: Theme.of(context).textTheme.titleSmall,
                  ).animate().fadeIn(delay: const Duration(milliseconds: 300)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Enter your email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter your email';
                      }
                      if (!value!.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: const Duration(milliseconds: 300)),
                  const SizedBox(height: 20),
                  // Phone field
                  Text(
                    'Phone Number',
                    style: Theme.of(context).textTheme.titleSmall,
                  ).animate().fadeIn(delay: const Duration(milliseconds: 400)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Enter your phone number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter your phone number';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: const Duration(milliseconds: 400)),
                  const SizedBox(height: 20),
                  // Location field
                  Text(
                    'Location',
                    style: Theme.of(context).textTheme.titleSmall,
                  ).animate().fadeIn(delay: const Duration(milliseconds: 450)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your location',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter your location';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: const Duration(milliseconds: 450)),
                  const SizedBox(height: 20),
                  // Password field
                  Text(
                    'Password',
                    style: Theme.of(context).textTheme.titleSmall,
                  ).animate().fadeIn(delay: const Duration(milliseconds: 500)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Create a password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter a password';
                      }
                      if (value!.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: const Duration(milliseconds: 500)),
                  const SizedBox(height: 20),
                  // Confirm password field
                  Text(
                    'Confirm Password',
                    style: Theme.of(context).textTheme.titleSmall,
                  ).animate().fadeIn(delay: const Duration(milliseconds: 600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      hintText: 'Confirm your password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: const Duration(milliseconds: 600)),
                  const SizedBox(height: 24),
                  // Terms checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _agreeToTerms,
                        onChanged: (value) {
                          setState(() {
                            _agreeToTerms = value ?? false;
                          });
                        },
                        activeColor: AppTheme.primaryYellow,
                      ),
                      Expanded(
                        child: Text(
                          'I agree to the terms and conditions',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: const Duration(milliseconds: 700)),
                  const SizedBox(height: 32),
                  // Sign up button
                  GradientButton(
                    text: _isLoading ? 'Creating Account...' : 'Register as Shop Owner',
                    onPressed: _isLoading ? null : _signup,
                  ).animate().fadeIn(delay: const Duration(milliseconds: 800)),
                  const SizedBox(height: 24),
                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Login',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryYellow,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: const Duration(milliseconds: 900)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

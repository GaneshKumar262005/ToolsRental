import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import '../themes/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../dummy_data/dummy_data.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
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
        final String name = _nameController.text.trim();
        final String email = _emailController.text.trim();
        final String password = _passwordController.text.trim();

        final response = await http.post(
          Uri.parse(ApiConfig.loginUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'email': email,
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
              phone: userData['phone'] ?? '+91 98765 43210',
              imageUrl: 'assets/images/download.jpg',
              location: userData['location'] ?? 'Chennai, Tamil Nadu',
            );

            // Check if admin login
            if (data['isAdmin'] == true) {
              Navigator.pushReplacementNamed(
                context,
                '/admin-dashboard',
              );
            } else if (data['isShopOwner'] == true) {
              // Shop owner login
              Navigator.pushReplacementNamed(
                context,
                '/shop-owner-dashboard',
              );
            } else {
              // Login successful
              Navigator.pushReplacementNamed(
                context,
                '/home',
                arguments: {'userName': userData['name']},
              );
            }
          } else {
            // Login failed
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Login failed'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else if (response.statusCode == 401) {
          final data = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Invalid credentials'),
              backgroundColor: Colors.red,
            ),
          );
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

  void _navigateToSignup() {
    Navigator.pushNamed(context, '/signup');
  }

  void _forgotPassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: const Text('Password reset link will be sent to your email.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _googleSignIn() async {
    // Show email input dialog for Google sign-in
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter your Gmail'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Gmail address',
              prefixIcon: Icon(Icons.email),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your Gmail';
              }
              if (!value.contains('@gmail.com')) {
                return 'Please enter a valid Gmail address';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, emailController.text.trim());
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (result != null) {
      // Check if email exists in backend
      try {
        final response = await http.get(
          Uri.parse('${ApiConfig.usersUrl}?email=${result.toLowerCase()}'),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] && data['users'] != null && data['users'].length > 0) {
            // Email exists, proceed with login
            final user = data['users'][0];
            DummyData.currentUser = UserModel(
              id: user['id'].toString(),
              name: user['name'],
              email: user['email'],
              phone: '+91 98765 43210',
              imageUrl: 'assets/images/download.jpg',
              location: 'Chennai, Tamil Nadu',
            );

            Navigator.pushReplacementNamed(
              context,
              '/home',
              arguments: {'userName': user['name']},
            );
          } else {
            // Email not registered
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This Gmail is not registered. Please register first.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
                  // Logo
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryYellow,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryYellow.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.construction,
                        size: 40,
                        color: AppTheme.primaryBlack,
                      ),
                    ).animate().scale().fadeIn(),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Center(
                    child: Text(
                      'Welcome Back!',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ).animate().fadeIn(delay: const Duration(milliseconds: 200)),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Login to continue renting tools',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.mediumGray,
                          ),
                    ).animate().fadeIn(delay: const Duration(milliseconds: 300)),
                  ),
                  const SizedBox(height: 32),

                  // ✅ Name field
                  Text(
                    'Full Name',
                    style: Theme.of(context).textTheme.titleSmall,
                  ).animate().fadeIn(delay: const Duration(milliseconds: 350)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Enter your full name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: const Duration(milliseconds: 350)),
                  const SizedBox(height: 20),

                  // Email field
                  Text(
                    'Email',
                    style: Theme.of(context).textTheme.titleSmall,
                  ).animate().fadeIn(delay: const Duration(milliseconds: 400)),
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
                  ).animate().fadeIn(delay: const Duration(milliseconds: 400)),
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
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
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
                        return 'Please enter your password';
                      }
                      if (value!.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: const Duration(milliseconds: 500)),
                  const SizedBox(height: 12),

                  // Remember me and forgot password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                            activeColor: AppTheme.primaryYellow,
                          ),
                          Text(
                            'Remember me',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _forgotPassword,
                        child: Text(
                          'Forgot Password?',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryYellow,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: const Duration(milliseconds: 600)),
                  const SizedBox(height: 32),

                  // Login button
                  GradientButton(
                    text: _isLoading ? 'Logging in...' : 'Login',
                    onPressed: _isLoading ? null : _login,
                  ).animate().fadeIn(delay: const Duration(milliseconds: 700)),
                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: AppTheme.mediumGray.withOpacity(0.3)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Or continue with',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.mediumGray,
                              ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: AppTheme.mediumGray.withOpacity(0.3)),
                      ),
                    ],
                  ).animate().fadeIn(delay: const Duration(milliseconds: 800)),
                  const SizedBox(height: 24),

                  // Google sign-in button
                  OutlinedButton.icon(
                    onPressed: () => _googleSignIn(),
                    icon: const Icon(Icons.g_mobiledata, size: 24),
                    label: const Text('Sign in with Google'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: AppTheme.mediumGray),
                    ),
                  ).animate().fadeIn(delay: const Duration(milliseconds: 900)),
                  const SizedBox(height: 32),

                  // Sign up link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: _navigateToSignup,
                          child: Text(
                            'Sign Up',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.primaryYellow,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: const Duration(milliseconds: 1000)),
                  const SizedBox(height: 16),
                  // Shop owner registration link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Are you a shop owner? ",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/shop-owner-signup'),
                          child: Text(
                            'Register as Shop Owner',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.primaryYellow,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: const Duration(milliseconds: 1100)),
                  const SizedBox(height: 12),
                  // Admin login link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Are you an administrator? ",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/admin-login'),
                          child: Text(
                            'Admin Login',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.primaryYellow,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: const Duration(milliseconds: 1200)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
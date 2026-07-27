import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../dummy_data/dummy_data.dart';
import '../themes/app_theme.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  File? _pickedImage;
  Uint8List? _pickedBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSavedProfileImage();
  }

  void _loadUserData() {
    final user = DummyData.currentUser;
    _nameController.text = user.name;
    _emailController.text = user.email;
    _phoneController.text = user.phone;
    _locationController.text = user.location;
  }

  Future<void> _loadSavedProfileImage() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Try loading base64 image (universal cross-platform support)
    final base64Str = prefs.getString('profileImageBase64');
    if (base64Str != null && base64Str.isNotEmpty) {
      try {
        final bytes = base64Decode(base64Str);
        if (mounted) {
          setState(() {
            _pickedBytes = bytes;
            DummyData.currentUser = UserModel(
              id: DummyData.currentUser.id,
              name: DummyData.currentUser.name,
              email: DummyData.currentUser.email,
              phone: DummyData.currentUser.phone,
              location: DummyData.currentUser.location,
              imageUrl: 'data:image/jpeg;base64,$base64Str',
            );
          });
        }
        return;
      } catch (_) {}
    }

    // 2. Try loading local file path (Desktop / Mobile)
    final savedPath = prefs.getString('profileImagePath');
    if (savedPath != null && savedPath.isNotEmpty) {
      if (!kIsWeb) {
        final file = File(savedPath);
        if (await file.exists()) {
          if (mounted) {
            setState(() {
              _pickedImage = file;
              DummyData.currentUser = UserModel(
                id: DummyData.currentUser.id,
                name: DummyData.currentUser.name,
                email: DummyData.currentUser.email,
                phone: DummyData.currentUser.phone,
                location: DummyData.currentUser.location,
                imageUrl: savedPath,
              );
            });
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = DummyData.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettingsDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.cardDecoration(),
              child: Column(
                children: [
                  // Avatar with change option
                  GestureDetector(
                    onTap: _showImagePickerOptions,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          key: ValueKey(_pickedImage?.path ?? user.imageUrl),
                          radius: 50,
                          backgroundColor: AppTheme.lightGray,
                          backgroundImage: _getProfileImageProvider(user.imageUrl),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryYellow,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primaryWhite,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: AppTheme.primaryBlack,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.mediumGray,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, size: 16, color: AppTheme.mediumGray),
                      const SizedBox(width: 4),
                      Text(
                        user.location,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.mediumGray,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ✅ Account Settings — fully filled
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Account Settings',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: AppTheme.cardDecoration(),
              child: Column(
                children: [
                  _buildMenuOption(
                    'Edit Profile',
                    Icons.edit_outlined,
                    () => _showEditProfileDialog(),
                  ),
                  const Divider(height: 1),
                  _buildMenuOption(
                    'Change Password',
                    Icons.lock_outline,
                    () => _showChangePasswordDialog(),
                  ),
                  const Divider(height: 1),
                  _buildMenuOption(
                    'Payment Methods',
                    Icons.payment_outlined,
                    () => _showPaymentMethodsDialog(),
                  ),
                  const Divider(height: 1),
                  _buildMenuOption(
                    'Payment History',
                    Icons.history_outlined,
                    () => Navigator.pushNamed(context, '/payment-history'),
                  ),
                  const Divider(height: 1),
                  _buildMenuOption(
                    'Notifications',
                    Icons.notifications_outlined,
                    () => Navigator.pushNamed(context, '/notifications'),
                  ),
                  const Divider(height: 1),
                  _buildMenuOption(
                    'Privacy Policy',
                    Icons.privacy_tip_outlined,
                    () => _showInfoDialog('Privacy Policy',
                        'We respect your privacy. Your personal data is encrypted and never shared with third parties without your consent.'),
                  ),
                  const Divider(height: 1),
                  _buildMenuOption(
                    'Terms & Conditions',
                    Icons.description_outlined,
                    () => _showInfoDialog('Terms & Conditions',
                        'By using ConstructHub, you agree to our rental terms. Tools must be returned in good condition. Late returns are charged at the daily rate.'),
                  ),
                  const Divider(height: 1),
                  _buildMenuOption(
                    'Help & Support',
                    Icons.help_outline,
                    () => _showHelpDialog(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // App info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration(),
              child: Column(
                children: [
                  Text(
                    'ConstructHub',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mediumGray,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showLogoutDialog(),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppTheme.accentRed),
                  foregroundColor: AppTheme.accentRed,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryYellow.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryYellow, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mediumGray,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                // ✅ Show actual value; fallback to 'Not set' if empty
                value.isNotEmpty ? value : 'Not set',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => _showEditProfileDialog(),
        ),
      ],
    );
  }

  Widget _buildMenuOption(String title, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryYellow),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.black54),
        onTap: onTap,
      ),
    );
  }

  // ─────────────────────────── Dialogs ───────────────────────────

  ImageProvider _getProfileImageProvider(String userImageUrl) {
    if (_pickedBytes != null) {
      return MemoryImage(_pickedBytes!);
    }
    if (_pickedImage != null && !kIsWeb && _pickedImage!.existsSync()) {
      return FileImage(_pickedImage!);
    }
    if (userImageUrl.isNotEmpty) {
      if (userImageUrl.startsWith('data:image')) {
        try {
          final base64Data = userImageUrl.split(',').last;
          return MemoryImage(base64Decode(base64Data));
        } catch (_) {}
      }
      if (userImageUrl.startsWith('assets/')) {
        return AssetImage(userImageUrl);
      } else if (userImageUrl.startsWith('http://') || userImageUrl.startsWith('https://')) {
        return NetworkImage(userImageUrl);
      } else if (!kIsWeb) {
        final file = File(userImageUrl);
        if (file.existsSync()) {
          return FileImage(file);
        }
      }
    }
    return const AssetImage('assets/images/avatar.jpg');
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Profile Photo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primaryYellow),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.primaryYellow),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_pickedBytes != null || _pickedImage != null || !DummyData.currentUser.imageUrl.startsWith('assets/'))
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppTheme.accentRed),
                  title: const Text('Remove Photo', style: TextStyle(color: AppTheme.accentRed)),
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfileImage();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        // Read raw image bytes for universal cross-platform support (Web, Windows Desktop, Mobile)
        final bytes = await picked.readAsBytes();
        final base64Str = base64Encode(bytes);

        // Invalidate Flutter image cache so new image renders instantly
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();

        // Save base64 string in SharedPreferences for instant persistence without plugin errors
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profileImageBase64', base64Str);

        // Safely try saving file path if path_provider is available (non-web)
        String savedPath = picked.path;
        if (!kIsWeb) {
          try {
            final appDir = await getApplicationDocumentsDirectory();
            final ext = p.extension(picked.path).isNotEmpty ? p.extension(picked.path) : '.jpg';
            final fileName = 'profile_dp_${DateTime.now().millisecondsSinceEpoch}$ext';
            final targetPath = '${appDir.path}/$fileName';
            final savedFile = await File(picked.path).copy(targetPath);
            savedPath = savedFile.path;
            await prefs.setString('profileImagePath', savedPath);
          } catch (_) {
            // Path provider fallback ignored gracefully
          }
        }

        if (mounted) {
          setState(() {
            _pickedBytes = bytes;
            if (!kIsWeb && savedPath.isNotEmpty) {
              _pickedImage = File(savedPath);
            }
            DummyData.currentUser = UserModel(
              id: DummyData.currentUser.id,
              name: DummyData.currentUser.name,
              email: DummyData.currentUser.email,
              phone: DummyData.currentUser.phone,
              location: DummyData.currentUser.location,
              imageUrl: savedPath.isNotEmpty ? savedPath : 'data:image/jpeg;base64,$base64Str',
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully ✓'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick image: ${e.toString()}'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _removeProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profileImageBase64');
    await prefs.remove('profileImagePath');

    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    if (mounted) {
      setState(() {
        _pickedBytes = null;
        _pickedImage = null;
        DummyData.currentUser = UserModel(
          id: DummyData.currentUser.id,
          name: DummyData.currentUser.name,
          email: DummyData.currentUser.email,
          phone: DummyData.currentUser.phone,
          location: DummyData.currentUser.location,
          imageUrl: 'assets/images/avatar.jpg',
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture removed')),
      );
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('No additional settings available'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    // ✅ Pre-fill controllers with current user data
    _nameController.text = DummyData.currentUser.name;
    _emailController.text = DummyData.currentUser.email;
    _phoneController.text = DummyData.currentUser.phone;
    _locationController.text = DummyData.currentUser.location;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });

              try {
                final userId = int.tryParse(DummyData.currentUser.id) ?? 1;
                final response = await http.put(
                  Uri.parse(ApiConfig.updateUserUrl(userId)),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'phone': _phoneController.text,
                    'location': _locationController.text,
                  }),
                );

                if (response.statusCode == 200) {
                  final data = jsonDecode(response.body);
                  if (data['success']) {
                    setState(() {
                      DummyData.currentUser = UserModel(
                        id: DummyData.currentUser.id,
                        name: _nameController.text,
                        email: _emailController.text,
                        phone: _phoneController.text,
                        location: _locationController.text,
                        imageUrl: DummyData.currentUser.imageUrl,
                      );
                      _isLoading = false;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated successfully')),
                    );
                  }
                } else {
                  setState(() {
                    _isLoading = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update profile')),
                  );
                }
              } catch (error) {
                setState(() {
                  _isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${error.toString()}')),
                );
              }
            },
            child: _isLoading ? const CircularProgressIndicator() : const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: Icon(Icons.lock_open),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: Icon(Icons.lock_reset),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password changed successfully')),
              );
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  void _showPaymentMethodsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Methods'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.credit_card),
              title: Text('Visa ending in 4242'),
              subtitle: Text('Expires 12/25'),
            ),
            ListTile(
              leading: Icon(Icons.credit_card),
              title: Text('Mastercard ending in 8888'),
              subtitle: Text('Expires 08/26'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add payment method feature coming soon')),
              );
            },
            child: const Text('Add New'),
          ),
        ],
      ),
    );
  }

  // ✅ New: Privacy Policy / Terms content dialog
  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ✅ New: Help & Support dialog
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.email_outlined),
              title: Text('Email Us'),
              subtitle: Text('support@constructhub.in'),
            ),
            ListTile(
              leading: Icon(Icons.phone_outlined),
              title: Text('Call Us'),
              subtitle: Text('+91 98765 43210'),
            ),
            ListTile(
              leading: Icon(Icons.chat_outlined),
              title: Text('Live Chat'),
              subtitle: Text('Available 9AM - 6PM'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
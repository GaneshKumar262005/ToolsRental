import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/firebase_service.dart';
import '../themes/app_theme.dart';

class ConnectionStatusBar extends StatefulWidget {
  const ConnectionStatusBar({super.key});

  @override
  State<ConnectionStatusBar> createState() => _ConnectionStatusBarState();
}

class _ConnectionStatusBarState extends State<ConnectionStatusBar> {
  bool _isBackendOnline = false;
  bool _isFirebaseOnline = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkConnections();
  }

  Future<void> _checkConnections() async {
    setState(() => _checking = true);
    
    // Check Backend
    try {
      final response = await http.get(Uri.parse(ApiConfig.healthUrl)).timeout(const Duration(seconds: 2));
      _isBackendOnline = response.statusCode == 200;
    } catch (_) {
      _isBackendOnline = false;
    }

    // Check Firebase
    _isFirebaseOnline = FirebaseService().isInitialized;

    if (mounted) {
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlack.withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _statusDot(_isBackendOnline, 'Server'),
          const SizedBox(width: 16),
          _statusDot(_isFirebaseOnline, 'Firebase'),
          if (!_checking)
            IconButton(
              icon: const Icon(Icons.refresh, size: 14, color: Colors.white70),
              onPressed: _checkConnections,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.only(left: 8),
            ),
        ],
      ),
    );
  }

  Widget _statusDot(bool online, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _checking ? Colors.grey : (online ? Colors.green : Colors.red),
            shape: BoxShape.circle,
            boxShadow: [
              if (online && !_checking)
                BoxShadow(color: Colors.green.withOpacity(0.5), blurRadius: 4, spreadRadius: 1),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

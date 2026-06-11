import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import '../themes/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../config/api_config.dart';

class BackendAdminScreen extends StatefulWidget {
  const BackendAdminScreen({super.key});

  @override
  State<BackendAdminScreen> createState() => _BackendAdminScreenState();
}

class _BackendAdminScreenState extends State<BackendAdminScreen> {
  bool _isServerRunning = false;
  String _serverStatus = 'Checking...';
  List<String> _logs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkServerStatus();
  }

  Future<void> _checkServerStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.healthUrl),
      ).timeout(
        const Duration(seconds: 3),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isServerRunning = true;
          _serverStatus = 'Running';
          _logs.add('[${DateTime.now().toString().substring(0, 19)}] Server is running');
        });
      } else {
        setState(() {
          _isServerRunning = false;
          _serverStatus = 'Error';
          _logs.add('[${DateTime.now().toString().substring(0, 19)}] Server returned error: ${response.statusCode}');
        });
      }
    } catch (error) {
      setState(() {
        _isServerRunning = false;
        _serverStatus = 'Stopped';
        _logs.add('[${DateTime.now().toString().substring(0, 19)}] Server connection failed: $error');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '[${DateTime.now().toString().substring(0, 19)}] $message');
      if (_logs.length > 50) {
        _logs.removeLast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Server Admin'),
        backgroundColor: AppTheme.primaryWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Server Status Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.mediumGray.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _isServerRunning ? AppTheme.accentGreen : AppTheme.accentRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Server Status',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            _serverStatus,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: _isServerRunning ? AppTheme.accentGreen : AppTheme.accentRed,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(width: 12),
                          if (_isLoading)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ApiConfig.baseUrl,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.mediumGray,
                            ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),
                const SizedBox(height: 24),

                // Server Info
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.mediumGray.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Server Information',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Framework', 'Node.js / Express'),
                      _buildInfoRow('Port', '3000'),
                      _buildInfoRow('API Version', '1.0.0'),
                      _buildInfoRow('Environment', 'Development'),
                    ],
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 200)),
                const SizedBox(height: 24),

                // Actions
                Text(
                  'Server Actions',
                  style: Theme.of(context).textTheme.titleMedium,
                ).animate().fadeIn(delay: const Duration(milliseconds: 300)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        text: 'Check Status',
                        onPressed: _isLoading ? null : _checkServerStatus,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () {
                          _addLog('Refresh requested');
                          _checkServerStatus();
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          side: const BorderSide(color: AppTheme.mediumGray),
                        ),
                        child: const Text('Refresh'),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: const Duration(milliseconds: 400)),
                const SizedBox(height: 24),

                // Logs Section
                Text(
                  'Server Logs',
                  style: Theme.of(context).textTheme.titleMedium,
                ).animate().fadeIn(delay: const Duration(milliseconds: 500)),
                const SizedBox(height: 16),
                Container(
                  height: 300,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkGray,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _logs.isEmpty
                      ? Center(
                          child: Text(
                            'No logs yet',
                            style: TextStyle(color: AppTheme.mediumGray),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                _logs[index],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            );
                          },
                        ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 600)),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _logs.clear();
                    });
                  },
                  child: Text(
                    'Clear Logs',
                    style: TextStyle(color: AppTheme.primaryYellow),
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 700)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mediumGray,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

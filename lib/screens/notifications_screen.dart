import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../dummy_data/dummy_data.dart';
import '../themes/app_theme.dart';
import '../config/api_config.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final userId = int.tryParse(DummyData.currentUser.id) ?? 1;
      print('Fetching notifications for userId: $userId');
      print('URL: ${ApiConfig.notificationsUrl(userId)}');
      
      final response = await http.get(
        Uri.parse(ApiConfig.notificationsUrl(userId)),
      ).timeout(
        const Duration(seconds: 10),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _notifications = data['notifications'];
            _isLoading = false;
          });
          print('Notifications fetched: ${_notifications.length}');
        } else {
          setState(() {
            _isLoading = false;
          });
          print('API returned success=false');
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        print('HTTP error: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching notifications: $error');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load notifications: ${error.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (var notification in _notifications) {
                  notification['read'] = true;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked as read')),
              );
            },
            child: Text(
              'Mark all read',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryYellow,
                  ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('No notifications yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return _buildNotificationCard(notification);
                  },
                ),
    );
  }

  Widget _buildNotificationCard(dynamic notification) {
    IconData icon;
    Color iconColor;

    switch (notification['type']) {
      case 'booking_accepted':
        icon = Icons.check_circle;
        iconColor = AppTheme.accentGreen;
        break;
      case 'booking_rejected':
        icon = Icons.cancel;
        iconColor = AppTheme.accentRed;
        break;
      case 'reminder':
        icon = Icons.alarm;
        iconColor = AppTheme.accentOrange;
        break;
      case 'offer':
        icon = Icons.local_offer;
        iconColor = AppTheme.primaryYellow;
        break;
      case 'payment':
        icon = Icons.payment;
        iconColor = AppTheme.accentBlue;
        break;
      default:
        icon = Icons.notifications;
        iconColor = AppTheme.mediumGray;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          notification['read'] = true;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification['read'] ? AppTheme.primaryWhite : AppTheme.primaryYellow.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification['read']
                ? AppTheme.mediumGray.withOpacity(0.2)
                : AppTheme.primaryYellow.withOpacity(0.3),
            width: notification['read'] ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlack.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['type'] == 'booking_accepted' ? 'Booking Accepted' : 
                  notification['type'] == 'booking_rejected' ? 'Booking Rejected' : 
                  'Notification',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: notification['read'] ? FontWeight.normal : FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification['message'] ?? 'No message',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mediumGray,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDate(notification['createdAt']),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mediumGray,
                      ),
                ),
              ],
            ),
          ),
          // Unread indicator
          if (!notification['read'])
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppTheme.primaryYellow,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      ),
    );
  }

  String _formatDate(dynamic dateInput) {
    DateTime dateTime;
    
    if (dateInput is String) {
      try {
        dateTime = DateTime.parse(dateInput);
      } catch (e) {
        return 'Invalid date';
      }
    } else if (dateInput is DateTime) {
      dateTime = dateInput;
    } else {
      return 'Invalid date';
    }
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(dateTime);
    }
  }
}

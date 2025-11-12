import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api.dart';
import '../../utils/app_theme.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/empty_state.dart';

class UserNotificationsScreen extends StatefulWidget {
  const UserNotificationsScreen({super.key});

  @override
  State<UserNotificationsScreen> createState() => _UserNotificationsScreenState();
}

class _UserNotificationsScreenState extends State<UserNotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notificationsData = await Api.getUserNotifications();
      
      if (mounted) {
        if (notificationsData != null && notificationsData.isNotEmpty) {
          setState(() {
            _notifications = List<Map<String, dynamic>>.from(notificationsData);
            _unreadCount = _notifications.where((n) => !(n['isRead'] ?? false)).length;
            _isLoading = false;
          });
        } else {
          // No notifications from backend - show empty state
          setState(() {
            _notifications = [];
            _unreadCount = 0;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _notifications = [];
          _unreadCount = 0;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading notifications: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await Api.markNotificationAsRead(notificationId);
      setState(() {
        final index = _notifications.indexWhere((n) => n['_id'] == notificationId);
        if (index != -1) {
          _notifications[index]['isRead'] = true;
          _unreadCount = _notifications.where((n) => !(n['isRead'] ?? false)).length;
        }
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await Api.markAllNotificationsAsRead();
      setState(() {
        for (var notification in _notifications) {
          notification['isRead'] = true;
        }
        _unreadCount = 0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to mark all as read')),
        );
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await Api.deleteNotification(notificationId);
      setState(() {
        _notifications.removeWhere((n) => n['_id'] == notificationId);
        _unreadCount = _notifications.where((n) => !(n['isRead'] ?? false)).length;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete notification')),
        );
      }
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'booking_confirmed':
      case 'booking_accepted':
        return Icons.check_circle;
      case 'booking_completed':
        return Icons.done_all;
      case 'booking_cancelled':
        return Icons.cancel;
      case 'technician_assigned':
      case 'new_technician':
        return Icons.person_add;
      case 'payment_received':
        return Icons.payment;
      case 'rating_received':
        return Icons.star;
      case 'system_update':
        return Icons.system_update;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'booking_confirmed':
      case 'booking_accepted':
      case 'booking_completed':
        return AppTheme.success;
      case 'booking_cancelled':
        return AppTheme.error;
      case 'technician_assigned':
      case 'new_technician':
        return AppTheme.accentOrange;
      case 'payment_received':
        return AppTheme.accentPurple;
      case 'rating_received':
        return Colors.amber;
      case 'system_update':
        return AppTheme.primaryBlue;
      default:
        return AppTheme.primaryBlue;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      DateTime dateTime;
      if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        return 'Just now';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return DateFormat('MMM d, yyyy').format(dateTime);
      }
    } catch (e) {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Notifications',
            subtitle: _unreadCount > 0 
                ? '$_unreadCount unread notification${_unreadCount > 1 ? 's' : ''}'
                : 'All caught up!',
            icon: Icons.notifications,
            action: _unreadCount > 0
                ? IconButton(
                    icon: const Icon(Icons.done_all, color: Colors.white),
                    onPressed: _markAllAsRead,
                    tooltip: 'Mark all as read',
                  )
                : null,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notifications.isEmpty
                    ? EmptyState(
                        icon: Icons.notifications_none,
                        title: 'No notifications',
                        subtitle: 'You\'ll see updates about your bookings and new technicians here',
                        message: 'You\'ll see updates about your bookings and new technicians here',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadNotifications,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final notification = _notifications[index];
                            return _buildNotificationCard(notification);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['isRead'] ?? false;
    final type = notification['type'] ?? 'general';
    final title = notification['title'] ?? 'Notification';
    final message = notification['message'] ?? '';
    final timestamp = notification['createdAt'] ?? notification['timestamp'];
    final notificationId = notification['_id'] ?? '';

    return ModernCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () {
        if (!isRead && notificationId.isNotEmpty) {
          _markAsRead(notificationId);
        }
      },
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getNotificationColor(type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getNotificationIcon(type),
                  color: _getNotificationColor(type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimestamp(timestamp),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Delete button
              IconButton(
                icon: Icon(Icons.close, size: 20, color: Colors.grey[400]),
                onPressed: () => _deleteNotification(notificationId),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

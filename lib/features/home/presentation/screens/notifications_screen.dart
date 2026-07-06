import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class NotificationModel {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    this.isRead = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<NotificationModel> _notifications = [
    NotificationModel(
      id: '1',
      title: 'Package Sold!',
      description: 'Your package "Guided Anger Yoga + Cold Towel Reset" has been purchased by Raiyu. S\$120.00 has been added to your wallet balance.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      isRead: false,
    ),
    NotificationModel(
      id: '2',
      title: 'New Customer Chat',
      description: 'You received a new inquiry message from Customer Raiyu regarding yoga packages.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
    ),
    NotificationModel(
      id: '3',
      title: 'Payout Completed',
      description: 'Your monthly payout request of S\$1,500.00 was successfully processed and wired to your registered Stripe Bank Account.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
    NotificationModel(
      id: '4',
      title: 'Package Verification Approved',
      description: 'Great news! Your newly added package "1-on-1 Pilates Introductory Resale Pass" has been verified and is now live on the marketplace.',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
    ),
  ];

  void _markAsRead(int index) {
    setState(() {
      _notifications[index].isRead = true;
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification deleted')),
    );
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Clear Notifications',
          style: TextStyle(fontFamily: 'Recoleta Alt', fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        content: const Text(
          'Are you sure you want to delete all notifications? This action cannot be undone.',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.black45)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _notifications.clear();
              });
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Delete All', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontFamily: 'Recoleta Alt',
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_notifications.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'read_all') {
                  _markAllAsRead();
                } else if (value == 'clear_all') {
                  _clearAll();
                }
              },
              icon: const Icon(Icons.more_vert, color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'read_all',
                  child: Text('Mark all as read', style: TextStyle(fontSize: 13)),
                ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Text('Clear all', style: TextStyle(fontSize: 13, color: Colors.red)),
                ),
              ],
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                    child: const Icon(Icons.notifications_off_outlined, size: 36, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'All Caught Up!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary, fontFamily: 'Recoleta Alt'),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'No notifications at the moment.',
                    style: TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _notifications.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return Dismissible(
                  key: Key(notification.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) => _deleteNotification(notification.id),
                  background: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: notification.isRead ? Colors.white : const Color(0xFFFDF7EA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: notification.isRead ? AppColors.primary.withValues(alpha: 0.05) : const Color(0xFFFBBD03).withValues(alpha: 0.2),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead ? FontWeight.bold : FontWeight.w900,
                                fontSize: 14,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Text(
                            _formatTimestamp(notification.timestamp),
                            style: const TextStyle(fontSize: 10, color: Colors.black38),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          notification.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: notification.isRead ? Colors.black54 : Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: notification.isRead ? AppColors.primary.withValues(alpha: 0.05) : const Color(0xFFFBBD03).withValues(alpha: 0.1),
                        child: Icon(
                          _getIcon(notification.title),
                          size: 18,
                          color: notification.isRead ? AppColors.primary : const Color(0xFFFBBD03),
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'mark_read') {
                            _markAsRead(index);
                          } else if (value == 'delete') {
                            _deleteNotification(notification.id);
                          }
                        },
                        icon: const Icon(Icons.more_horiz, size: 18, color: Colors.black38),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        itemBuilder: (context) => [
                          if (!notification.isRead)
                            const PopupMenuItem(
                              value: 'mark_read',
                              child: Text('Mark as read', style: TextStyle(fontSize: 12)),
                            ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete', style: TextStyle(fontSize: 12, color: Colors.red)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  IconData _getIcon(String title) {
    if (title.contains('Sold')) return Icons.monetization_on_outlined;
    if (title.contains('Chat')) return Icons.chat_bubble_outline_rounded;
    if (title.contains('Payout')) return Icons.account_balance_wallet_outlined;
    return Icons.verified_outlined;
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}

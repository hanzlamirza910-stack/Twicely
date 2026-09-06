import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../chat/presentation/chat_helpers.dart';
import '../../../chat/presentation/screens/chat_detail_screen.dart';

class NotificationModel {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  bool isRead;
  final Map<String, dynamic>? sessionData;

  NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    this.isRead = false,
    this.sessionData,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLiveNotifications();
  }

  Future<void> _fetchLiveNotifications() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getChatSessions(role: 'buyer'),
        ApiService.getChatSessions(role: 'seller'),
      ]);

      final List<Map<String, dynamic>> rawSessions = [];
      for (final res in results) {
        if (res['success'] == true && res['data'] is List) {
          final list = (res['data'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e));
          rawSessions.addAll(list);
        }
      }

      // De-duplicate sessions by ID
      final Map<int, Map<String, dynamic>> uniqueSessions = {};
      for (final s in rawSessions) {
        final id = int.tryParse(s['id']?.toString() ?? '');
        if (id != null) {
          uniqueSessions[id] = s;
        }
      }

      final List<NotificationModel> loadedList = [];
      for (final s in uniqueSessions.values) {
        final enriched = await ChatSessionHelper.enrichSessionData(s);
        final otherName = ChatSessionHelper.resolveOtherPartyName(enriched);
        final pkgTitle = ChatSessionHelper.resolvePackageTitle(enriched);
        final lastMsg = (enriched['last_message_content'] ?? '').toString();
        final lastTimeStr = (enriched['last_message_at'] ?? enriched['created_at'] ?? '').toString();

        DateTime timestamp = DateTime.now();
        if (lastTimeStr.isNotEmpty) {
          try {
            timestamp = DateTime.parse(lastTimeStr).toLocal();
          } catch (_) {}
        }

        final unread = int.tryParse(enriched['unread_count']?.toString() ?? '0') ?? 0;
        final String title = unread > 0
            ? 'New message from $otherName'
            : 'Chat with $otherName';
        final String desc = lastMsg.isNotEmpty
            ? '$otherName: $lastMsg'
            : 'Package: $pkgTitle';

        loadedList.add(NotificationModel(
          id: (enriched['id'] ?? s['id']).toString(),
          title: title,
          description: desc,
          timestamp: timestamp,
          isRead: unread == 0,
          sessionData: enriched,
        ));
      }

      // Sort by timestamp descending
      loadedList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (mounted) {
        setState(() {
          _notifications = loadedList;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
    CustomSnackBar.show(
      context,
      message: 'All notifications marked as read',
      type: SnackBarType.success,
    );
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
    CustomSnackBar.show(
      context,
      message: 'Notification deleted',
      type: SnackBarType.success,
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            )
          : _notifications.isEmpty
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
              : RefreshIndicator(
                  onRefresh: _fetchLiveNotifications,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _notifications.length,
                    physics: const AlwaysScrollableScrollPhysics(),
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
                            onTap: () {
                              _markAsRead(index);
                              if (notification.sessionData != null) {
                                final sId = int.tryParse(notification.sessionData!['id']?.toString() ?? '') ?? 0;
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ChatDetailScreen(
                                      sessionId: sId,
                                      session: notification.sessionData!,
                                    ),
                                  ),
                                );
                              }
                            },
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
                ),
    );
  }

  IconData _getIcon(String title) {
    if (title.contains('Message') || title.contains('Chat')) return Icons.chat_bubble_outline_rounded;
    return Icons.notifications_none_rounded;
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes <= 0 ? 1 : diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}

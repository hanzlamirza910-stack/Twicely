import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'chat_detail_screen.dart';
import '../../../home/presentation/screens/notifications_screen.dart';

class ConversationsScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;

  const ConversationsScreen({
    super.key,
    this.onProfileTap,
  });

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final List<Map<String, dynamic>> _conversations = [
    {
      'name': 'Sarah Jenkins',
      'message': 'Is the vintage lamp still available?',
      'time': '2 min ago',
      'unread': 1,
      'isImage': true,
      'avatar': 'assets/images/avatar_sarah.png',
      'isActive': true,
    },
    {
      'name': 'Mike Johnson',
      'message': 'We can do \$45 for the bundle.',
      'time': '1 hr ago',
      'unread': 3,
      'isImage': false,
      'avatar': 'MJ',
      'color': const Color(0xFFE5ECFF),
      'textColor': const Color(0xFF1E56B3),
      'isActive': false,
      'hasMuteIcon': true,
    },
    {
      'name': 'Alex Rivera',
      'message': 'Thanks! I\'ll pick it up tomorrow.',
      'time': 'Yesterday',
      'unread': 0,
      'isImage': true,
      'avatar': 'assets/images/avatar_alex.png',
      'isActive': false,
    },
    {
      'name': 'Elena Woods',
      'message': 'Okay, sounds good.',
      'time': 'Mon',
      'unread': 0,
      'isImage': true,
      'avatar': 'assets/images/avatar_elena.png',
      'isActive': false,
    },
    {
      'name': 'The Curated Closet',
      'message': 'Your package has been shipped!',
      'time': 'Nov 12',
      'unread': 0,
      'isImage': false,
      'avatar': 'TC',
      'color': const Color(0xFFFFF8D4),
      'textColor': const Color(0xFFB3921E),
      'isActive': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (canPop)
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      Image.asset(
                        'assets/images/logo.webp',
                        width: 110,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded, color: AppColors.primary, size: 24),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      if (widget.onProfileTap != null)
                        GestureDetector(
                          onTap: widget.onProfileTap,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.12), width: 1.5),
                            ),
                            child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Screen Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Messages',
                style: TextStyle(
                  fontFamily: 'Recoleta Alt',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    hintStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.4), fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Conversations List
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                itemCount: _conversations.length,
                itemBuilder: (context, index) {
                  final chat = _conversations[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          chat['unread'] = 0;
                        });
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ChatDetailScreen(
                              name: chat['name'] as String,
                              avatar: chat['avatar'] as String,
                              isImage: chat['isImage'] as bool,
                              initialMessage: chat['message'] as String,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.015),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.04),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildAvatar(chat),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        chat['name'] as String,
                                        style: TextStyle(
                                          fontWeight: (chat['unread'] as int) > 0
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          fontSize: 14.5,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      Text(
                                        chat['time'] as String,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: (chat['unread'] as int) > 0
                                              ? const Color(0xFF1E56B3)
                                              : Colors.black38,
                                          fontWeight: (chat['unread'] as int) > 0
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      if (chat['hasMuteIcon'] == true) ...[
                                        const Icon(
                                          Icons.volume_off_rounded,
                                          size: 14,
                                          color: Colors.black38,
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      Expanded(
                                        child: Text(
                                          chat['message'] as String,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: (chat['unread'] as int) > 0
                                                ? AppColors.primary
                                                : Colors.black45,
                                            fontWeight: (chat['unread'] as int) > 0
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      if ((chat['unread'] as int) > 0) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFBBD03),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${chat['unread']}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> chat) {
    Widget avatarWidget;
    if (chat['isImage'] as bool) {
      final avatarStr = chat['avatar'] as String;
      avatarWidget = CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey.shade100,
        backgroundImage: avatarStr.startsWith('http')
            ? NetworkImage(avatarStr)
            : (avatarStr.startsWith('assets/')
                ? AssetImage(avatarStr)
                : const AssetImage('assets/images/package_spa.jpg')) as ImageProvider,
      );
    } else {
      avatarWidget = CircleAvatar(
        radius: 24,
        backgroundColor: chat['color'] as Color,
        child: Text(
          chat['avatar'] as String,
          style: TextStyle(
            color: chat['textColor'] as Color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    }

    if (chat['isActive'] == true) {
      return Stack(
        children: [
          avatarWidget,
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50), // Active green
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ],
      );
    }
    return avatarWidget;
  }
}

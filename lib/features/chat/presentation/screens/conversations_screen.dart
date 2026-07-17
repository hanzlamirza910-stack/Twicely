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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _conversations = [
    {
      'name': 'Sarah Jenkins',
      'message': 'Is the vintage lamp still available?',
      'time': '2 min ago',
      'unread': 1,
      'initials': 'SJ',
      'color': const Color(0xFFE5F0FF),
      'textColor': const Color(0xFF1E56B3),
      'isActive': true,
    },
    {
      'name': 'Mike Johnson',
      'message': 'We can do \$45 for the bundle.',
      'time': '1 hr ago',
      'unread': 3,
      'initials': 'MJ',
      'color': const Color(0xFFF0EDFF),
      'textColor': const Color(0xFF5B3FC8),
      'isActive': false,
      'hasMuteIcon': true,
    },
    {
      'name': 'Alex Rivera',
      'message': 'Thanks! I\'ll pick it up tomorrow.',
      'time': 'Yesterday',
      'unread': 0,
      'initials': 'AR',
      'color': const Color(0xFFE9F8F0),
      'textColor': const Color(0xFF256842),
      'isActive': false,
    },
    {
      'name': 'Elena Woods',
      'message': 'Okay, sounds good.',
      'time': 'Mon',
      'unread': 0,
      'initials': 'EW',
      'color': const Color(0xFFFFF3E0),
      'textColor': const Color(0xFF9C5A0A),
      'isActive': false,
    },
    {
      'name': 'The Curated Closet',
      'message': 'Your package has been shipped!',
      'time': 'Nov 12',
      'unread': 0,
      'initials': 'TC',
      'color': const Color(0xFFFFF8D4),
      'textColor': const Color(0xFFB3921E),
      'isActive': false,
    },
  ];

  List<Map<String, dynamic>> get _filteredConversations {
    if (_searchQuery.isEmpty) return _conversations;
    return _conversations.where((c) {
      final name = (c['name'] as String).toLowerCase();
      final msg = (c['message'] as String).toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) ||
          msg.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final filtered = _filteredConversations;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header Row (matches Home/Search design) ──────────────────
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 8.0, top: 16.0),
              child: Row(
                children: [
                  if (canPop)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.arrow_back_rounded, color: AppColors.primary, size: 22),
                      ),
                    ),
                  Image.asset(
                    'assets/images/logo.webp',
                    height: 38,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Text(
                      'twicely',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded,
                        color: AppColors.primary, size: 26),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const NotificationsScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  if (widget.onProfileTap != null)
                    GestureDetector(
                      onTap: widget.onProfileTap,
                      child: Container(
                        width: 38,
                        height: 38,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.person_outline_rounded,
                            color: AppColors.primary, size: 20),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Title ──────────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Messages',
                style: TextStyle(
                  fontFamily: 'Recoleta Alt',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Search Bar (matches Home screen style exactly) ─────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TextFormField(
                controller: _searchController,
                style: const TextStyle(fontSize: 14, color: Color(0xFF1F2E4E)),
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Search messages...',
                  hintStyle: TextStyle(color: const Color(0xFF1F2E4E).withValues(alpha: 0.4)),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1F2E4E), size: 22),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () => setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          }),
                          child: const Icon(Icons.cancel_rounded, color: Color(0xFF1F2E4E), size: 20),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color(0xFF273DB7), width: 1.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color(0xFF273DB7), width: 1.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color(0xFF273DB7), width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // ── Conversations List ──────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 52,
                              color: AppColors.primary.withValues(alpha: 0.12)),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No results found'
                                : 'No conversations yet',
                            style: TextStyle(
                                fontSize: 14,
                                color:
                                    AppColors.primary.withValues(alpha: 0.35),
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 4),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final chat = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: _buildConversationTile(chat),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> chat) {
    final int unread = chat['unread'] as int;
    return GestureDetector(
      onTap: () {
        setState(() => chat['unread'] = 0);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              name: chat['name'] as String,
              avatar: chat['initials'] as String,
              isImage: false,
              initialMessage: chat['message'] as String,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: unread > 0
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.primary.withValues(alpha: 0.04),
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
                      Expanded(
                        child: Text(
                          chat['name'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: unread > 0
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        chat['time'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: unread > 0
                              ? const Color(0xFF1E56B3)
                              : Colors.black38,
                          fontWeight: unread > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      if (chat['hasMuteIcon'] == true) ...[
                        const Icon(Icons.volume_off_rounded,
                            size: 13, color: Colors.black38),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          chat['message'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: unread > 0 ? AppColors.primary : Colors.black45,
                            fontWeight: unread > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (unread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBBD03),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$unread',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
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
    );
  }

  Widget _buildAvatar(Map<String, dynamic> chat) {
    final Widget av = CircleAvatar(
      radius: 24,
      backgroundColor: chat['color'] as Color,
      child: Text(
        chat['initials'] as String,
        style: TextStyle(
          color: chat['textColor'] as Color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );

    if (chat['isActive'] == true) {
      return Stack(
        children: [
          av,
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ],
      );
    }
    return av;
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/session_manager.dart';
import 'chat_detail_screen.dart';
import '../../../home/presentation/screens/notifications_screen.dart';
import '../chat_helpers.dart';
import '../widgets/chat_shimmer.dart';


class ConversationsScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;

  /// Default role ('seller' or 'buyer').
  final String role;

  const ConversationsScreen({
    super.key,
    this.onProfileTap,
    this.role = 'seller',
  });

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late String _activeRole;
  String _activeStatus = 'active'; // 'active', 'closed', 'all'

  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = true;
  String? _errorMessage;

  // In-memory tab session cache to eliminate API re-fetching and flicker when switching tabs
  final Map<String, List<Map<String, dynamic>>> _sessionsCache = {};

  // Periodic refresh timer so new messages update the list
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _activeRole = widget.role;
    _loadSessions();
    // Refresh every 15 seconds to pick up new incoming messages
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _loadSessions(silent: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSessions({bool silent = false}) async {
    final int currentUserId = SessionManager.userId ?? 0;
    final cacheKey = '${currentUserId}_${_activeRole}_$_activeStatus';
    if (_sessionsCache.containsKey(cacheKey) && !silent) {
      setState(() {
        _sessions = _sessionsCache[cacheKey]!;
        _isLoading = false;
        _errorMessage = null;
      });
      silent = true; // Fetch background update silently
    }

    if (!silent && mounted) setState(() => _isLoading = true);

    try {
      final res = await ApiService.getChatSessions(
        role: _activeRole,
        status: _activeStatus,
      );
      if (!mounted) return;
      if (res['success'] == true && res['data'] is List) {
        final raw = (res['data'] as List<dynamic>)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        final enrichedList = await Future.wait(
          raw.map((s) => ChatSessionHelper.enrichSessionData(s)),
        );

        if (!mounted) return;
        _sessionsCache[cacheKey] = enrichedList;
        setState(() {
          _sessions = enrichedList;
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        if (_sessions.isEmpty) {
          setState(() {
            _isLoading = false;
            _errorMessage = res['message']?.toString() ?? 'Failed to load conversations.';
          });
        }
      }
    } catch (e) {
      if (mounted && _sessions.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not connect to server.';
        });
      }
    }
  }



  List<Map<String, dynamic>> get _filteredSessions {
    if (_searchQuery.isEmpty) return _sessions;
    final q = _searchQuery.toLowerCase();
    return _sessions.where((s) {
      final pkg = (s['package_title'] ?? s['package_name'] ?? '').toString().toLowerCase();
      final owner = (s['owner_name'] ?? s['buyer_name'] ?? '').toString().toLowerCase();
      final msg = (s['last_message_content'] ?? '').toString().toLowerCase();
      return pkg.contains(q) || owner.contains(q) || msg.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ModalRoute<dynamic>? parentRoute = ModalRoute.of(context);
    final bool canPop = parentRoute?.canPop ?? false;
    final bool isFirst = parentRoute?.isFirst ?? true;
    final bool showBackButton = canPop && !isFirst;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header Row ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 8.0, top: 16.0),
              child: Row(
                children: [
                  if (showBackButton)
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
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
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

            // ── Title ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Messages',
                    style: TextStyle(
                      fontFamily: 'Recoleta Alt',
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  // Role Toggle Pills
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        _buildRoleTab('seller', 'Seller Inbox'),
                        _buildRoleTab('buyer', 'Buyer Chats'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Status Filter Chips & Search Bar ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1F2E4E)),
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Search messages...',
                        hintStyle: TextStyle(color: const Color(0xFF1F2E4E).withValues(alpha: 0.4)),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1F2E4E), size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () => setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                }),
                                child: const Icon(Icons.cancel_rounded, color: Color(0xFF1F2E4E), size: 18),
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    initialValue: _activeStatus,
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF273DB7), width: 1.0),
                      ),
                      child: const Icon(Icons.filter_list_rounded, size: 20, color: AppColors.primary),
                    ),
                    onSelected: (status) {
                      setState(() => _activeStatus = status);
                      _loadSessions();
                    },
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(value: 'active', child: Text('Active Sessions')),
                      PopupMenuItem(value: 'closed', child: Text('Closed Sessions')),
                      PopupMenuItem(value: 'all', child: Text('All Sessions')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Content ──────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const ChatConversationSkeletonList()
                  : _errorMessage != null
                      ? _buildErrorState()
                      : RefreshIndicator(
                          onRefresh: _loadSessions,
                          color: AppColors.primary,
                          child: _buildSessionList(),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleTab(String roleKey, String label) {
    final bool isSelected = _activeRole == roleKey;
    return GestureDetector(
      onTap: () {
        if (_activeRole != roleKey) {
          setState(() {
            _activeRole = roleKey;
          });
          _loadSessions();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.primary.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 52,
                color: AppColors.primary.withValues(alpha: 0.2)),
            const SizedBox(height: 14),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 18),
            TextButton.icon(
              onPressed: _loadSessions,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionList() {
    final filtered = _filteredSessions;
    if (filtered.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 300,
            child: Center(
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
                        : _activeRole == 'seller'
                            ? 'No buyer messages yet'
                            : 'No buyer conversations yet',
                    style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primary.withValues(alpha: 0.35),
                        fontWeight: FontWeight.bold),
                  ),
                  if (_searchQuery.isEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _activeRole == 'seller'
                          ? 'Buyers will appear here when they message\nyou about your listed packages.'
                          : 'Click "Chat Now" on any package detail page to start a chat.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary.withValues(alpha: 0.25)),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final session = filtered[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: _buildSessionTile(session),
        );
      },
    );
  }

  Widget _buildSessionTile(Map<String, dynamic> session) {
    final int sessionId = int.tryParse(session['id']?.toString() ?? '') ?? 0;
    final int unread = int.tryParse(session['unread_count']?.toString() ?? '0') ?? 0;
    final String packageTitle = ChatSessionHelper.resolvePackageTitle(session);
    final String lastMsg = (session['last_message_content'] ?? 'No messages yet').toString();
    final String timeStr = _formatTime(session['last_message_at']?.toString() ?? session['created_at']?.toString());

    final String otherName = ChatSessionHelper.resolveOtherPartyName(session, activeRole: _activeRole);
    final String otherAvatar = ChatSessionHelper.resolveOtherPartyAvatar(session, activeRole: _activeRole);
    final String thumbnail = ChatSessionHelper.resolvePackageThumbnail(session);

    final String initial = otherName.isNotEmpty ? otherName[0].toUpperCase() : 'U';
    final Color avatarBg = _colorForInitial(initial);
    final Color textCol = _textColorForBg(avatarBg);
    final bool isClosed = session['status'] == 'closed';

    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              sessionId: sessionId,
              session: session,
            ),
          ),
        );
        if (mounted) _loadSessions(silent: true);
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
            _buildAvatar(otherAvatar, thumbnail, initial, avatarBg, textCol),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                packageTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: unread > 0 ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            if (isClosed) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('Closed', style: TextStyle(fontSize: 9, color: Colors.grey)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: unread > 0 ? const Color(0xFF1E56B3) : Colors.black38,
                          fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _activeRole == 'seller' ? 'From: $otherName' : 'Seller: $otherName',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMsg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: unread > 0 ? AppColors.primary : Colors.black45,
                            fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (unread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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

  Widget _buildAvatar(String rawAvatarUrl, String thumbnailUrl, String initial, Color bg, Color textCol) {
    final String avatarUrl = ApiService.unescapeHtml(rawAvatarUrl).trim();
    if (avatarUrl.isNotEmpty && avatarUrl.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          avatarUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialAvatar(initial, bg, textCol),
        ),
      );
    }
    return _initialAvatar(initial, bg, textCol);
  }

  Widget _initialAvatar(String initial, Color bg, Color textCol) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: bg,
      child: Text(
        initial,
        style: TextStyle(color: textCol, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatTime(String? isoString) {
    return ChatSessionHelper.formatConversationTime(isoString);
  }

  Color _colorForInitial(String initial) {
    final colors = [
      const Color(0xFFE5F0FF),
      const Color(0xFFF0EDFF),
      const Color(0xFFE9F8F0),
      const Color(0xFFFFF3E0),
      const Color(0xFFFFF8D4),
      const Color(0xFFFFEBEE),
      const Color(0xFFE8F5E9),
      const Color(0xFFFCE4EC),
    ];
    final code = initial.isNotEmpty ? initial.codeUnitAt(0) : 0;
    return colors[code % colors.length];
  }

  Color _textColorForBg(Color bg) {
    final luminance = bg.computeLuminance();
    return luminance > 0.7 ? const Color(0xFF1F2E4E) : Colors.white;
  }
}

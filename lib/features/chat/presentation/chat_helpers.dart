import '../../../core/services/api_service.dart';
import '../../../core/utils/session_manager.dart';

class ChatSessionHelper {
  /// Resolves the authentic name of the other party in a chat session.
  /// [session]: Map containing session data.
  /// [activeRole]: 'seller' or 'buyer' (optional).
  static String resolveOtherPartyName(Map<String, dynamic> session, {String? activeRole}) {
    final int? myUserId = SessionManager.userId;
    final int? myMerchantId = int.tryParse(
      SessionManager.userData?['merchant_id']?.toString() ??
      SessionManager.userData?['merchant']?['id']?.toString() ?? '',
    );
    final int? ownerId = int.tryParse(
      session['owner_id']?.toString() ??
      session['merchant_id']?.toString() ??
      session['owner']?['id']?.toString() ??
      session['package']?['owner_id']?.toString() ?? '',
    );
    final int? buyerId = int.tryParse(
      session['user_id']?.toString() ??
      session['buyer_id']?.toString() ??
      session['created_by']?.toString() ??
      session['user']?['id']?.toString() ??
      session['buyer']?['id']?.toString() ?? '',
    );

    // Determine if current logged-in user is the Seller in this session
    bool isMeSeller = false;
    if (activeRole == 'seller') {
      isMeSeller = true;
    } else if (activeRole == 'buyer') {
      isMeSeller = false;
    } else {
      if (myUserId != null && ownerId != null && myUserId == ownerId) {
        isMeSeller = true;
      } else if (myMerchantId != null && ownerId != null && myMerchantId == ownerId) {
        isMeSeller = true;
      } else if (myUserId != null && buyerId != null && myUserId == buyerId) {
        isMeSeller = false;
      }
    }

    if (isMeSeller) {
      return _extractBuyerName(session);
    } else {
      return _extractSellerName(session);
    }
  }

  /// Resolves the authentic avatar URL of the other party in a chat session.
  static String resolveOtherPartyAvatar(Map<String, dynamic> session, {String? activeRole}) {
    final int? myUserId = SessionManager.userId;
    final int? myMerchantId = int.tryParse(
      SessionManager.userData?['merchant_id']?.toString() ??
      SessionManager.userData?['merchant']?['id']?.toString() ?? '',
    );
    final int? ownerId = int.tryParse(
      session['owner_id']?.toString() ??
      session['merchant_id']?.toString() ??
      session['owner']?['id']?.toString() ??
      session['package']?['owner_id']?.toString() ?? '',
    );
    final int? buyerId = int.tryParse(
      session['user_id']?.toString() ??
      session['buyer_id']?.toString() ??
      session['created_by']?.toString() ??
      session['user']?['id']?.toString() ??
      session['buyer']?['id']?.toString() ?? '',
    );

    bool isMeSeller = false;
    if (activeRole == 'seller') {
      isMeSeller = true;
    } else if (activeRole == 'buyer') {
      isMeSeller = false;
    } else {
      if (myUserId != null && ownerId != null && myUserId == ownerId) {
        isMeSeller = true;
      } else if (myMerchantId != null && ownerId != null && myMerchantId == ownerId) {
        isMeSeller = true;
      } else if (myUserId != null && buyerId != null && myUserId == buyerId) {
        isMeSeller = false;
      }
    }

    if (isMeSeller) {
      return _extractBuyerAvatar(session);
    } else {
      return _extractSellerAvatar(session);
    }
  }

  /// Resolves the authentic title of the package.
  static String resolvePackageTitle(Map<String, dynamic> session) {
    final String? title = session['package_title']?.toString() ??
        session['package_name']?.toString() ??
        session['title']?.toString() ??
        session['package']?['title']?.toString() ??
        session['package']?['name']?.toString();
    if (title != null && title.isNotEmpty && title != 'Package') {
      return ApiService.unescapeHtml(title);
    }
    final packageId = session['package_id']?.toString() ?? session['package']?['id']?.toString();
    if (packageId != null && packageId.isNotEmpty) {
      return 'Package #$packageId';
    }
    return 'Package';
  }

  /// Resolves the thumbnail image URL of the package.
  static String resolvePackageThumbnail(Map<String, dynamic> session) {
    final String? thumb = session['package_thumbnail']?.toString() ??
        session['package_image']?.toString() ??
        session['package_cover']?.toString() ??
        session['package']?['thumbnail']?.toString() ??
        session['package']?['cover_image']?.toString();
    if (thumb != null && thumb.startsWith('http')) return thumb;
    if (session['package']?['images'] is List && (session['package']['images'] as List).isNotEmpty) {
      final img = session['package']['images'][0];
      if (img is Map && img['url'] != null && img['url'].toString().startsWith('http')) {
        return img['url'].toString();
      }
    }
    return '';
  }

  // ── Private Extraction Helpers ─────────────────────────────────────────────

  static String _extractBuyerName(Map<String, dynamic> session) {
    final name = session['buyer_name']?.toString() ??
        session['user_name'] ??
        session['buyer_display_name'] ??
        session['user_display_name'] ??
        session['buyer']?['name'] ??
        session['buyer']?['display_name'] ??
        session['user']?['name'] ??
        session['user']?['display_name'];
    if (name != null && name.toString().trim().isNotEmpty && name.toString().trim() != 'Buyer') {
      return ApiService.unescapeHtml(name.toString().trim());
    }
    final buyerId = int.tryParse(session['user_id']?.toString() ?? session['buyer_id']?.toString() ?? '');
    if (buyerId != null && ApiService.usersCache.containsKey(buyerId)) {
      final u = ApiService.usersCache[buyerId]!;
      final cacheName = u['name']?.toString() ?? u['display_name']?.toString();
      if (cacheName != null && cacheName.isNotEmpty) return ApiService.unescapeHtml(cacheName);
    }
    return 'Buyer';
  }

  static String _extractSellerName(Map<String, dynamic> session) {
    final name = session['seller_name']?.toString() ??
        session['owner_name']?.toString() ??
        session['merchant_name'] ??
        session['owner_business_name'] ??
        session['seller']?['name'] ??
        session['owner']?['business_name'] ??
        session['owner']?['name'] ??
        session['merchant']?['name'] ??
        session['merchant']?['business_name'] ??
        session['presented_by']?['name'] ??
        session['package']?['owner_name'] ??
        session['package']?['presented_by']?['name'];
    if (name != null && name.toString().trim().isNotEmpty && name.toString().trim() != 'Seller') {
      return ApiService.unescapeHtml(name.toString().trim());
    }
    final ownerId = int.tryParse(session['seller_id']?.toString() ?? session['owner_id']?.toString() ?? session['merchant_id']?.toString() ?? '');
    if (ownerId != null) {
      if (ApiService.merchantsCache.containsKey(ownerId)) {
        final m = ApiService.merchantsCache[ownerId]!;
        final mName = m['business_name']?.toString() ?? m['name']?.toString();
        if (mName != null && mName.isNotEmpty) return ApiService.unescapeHtml(mName);
      }
      if (ApiService.usersCache.containsKey(ownerId)) {
        final u = ApiService.usersCache[ownerId]!;
        final uName = u['name']?.toString() ?? u['display_name']?.toString();
        if (uName != null && uName.isNotEmpty) return ApiService.unescapeHtml(uName);
      }
    }
    return 'Seller';
  }

  static String _extractBuyerAvatar(Map<String, dynamic> session) {
    final avatar = session['buyer_avatar']?.toString() ??
        session['user_avatar'] ??
        session['buyer']?['avatar'] ??
        session['buyer']?['avatar_url'] ??
        session['user']?['avatar'];
    if (avatar != null && avatar.trim().isNotEmpty) {
      final clean = ApiService.unescapeHtml(avatar.trim());
      if (clean.startsWith('http')) return clean;
    }
    if (session['user']?['avatar_urls'] is Map) {
      final urls = session['user']['avatar_urls'] as Map;
      final u = urls['96']?.toString() ?? urls['48']?.toString();
      if (u != null) {
        final clean = ApiService.unescapeHtml(u.trim());
        if (clean.startsWith('http')) return clean;
      }
    }
    final buyerId = int.tryParse(session['user_id']?.toString() ?? session['buyer_id']?.toString() ?? '');
    if (buyerId != null && ApiService.usersCache.containsKey(buyerId)) {
      final u = ApiService.usersCache[buyerId]!;
      final urls = u['avatar_urls'];
      if (urls is Map) {
        final img = urls['96']?.toString() ?? urls['48']?.toString();
        if (img != null) {
          final clean = ApiService.unescapeHtml(img.trim());
          if (clean.startsWith('http')) return clean;
        }
      }
    }
    return '';
  }

  static String _extractSellerAvatar(Map<String, dynamic> session) {
    final avatar = session['seller_avatar']?.toString() ??
        session['owner_avatar']?.toString() ??
        session['seller_photo'] ??
        session['owner_photo'] ??
        session['merchant_logo'] ??
        session['seller']?['avatar'] ??
        session['owner']?['avatar'] ??
        session['owner']?['logo_url'] ??
        session['merchant']?['logo'] ??
        session['merchant']?['logo_url'] ??
        session['presented_by']?['logo'] ??
        session['presented_by']?['logo_url'] ??
        session['package']?['owner_avatar'];
    if (avatar != null && avatar.trim().isNotEmpty) {
      final clean = ApiService.unescapeHtml(avatar.trim());
      if (clean.startsWith('http')) return clean;
    }

    final ownerId = int.tryParse(session['seller_id']?.toString() ?? session['owner_id']?.toString() ?? session['merchant_id']?.toString() ?? session['package']?['owner_id']?.toString() ?? '');
    if (ownerId != null) {
      if (ApiService.merchantsCache.containsKey(ownerId)) {
        final m = ApiService.merchantsCache[ownerId]!;
        final logo = ApiService.getMerchantLogo(ownerId, m['logo_url']?.toString());
        final clean = ApiService.unescapeHtml(logo.trim());
        if (clean.startsWith('http')) return clean;
      }
      if (ApiService.usersCache.containsKey(ownerId)) {
        final u = ApiService.usersCache[ownerId]!;
        final urls = u['avatar_urls'];
        if (urls is Map) {
          final img = urls['96']?.toString() ?? urls['48']?.toString();
          if (img != null) {
            final clean = ApiService.unescapeHtml(img.trim());
            if (clean.startsWith('http')) return clean;
          }
        }
      }
    }
    return '';
  }

  /// Async helper to enrich a session with live data from API if name/avatar/package title is missing.
  static Future<Map<String, dynamic>> enrichSessionData(Map<String, dynamic> session) async {
    final mutableSession = Map<String, dynamic>.from(session);

    // 1. Package details
    final packageId = int.tryParse(
      mutableSession['package_id']?.toString() ?? mutableSession['package']?['id']?.toString() ?? '',
    );
    final pTitle = mutableSession['package_title']?.toString() ?? mutableSession['package']?['title']?.toString();
    final pThumb = mutableSession['package_thumbnail']?.toString() ?? mutableSession['package']?['thumbnail']?.toString();

    if (packageId != null && packageId > 0) {
      if (ApiService.packagesCache.containsKey(packageId)) {
        final pkgData = ApiService.packagesCache[packageId]!;
        mutableSession['package'] = pkgData;
        if (mutableSession['package_title'] == null || mutableSession['package_title'] == 'Package') {
          mutableSession['package_title'] = pkgData['title'];
        }
        if (mutableSession['package_thumbnail'] == null || mutableSession['package_thumbnail'].toString().isEmpty) {
          if (pkgData['images'] is List && (pkgData['images'] as List).isNotEmpty) {
            final firstImg = pkgData['images'][0];
            if (firstImg is Map && firstImg['url'] != null) {
              mutableSession['package_thumbnail'] = firstImg['url'];
            }
          }
        }
        if (mutableSession['owner_id'] == null) mutableSession['owner_id'] = pkgData['owner_id'];
        final ownerInfo = ApiService.resolveOwnerInfo(Map<String, dynamic>.from(pkgData));
        if ((mutableSession['owner_name'] == null || mutableSession['owner_name'] == 'Seller') && ownerInfo['name'] != null && ownerInfo['name'] != 'Twicely') {
          mutableSession['owner_name'] = ownerInfo['name'];
        }
        if ((mutableSession['owner_avatar'] == null || mutableSession['owner_avatar'].toString().isEmpty) && ownerInfo['avatar'] != null && ownerInfo['avatar'].toString().isNotEmpty) {
          mutableSession['owner_avatar'] = ownerInfo['avatar'];
        }
      } else if (pTitle == null || pTitle.isEmpty || pTitle == 'Package' || pThumb == null || pThumb.isEmpty) {
        try {
          final pkgRes = await ApiService.getPackageById(packageId);
          if (pkgRes['success'] == true && pkgRes['data'] is Map) {
            final pkgData = pkgRes['data'] as Map;
            mutableSession['package'] = pkgData;
            if (pkgData['title'] != null) mutableSession['package_title'] = pkgData['title'];
            if (pkgData['images'] is List && (pkgData['images'] as List).isNotEmpty) {
              final firstImg = pkgData['images'][0];
              if (firstImg is Map && firstImg['url'] != null) {
                mutableSession['package_thumbnail'] = firstImg['url'];
              }
            }
            if (pkgData['owner_id'] != null) mutableSession['owner_id'] = pkgData['owner_id'];
            final ownerInfo = ApiService.resolveOwnerInfo(Map<String, dynamic>.from(pkgData));
            if (ownerInfo['name'] != null && ownerInfo['name'] != 'Twicely') {
              mutableSession['owner_name'] = ownerInfo['name'];
            }
            if (ownerInfo['avatar'] != null && ownerInfo['avatar'].toString().isNotEmpty) {
              mutableSession['owner_avatar'] = ownerInfo['avatar'];
            }
          }
        } catch (_) {}
      }
    }

    // 2. Buyer User profile
    final buyerId = int.tryParse(
      mutableSession['user_id']?.toString() ?? mutableSession['buyer_id']?.toString() ?? '',
    );
    final hasBuyerAvatar = mutableSession['buyer_avatar'] != null && mutableSession['buyer_avatar'].toString().trim().isNotEmpty;
    final hasBuyerName = mutableSession['buyer_name'] != null && mutableSession['buyer_name'].toString().trim().isNotEmpty && mutableSession['buyer_name'] != 'Buyer';

    if (buyerId != null && buyerId > 0 && (!hasBuyerAvatar || !hasBuyerName)) {
      if (ApiService.usersCache.containsKey(buyerId)) {
        final uData = ApiService.usersCache[buyerId]!;
        if (!hasBuyerName) mutableSession['buyer_name'] = uData['name'] ?? uData['display_name'];
        if (uData['avatar_urls'] is Map) {
          final urls = uData['avatar_urls'] as Map;
          mutableSession['buyer_avatar'] = urls['96'] ?? urls['48'];
        } else if (uData['avatar'] != null) {
          mutableSession['buyer_avatar'] = uData['avatar'];
        }
      } else {
        try {
          final uRes = await ApiService.getPublicUserProfile(buyerId);
          if (uRes['success'] == true && uRes['data'] is Map) {
            final uData = uRes['data'] as Map;
            if (!hasBuyerName) mutableSession['buyer_name'] = uData['name'] ?? uData['display_name'];
            if (uData['avatar_urls'] is Map) {
              final urls = uData['avatar_urls'] as Map;
              mutableSession['buyer_avatar'] = urls['96'] ?? urls['48'];
            } else if (uData['avatar'] != null) {
              mutableSession['buyer_avatar'] = uData['avatar'];
            }
          }
        } catch (_) {}
      }
    }

    // 3. Seller Merchant / User profile
    final ownerId = int.tryParse(
      mutableSession['owner_id']?.toString() ?? mutableSession['merchant_id']?.toString() ?? mutableSession['package']?['owner_id']?.toString() ?? '',
    );
    final hasOwnerAvatar = mutableSession['owner_avatar'] != null && mutableSession['owner_avatar'].toString().trim().isNotEmpty;
    final hasOwnerName = mutableSession['owner_name'] != null && mutableSession['owner_name'].toString().trim().isNotEmpty && mutableSession['owner_name'] != 'Seller';

    if (ownerId != null && ownerId > 0 && (!hasOwnerAvatar || !hasOwnerName)) {
      if (ApiService.merchantsCache.containsKey(ownerId)) {
        final mData = ApiService.merchantsCache[ownerId]!;
        if (!hasOwnerName) mutableSession['owner_name'] = mData['business_name'] ?? mData['name'];
        mutableSession['owner_avatar'] = ApiService.getMerchantLogo(ownerId, mData['logo_url']?.toString());
      } else if (ApiService.usersCache.containsKey(ownerId)) {
        final uData = ApiService.usersCache[ownerId]!;
        if (!hasOwnerName) mutableSession['owner_name'] = uData['name'] ?? uData['display_name'];
        if (uData['avatar_urls'] is Map) {
          final urls = uData['avatar_urls'] as Map;
          mutableSession['owner_avatar'] = urls['96'] ?? urls['48'];
        }
      } else {
        try {
          final mRes = await ApiService.getPublicMerchantProfile(ownerId);
          if (mRes['success'] == true && mRes['data'] is Map) {
            final mData = mRes['data'] as Map;
            if (!hasOwnerName) mutableSession['owner_name'] = mData['business_name'] ?? mData['name'];
            mutableSession['owner_avatar'] = ApiService.getMerchantLogo(ownerId, mData['logo_url']?.toString());
          } else {
            final uRes = await ApiService.getPublicUserProfile(ownerId);
            if (uRes['success'] == true && uRes['data'] is Map) {
              final uData = uRes['data'] as Map;
              if (!hasOwnerName) mutableSession['owner_name'] = uData['name'] ?? uData['display_name'];
              if (uData['avatar_urls'] is Map) {
                final urls = uData['avatar_urls'] as Map;
                mutableSession['owner_avatar'] = urls['96'] ?? urls['48'];
              }
            }
          }
        } catch (_) {}
      }
    }

    return mutableSession;
  }

  // ── Local Timezone Date & Time Helpers ─────────────────────────────────────

  /// Safely parses ISO or DB timestamp string into local DateTime.
  static DateTime parseLocalTime(String isoString) {
    String s = isoString.trim();
    if (!s.contains('Z') && !s.contains('+') && !s.contains('-')) {
      s = '${s.replaceAll(' ', 'T')}Z';
    }
    return DateTime.parse(s).toLocal();
  }

  /// Formats message time e.g. "5:43 PM".
  static String formatMessageTime(String? isoString) {
    if (isoString == null || isoString.trim().isEmpty) return '';
    try {
      final dt = parseLocalTime(isoString);
      final h = dt.hour;
      final m = dt.minute.toString().padLeft(2, '0');
      final period = h >= 12 ? 'PM' : 'AM';
      final hour12 = h % 12 == 0 ? 12 : h % 12;
      return '$hour12:$m $period';
    } catch (_) {
      return '';
    }
  }

  /// Formats date separator e.g. "Today", "Yesterday", "Thursday", "Thu, 12 Oct" or "12 Oct 2025".
  static String formatDateSeparator(String? isoString) {
    if (isoString == null || isoString.trim().isEmpty) return 'Today';
    try {
      final dt = parseLocalTime(isoString);
      final now = DateTime.now();

      final todayLocal = DateTime(now.year, now.month, now.day);
      final msgDateLocal = DateTime(dt.year, dt.month, dt.day);
      final daysDiff = todayLocal.difference(msgDateLocal).inDays;

      if (daysDiff == 0) return 'Today';
      if (daysDiff == 1) return 'Yesterday';

      const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      if (daysDiff > 1 && daysDiff < 7) {
        return weekdays[dt.weekday - 1];
      }

      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final monthName = months[dt.month - 1];

      if (dt.year == now.year) {
        return '${dt.day} $monthName';
      }
      return '${dt.day} $monthName ${dt.year}';
    } catch (_) {
      return 'Today';
    }
  }

  /// Formats list tile time e.g. "Just now", "5m ago", "2h ago", "Yesterday", "Thursday", "12 Oct".
  static String formatConversationTime(String? isoString) {
    if (isoString == null || isoString.trim().isEmpty) return '';
    try {
      final dt = parseLocalTime(isoString);
      final now = DateTime.now();

      final todayLocal = DateTime(now.year, now.month, now.day);
      final msgDateLocal = DateTime(dt.year, dt.month, dt.day);
      final daysDiff = todayLocal.difference(msgDateLocal).inDays;

      if (daysDiff == 0) {
        final diff = now.difference(dt);
        if (diff.inMinutes < 1) return 'Just now';
        if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
        return '${diff.inHours}h ago';
      }
      if (daysDiff == 1) return 'Yesterday';

      const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      if (daysDiff > 1 && daysDiff < 7) {
        return weekdays[dt.weekday - 1];
      }

      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final monthName = months[dt.month - 1];
      if (dt.year == now.year) {
        return '${dt.day} $monthName';
      }
      return '${dt.day} $monthName ${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

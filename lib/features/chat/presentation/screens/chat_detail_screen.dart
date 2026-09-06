import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../chat_helpers.dart';
import '../widgets/chat_shimmer.dart';
import '../../../home/presentation/screens/package_detail_screen.dart';


class ChatDetailScreen extends StatefulWidget {
  /// The chat session ID
  final int sessionId;

  /// Full session object (from list or startChatSession)
  final Map<String, dynamic> session;

  const ChatDetailScreen({
    super.key,
    required this.sessionId,
    required this.session,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _messages = [];
  final Map<dynamic, String> _localAttachmentCache = {};
  late Map<String, dynamic> _sessionData;

  bool _isLoadingMessages = true;
  bool _isSending = false;
  bool _isUploadingAttachment = false;
  bool _canSend = false;
  String? _errorMessage;

  XFile? _selectedAttachmentFile;
  Uint8List? _selectedAttachmentBytes;
  String? _selectedAttachmentName;

  // Polling timer for real-time simulation
  Timer? _pollTimer;
  int _lastMessageId = 0;

  @override
  void initState() {
    super.initState();
    _sessionData = Map<String, dynamic>.from(widget.session);
    _textController.addListener(_onTextChanged);
    _refreshSessionDetails();
    _loadMessages();
    _markRead();
    // Poll every 3 seconds for new messages & status updates
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _pollNewMessages();
    });
  }

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    final hasAttachment = _selectedAttachmentFile != null;
    final canSendNow = hasText || hasAttachment;
    if (canSendNow != _canSend) {
      setState(() {
        _canSend = canSendNow;
      });
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  // ── Session & Message Loading ─────────────────────────────────────────────

  Future<void> _refreshSessionDetails() async {
    try {
      final enrichedInitial = await ChatSessionHelper.enrichSessionData(_sessionData);
      if (mounted) {
        setState(() {
          _sessionData = enrichedInitial;
        });
      }

      final res = await ApiService.getChatSessionById(widget.sessionId);
      if (mounted && res['success'] == true && res['data'] is Map) {
        final fetched = Map<String, dynamic>.from(res['data'] as Map);
        final merged = <String, dynamic>{..._sessionData, ...fetched};
        final enrichedMerged = await ChatSessionHelper.enrichSessionData(merged);
        if (mounted) {
          setState(() {
            _sessionData = enrichedMerged;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadMessages() async {
    if (mounted) setState(() => _isLoadingMessages = true);
    try {
      final res = await ApiService.getChatMessages(widget.sessionId);
      if (!mounted) return;
      if (res['success'] == true && res['data'] is List) {
        final raw = (res['data'] as List<dynamic>)
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
        setState(() {
          _messages.clear();
          _messages.addAll(raw);
          _isLoadingMessages = false;
          _errorMessage = null;
          if (raw.isNotEmpty) {
            _lastMessageId =
                int.tryParse(raw.last['id']?.toString() ?? '0') ?? 0;
          }
        });
        _scrollToBottom();
      } else {
        setState(() {
          _isLoadingMessages = false;
          _errorMessage = res['message']?.toString() ?? 'Failed to load messages.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMessages = false;
          _errorMessage = 'Could not load messages.';
        });
      }
    }
  }

  /// Poll for messages newer than [_lastMessageId] without showing full loading.
  Future<void> _pollNewMessages() async {
    try {
      final res = await ApiService.getChatMessages(
        widget.sessionId,
        limit: 50,
        offset: 0,
      );
      if (!mounted) return;
      if (res['success'] == true && res['data'] is List) {
        final raw = (res['data'] as List<dynamic>)
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
        
        final newOnes = raw.where((m) {
          final id = int.tryParse(m['id']?.toString() ?? '0') ?? 0;
          return id > _lastMessageId;
        }).toList();

        if (newOnes.isNotEmpty) {
          setState(() {
            _messages.addAll(newOnes);
            _lastMessageId =
                int.tryParse(newOnes.last['id']?.toString() ?? '0') ?? _lastMessageId;
          });
          _scrollToBottom();
          _markRead();
        }
      }
    } catch (_) {}
  }

  Future<void> _markRead() async {
    try {
      await ApiService.markChatSessionRead(widget.sessionId);
    } catch (_) {}
  }

  // ── Sending & Attachments ──────────────────────────────────────────────────

  Future<void> _sendMessage(String text, {String? attachmentUrl, String messageType = 'text'}) async {
    if ((text.trim().isEmpty && (attachmentUrl == null || attachmentUrl.isEmpty)) || _isSending) return;
    
    // Check if session is closed
    if (_sessionData['status'] == 'closed') {
      CustomSnackBar.show(
        context,
        message: 'This session is closed. Reopen to send messages.',
        type: SnackBarType.warning,
      );
      return;
    }

    final String caption = text.trim();
    final String messageContent = caption.isNotEmpty
        ? caption
        : (messageType == 'image' ? '[Photo]' : (attachmentUrl != null && attachmentUrl.isNotEmpty ? '[Attachment]' : ''));

    _textController.clear();

    // Optimistic UI
    final optimisticId = -DateTime.now().millisecondsSinceEpoch;
    final optimistic = <String, dynamic>{
      'id': optimisticId,
      'sender_id': SessionManager.userId,
      'message': messageContent,
      'attachment_url': attachmentUrl,
      'message_type': messageType,
      'is_read': false,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      '_sending': true,
    };
    setState(() {
      _messages.add(optimistic);
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final res = await ApiService.sendChatMessage(
        widget.sessionId,
        message: messageContent,
        attachmentUrl: attachmentUrl,
        messageType: messageType,
      );
      if (!mounted) return;
      if (res['success'] == true && res['data'] != null) {
        final sent = Map<String, dynamic>.from(res['data'] as Map);
        if ((sent['attachment_url'] == null || sent['attachment_url'].toString().isEmpty) &&
            attachmentUrl != null &&
            attachmentUrl.isNotEmpty) {
          sent['attachment_url'] = attachmentUrl;
        }
        final sentId = sent['id'];
        if (sentId != null && attachmentUrl != null && attachmentUrl.isNotEmpty) {
          _localAttachmentCache[sentId] = attachmentUrl;
        }
        setState(() {
          final idx = _messages.indexWhere((m) => m['id'] == optimisticId);
          if (idx != -1) {
            _messages[idx] = sent;
          } else {
            _messages.add(sent);
          }
          _isSending = false;
          _lastMessageId = int.tryParse(sent['id']?.toString() ?? '0') ?? _lastMessageId;
        });
      } else {
        setState(() {
          _messages.removeWhere((m) => m['id'] == optimisticId);
          _isSending = false;
        });
        if (mounted) {
          CustomSnackBar.show(
            context,
            message: res['message']?.toString() ?? 'Failed to send message.',
            type: SnackBarType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m['id'] == optimisticId);
          _isSending = false;
        });
        CustomSnackBar.show(
          context,
          message: 'Could not send message. Please try again.',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _pickAttachment() async {
    if (_sessionData['status'] == 'closed' || _isSending || _isUploadingAttachment) return;

    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Attachment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontFamily: 'Recoleta Alt',
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE5ECFF),
                  child: Icon(Icons.photo_library_rounded, color: AppColors.primary),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE5ECFF),
                  child: Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                ),
                title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 80);
      if (image == null) return;

      final bytes = await image.readAsBytes();

      setState(() {
        _selectedAttachmentFile = image;
        _selectedAttachmentBytes = bytes;
        _selectedAttachmentName = image.name;
        _canSend = true;
      });
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Error selecting image.',
          type: SnackBarType.error,
        );
      }
    }
  }

  void _clearSelectedAttachment() {
    setState(() {
      _selectedAttachmentFile = null;
      _selectedAttachmentBytes = null;
      _selectedAttachmentName = null;
      _canSend = _textController.text.trim().isNotEmpty;
    });
  }

  Future<void> _handleSendPressed() async {
    if ((_textController.text.trim().isEmpty && _selectedAttachmentFile == null) || _isSending || _isUploadingAttachment) {
      return;
    }

    final String text = _textController.text.trim();

    if (_selectedAttachmentFile != null) {
      setState(() => _isUploadingAttachment = true);

      final uploadRes = await ApiService.uploadChatAttachment(
        widget.sessionId,
        _selectedAttachmentFile!.path,
        bytes: _selectedAttachmentBytes,
        fileName: _selectedAttachmentName,
      );

      if (!mounted) return;
      setState(() => _isUploadingAttachment = false);

      if (uploadRes['success'] == true && uploadRes['url'] != null && uploadRes['url'].toString().isNotEmpty) {
        final String uploadedUrl = uploadRes['url'].toString();
        final String msgType = uploadRes['message_type']?.toString() ?? 'image';

        _clearSelectedAttachment();
        await _sendMessage(text, attachmentUrl: uploadedUrl, messageType: msgType);
      } else {
        CustomSnackBar.show(
          context,
          message: uploadRes['message']?.toString() ?? 'Failed to upload attachment.',
          type: SnackBarType.error,
        );
      }
    } else {
      await _sendMessage(text);
    }
  }

  void _openFullScreenImage(String imageUrl) {
    if (imageUrl.isEmpty) return;
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: imageUrl.startsWith('data:image')
                  ? Image.memory(
                      base64Decode(imageUrl.split(',').last),
                      fit: BoxFit.contain,
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image_rounded, color: Colors.white70, size: 48),
                          SizedBox(height: 8),
                          Text('Image failed to load', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPackageDetail() {
    final rawPkg = _sessionData['package'];
    final packageId = _sessionData['package_id'] ?? (rawPkg is Map ? rawPkg['id'] : null);

    if (packageId == null) {
      CustomSnackBar.show(
        context,
        message: 'Package details unavailable.',
        type: SnackBarType.warning,
      );
      return;
    }

    final Map<String, dynamic> pkgMap = rawPkg is Map
        ? Map<String, dynamic>.from(rawPkg)
        : {'id': packageId, 'title': ChatSessionHelper.resolvePackageTitle(_sessionData)};

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PackageDetailScreen(package: pkgMap),
      ),
    );
  }

  // ── Message Deletion (DEL /chat/messages/{id}) ─────────────────────────────

  Future<void> _confirmDeleteMessage(Map<String, dynamic> msg) async {
    final msgId = int.tryParse(msg['id']?.toString() ?? '0') ?? 0;
    if (msgId <= 0) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await ApiService.deleteChatMessage(msgId);
      if (!mounted) return;
      if (res['success'] == true) {
        setState(() {
          _messages.removeWhere((m) => m['id'] == msgId);
        });
        CustomSnackBar.show(
          context,
          message: 'Message deleted.',
          type: SnackBarType.success,
        );
      } else {
        CustomSnackBar.show(
          context,
          message: res['message']?.toString() ?? 'Could not delete message.',
          type: SnackBarType.error,
        );
      }
    } catch (_) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Failed to delete message.',
          type: SnackBarType.error,
        );
      }
    }
  }

  // ── Session Close / Reopen (POST /chat/sessions/{id}/close & reopen) ───────

  @pragma('vm:entry-point')
  Future<void> _closeSession() async {
    String selectedReason = 'successful_sale';
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: StatefulBuilder(
            builder: (context, setDlgState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_person_outlined, color: Colors.red, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Close Chat Session',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontFamily: 'Recoleta Alt',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Select the reason for closing this conversation with the customer:',
                  style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedReason,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                      items: const [
                        DropdownMenuItem(
                          value: 'successful_sale',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                              SizedBox(width: 10),
                              Text('Successful Sale', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'not_interested',
                          child: Row(
                            children: [
                              Icon(Icons.highlight_off, size: 18, color: Colors.orange),
                              SizedBox(width: 10),
                              Text('Not Interested', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'spam',
                          child: Row(
                            children: [
                              Icon(Icons.report_gmailerrorred, size: 18, color: Colors.red),
                              SizedBox(width: 10),
                              Text('Spam or Fraudulent', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'other',
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: Colors.blue),
                              SizedBox(width: 10),
                              Text('Other Reason', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setDlgState(() => selectedReason = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Side-by-side action buttons in 1 row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                          side: const BorderSide(color: Colors.black26),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Cancel',
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, selectedReason),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 46),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Close Session',
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == null) return;

    final res = await ApiService.closeChatSession(widget.sessionId, reason: result);
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _sessionData['status'] = 'closed';
      });
      CustomSnackBar.show(
        context,
        message: 'Chat session closed successfully.',
        type: SnackBarType.info,
      );
    } else {
      CustomSnackBar.show(
        context,
        message: res['message']?.toString() ?? 'Could not close session.',
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _reopenSession() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_open_rounded, color: Colors.green, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Reopen Chat Session',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontFamily: 'Recoleta Alt',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Are you sure you want to reopen this chat session? This will allow new messages to be sent and received.',
                style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
              ),
              const SizedBox(height: 24),
              // Side-by-side action buttons in 1 row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                        side: const BorderSide(color: Colors.black26),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Cancel',
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Reopen Session',
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    final res = await ApiService.reopenChatSession(widget.sessionId);
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _sessionData['status'] = 'active';
      });
      CustomSnackBar.show(
        context,
        message: 'Chat session reopened successfully.',
        type: SnackBarType.success,
      );
    } else {
      CustomSnackBar.show(
        context,
        message: res['message']?.toString() ?? 'Could not reopen session.',
        type: SnackBarType.error,
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build UI ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final session = _sessionData;
    final packageTitle = ChatSessionHelper.resolvePackageTitle(session);
    final otherName = ChatSessionHelper.resolveOtherPartyName(session);
    final isClosed = session['status'] == 'closed';
    final isOwner = _isCurrentOwner(session);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            _buildAppBarAvatar(session),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          otherName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (isClosed) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Closed',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    packageTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.primary.withValues(alpha: 0.55),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Eye button -> Navigates directly to Package Details screen
          IconButton(
            icon: const Icon(Icons.remove_red_eye_outlined, color: AppColors.primary, size: 24),
            tooltip: 'View Package Details',
            onPressed: _openPackageDetail,
          ),
          /*
          // 3-Dots Popup Menu (Commented out per user request)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.primary),
            onSelected: (val) {
              if (val == 'close') _closeSession();
              if (val == 'reopen') _reopenSession();
              if (val == 'refresh') {
                _loadMessages();
                _refreshSessionDetails();
              }
            },
            itemBuilder: (ctx) => [
              if (isOwner && !isClosed)
                const PopupMenuItem(
                  value: 'close',
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline, size: 18, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Close Session'),
                    ],
                  ),
                ),
              if (isOwner && isClosed)
                const PopupMenuItem(
                  value: 'reopen',
                  child: Row(
                    children: [
                      Icon(Icons.lock_open, size: 18, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Reopen Session'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Refresh Chat'),
                  ],
                ),
              ),
            ],
          ),
          */
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Package context card
            _buildPackageCard(session),

            if (isClosed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.orange.shade100,
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: Colors.deepOrange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isOwner
                            ? 'This session is closed. Tap menu to reopen.'
                            : 'This chat session has been closed by the seller.',
                        style: const TextStyle(fontSize: 12, color: Colors.brown, fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (isOwner)
                      TextButton(
                        onPressed: _reopenSession,
                        child: const Text('Reopen', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),

            // Messages area
            Expanded(
              child: _isLoadingMessages
                  ? const ChatDetailSkeleton()
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _messages.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              controller: _scrollController,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.all(16.0),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final msg = _messages[index];
                                final isMe = int.tryParse(
                                            msg['sender_id']?.toString() ?? '') ==
                                        SessionManager.userId;

                                Widget bubble = GestureDetector(
                                  onLongPress: isMe && msg['_sending'] != true
                                      ? () => _confirmDeleteMessage(msg)
                                      : null,
                                  child: _buildMessageBubble(msg, isMe),
                                );

                                if (index == 0) {
                                  return Column(
                                    children: [
                                      _buildDateSeparator(msg['created_at']),
                                      bubble,
                                    ],
                                  );
                                }

                                final prevDate = _parseDate(_messages[index - 1]['created_at']);
                                final currDate = _parseDate(msg['created_at']);
                                if (prevDate != currDate) {
                                  return Column(
                                    children: [
                                      _buildDateSeparator(msg['created_at']),
                                      bubble,
                                    ],
                                  );
                                }
                                return bubble;
                              },
                            ),
            ),

            // Input bar
            _buildInputBar(isClosed: isClosed),
          ],
        ),
      ),
    );
  }

  // ── Sub-widgets ───────────────────────────────────────────────────────────

  Widget _buildAppBarAvatar(Map<String, dynamic> session) {
    final String rawAvatarUrl = ChatSessionHelper.resolveOtherPartyAvatar(session);
    final String avatarUrl = ApiService.unescapeHtml(rawAvatarUrl).trim();
    final String otherName = ChatSessionHelper.resolveOtherPartyName(session);
    final String initial = otherName.isNotEmpty ? otherName[0].toUpperCase() : 'U';

    return Stack(
      children: [
        if (avatarUrl.isNotEmpty && avatarUrl.startsWith('http'))
          ClipOval(
            child: Image.network(
              avatarUrl,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE5ECFF),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Color(0xFF1E56B3),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          )
        else
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE5ECFF),
            child: Text(
              initial,
              style: const TextStyle(
                color: Color(0xFF1E56B3),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: session['status'] == 'closed' ? Colors.grey : const Color(0xFF4CAF50),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> session) {
    final title = ChatSessionHelper.resolvePackageTitle(session);
    final thumb = ChatSessionHelper.resolvePackageThumbnail(session);
    final packageId = session['package_id']?.toString() ?? session['package']?['id']?.toString() ?? '';

    return GestureDetector(
      onTap: _openPackageDetail,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: thumb.isNotEmpty && thumb.startsWith('http')
                    ? Image.network(
                        thumb,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _packageIconFallback(),
                      )
                    : _packageIconFallback(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Package #${packageId.isNotEmpty ? packageId : 'Detail'}',
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Active Chat',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _packageIconFallback() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.shopping_bag_outlined, size: 22, color: Colors.black38),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 52, color: Color(0x1F1F2E4E)),
          SizedBox(height: 12),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0x591F2E4E),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Start the conversation!',
            style: TextStyle(fontSize: 12, color: Color(0x401F2E4E)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 40, color: Colors.black26),
          const SizedBox(height: 12),
          Text(_errorMessage!,
              style: const TextStyle(fontSize: 13, color: Colors.black45)),
          const SizedBox(height: 14),
          TextButton(
            onPressed: _loadMessages,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(String? isoString) {
    final label = ChatSessionHelper.formatDateSeparator(isoString);
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }

  String _resolveAttachmentUrl(Map<String, dynamic> msg) {
    if (msg['attachment_url'] != null && msg['attachment_url'].toString().isNotEmpty) {
      return msg['attachment_url'].toString();
    }
    if (msg['attachment'] != null) {
      if (msg['attachment'] is String && msg['attachment'].toString().isNotEmpty) {
        return msg['attachment'].toString();
      }
      if (msg['attachment'] is Map && msg['attachment']['url'] != null) {
        return msg['attachment']['url'].toString();
      }
    }
    if (msg['image_url'] != null && msg['image_url'].toString().isNotEmpty) {
      return msg['image_url'].toString();
    }
    if (msg['file_url'] != null && msg['file_url'].toString().isNotEmpty) {
      return msg['file_url'].toString();
    }
    if (msg['url'] != null && msg['url'].toString().isNotEmpty) {
      return msg['url'].toString();
    }
    final msgId = msg['id'];
    if (msgId != null && _localAttachmentCache.containsKey(msgId)) {
      return _localAttachmentCache[msgId]!;
    }
    final msgText = (msg['message'] ?? '').toString().trim();
    if (msgText.startsWith('http://') || msgText.startsWith('https://') || msgText.startsWith('data:image')) {
      return msgText;
    }
    return '';
  }

  Widget _imageErrorFallback() {
    return Container(
      width: 220,
      height: 140,
      color: Colors.black12,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_rounded, color: Colors.black45, size: 36),
          SizedBox(height: 4),
          Text('Image unavailable', style: TextStyle(fontSize: 11, color: Colors.black45)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    final text = (msg['message'] ?? '').toString();
    final isSending = msg['_sending'] == true;
    final isRead = msg['is_read'] == true;
    final timeStr = _formatTime(msg['created_at']?.toString());
    final attachmentUrl = _resolveAttachmentUrl(msg);
    final msgType = (msg['message_type'] ?? (attachmentUrl.isNotEmpty ? 'image' : 'text')).toString();
    final bool isImageBubble = msgType == 'image' || attachmentUrl.startsWith('data:image') || attachmentUrl.startsWith('http');

    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              _buildSenderAvatar(msg),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72),
                padding: isImageBubble
                    ? const EdgeInsets.all(4)
                    : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFF1F2E4E) : const Color(0xFFECEFF1),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 0),
                    bottomRight: Radius.circular(isMe ? 0 : 16),
                  ),
                ),
                child: _buildMessageContent(text, attachmentUrl, msgType, isMe),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Padding(
          padding: EdgeInsets.only(
            left: isMe ? 0 : 42.0,
            right: isMe ? 4.0 : 0,
            bottom: 10.0,
          ),
          child: Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(
                timeStr,
                style: const TextStyle(fontSize: 10, color: Colors.black38),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                isSending
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                            strokeWidth: 1.5, color: Colors.black38),
                      )
                    : Icon(
                        isRead ? Icons.done_all : Icons.check,
                        color: isRead ? const Color(0xFF4CAF50) : Colors.black38,
                        size: 14,
                      ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageContent(
      String text, String rawAttachmentUrl, String msgType, bool isMe) {
    final String attachmentUrl = rawAttachmentUrl.trim();
    final String finalUrl = attachmentUrl.isNotEmpty
        ? attachmentUrl
        : ((text.startsWith('data:image') || text.startsWith('http://') || text.startsWith('https://')) ? text : '');

    final bool isImageAttachment = (msgType == 'image') ||
        finalUrl.startsWith('data:image') ||
        finalUrl.startsWith('http://') ||
        finalUrl.startsWith('https://');

    if (isImageAttachment && finalUrl.isNotEmpty) {
      Widget imageWidget;
      if (finalUrl.startsWith('data:image')) {
        try {
          final base64Bytes = base64Decode(finalUrl.split(',').last);
          imageWidget = Image.memory(
            base64Bytes,
            width: 220,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _imageErrorFallback(),
          );
        } catch (_) {
          imageWidget = _imageErrorFallback();
        }
      } else {
        imageWidget = Image.network(
          finalUrl,
          width: 220,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _imageErrorFallback(),
        );
      }

      final bool showCaption = text.isNotEmpty &&
          text != '[Photo]' &&
          text != '[Attachment]' &&
          !text.startsWith('data:image') &&
          !text.startsWith('http://') &&
          !text.startsWith('https://');

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _openFullScreenImage(finalUrl),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageWidget,
            ),
          ),
          if (showCaption) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : AppColors.primary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      );
    }
    if (msgType == 'file' && attachmentUrl.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.attach_file_rounded,
                  size: 18, color: isMe ? Colors.white70 : Colors.black54),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  text.isNotEmpty ? text : 'Attachment File',
                  style: TextStyle(
                      color: isMe ? Colors.white : AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        ],
      );
    }
    return Text(
      text,
      style: TextStyle(
        color: isMe ? Colors.white : AppColors.primary,
        fontSize: 14,
        height: 1.4,
      ),
    );
  }

  Widget _buildSenderAvatar(Map<String, dynamic> msg) {
    String rawAvatar = (msg['sender']?['avatar'] ?? msg['sender']?['avatar_url'] ?? msg['sender_avatar'] ?? msg['sender_photo'] ?? '').toString();
    if (rawAvatar.isEmpty || !rawAvatar.startsWith('http')) {
      rawAvatar = ChatSessionHelper.resolveOtherPartyAvatar(_sessionData);
    }
    final String senderAvatar = ApiService.unescapeHtml(rawAvatar).trim();
    final String senderName = (msg['sender']?['name'] ?? ChatSessionHelper.resolveOtherPartyName(_sessionData)).toString();
    final initial = senderName.isNotEmpty ? senderName[0].toUpperCase() : 'U';

    if (senderAvatar.isNotEmpty && senderAvatar.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          senderAvatar,
          width: 28,
          height: 28,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFFE5ECFF),
            child: Text(
              initial,
              style: const TextStyle(
                  color: Color(0xFF1E56B3), fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 14,
      backgroundColor: const Color(0xFFE5ECFF),
      child: Text(
        initial,
        style: const TextStyle(
            color: Color(0xFF1E56B3), fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Widget _buildAttachmentPreviewCard() {
    if (_selectedAttachmentFile == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5ECFF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _selectedAttachmentBytes != null
                ? Image.memory(
                    _selectedAttachmentBytes!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 52,
                    height: 52,
                    color: const Color(0xFFE5ECFF),
                    child: const Icon(Icons.image, color: AppColors.primary),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _selectedAttachmentName ?? 'Selected Attachment',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.black45, size: 20),
            onPressed: _clearSelectedAttachment,
            tooltip: 'Remove Attachment',
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar({bool isClosed = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAttachmentPreviewCard(),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            children: [
              // Attachment Button (Paperclip)
              IconButton(
                icon: Icon(
                  Icons.attach_file_rounded,
                  color: isClosed ? Colors.grey : AppColors.primary,
                  size: 24,
                ),
                onPressed: isClosed || _isUploadingAttachment || _isSending ? null : _pickAttachment,
              ),
              const SizedBox(width: 4),
              // Expanded text input
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAEAEA).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _textController,
                    enabled: !isClosed,
                    style: const TextStyle(fontSize: 14),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: isClosed ? 'Session is closed' : 'Type a message...',
                      hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Send button
              Builder(
                builder: (context) {
                  final bool isSendEnabled = !isClosed && !_isSending && !_isUploadingAttachment && _canSend;
                  return GestureDetector(
                    onTap: isSendEnabled ? _handleSendPressed : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSendEnabled ? const Color(0xFF7F7DF4) : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: (_isSending || _isUploadingAttachment)
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(
                              Icons.send_rounded,
                              color: isSendEnabled ? Colors.white : Colors.white.withValues(alpha: 0.6),
                              size: 20,
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool _isCurrentOwner(Map<String, dynamic> session) {
    final myId = SessionManager.userId;
    final ownerId = int.tryParse(session['owner_id']?.toString() ?? '');
    return myId != null && ownerId != null && myId == ownerId;
  }



  String _parseDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.year}-${dt.month}-${dt.day}';
    } catch (_) {
      return '';
    }
  }

  String _formatTime(String? isoString) {
    return ChatSessionHelper.formatMessageTime(isoString);
  }
}

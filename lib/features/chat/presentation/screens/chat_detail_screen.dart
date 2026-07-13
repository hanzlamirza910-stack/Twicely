import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_snackbar.dart';

class ChatDetailScreen extends StatefulWidget {
  final String name;
  final String avatar;
  final bool isImage;
  final String initialMessage;

  const ChatDetailScreen({
    super.key,
    required this.name,
    required this.avatar,
    required this.isImage,
    required this.initialMessage,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Load default mockup conversation matching the Figma mockup
    _messages.addAll([
      {
        'text': 'Hello! I saw your interest in the Clay Pitcher. Just to let you know, it\'s hand-fired using local earth from the Tuscan hills.',
        'time': '09:42 AM',
        'isMe': false,
      },
      {
        'text': 'That sounds beautiful. Is the glaze lead-free? I\'m looking for daily use pieces for my home.',
        'time': '09:45 AM',
        'isMe': true,
        'status': 'read',
      },
      {
        'text': 'Yes, absolutely. All our glazes are certified food-safe and lead-free. We use a traditional kiln firing method that ensures durability for daily use.',
        'time': '09:47 AM',
        'isMe': false,
      },
    ]);
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

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';

    setState(() {
      _messages.add({
        'text': text,
        'time': timeStr,
        'isMe': true,
        'status': 'sent',
      });
    });

    _textController.clear();
    _scrollToBottom();

    // Simulate typing and reply
    setState(() {
      _isTyping = true;
    });

    Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      
      String replyText = 'That\'s awesome! Let me know if you have any other questions or if you want to proceed. 😊';
      if (text.contains('shipping') || text.contains('ship')) {
        replyText = 'Standard shipping is S\$5.00 within Singapore, or we can arrange self-pickup at Orchard!';
      } else if (text.contains('kiln') || text.contains('clay')) {
        replyText = 'The kiln is fired up to 1200°C which vitrifies the clay fully, making it oven and dishwasher safe!';
      }

      setState(() {
        _isTyping = false;
        _messages.add({
          'text': replyText,
          'time': timeStr,
          'isMe': false,
        });
      });
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EA), // Warm cream background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                _buildAvatarWidget(),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Active now',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Product contextual card
            _buildProductCard(),

            // Chat Messages area
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isMe = msg['isMe'] as bool;
                  if (index == 0) {
                    return Column(
                      children: [
                        Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Today',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black45,
                              ),
                            ),
                          ),
                        ),
                        _buildMessageBubble(msg, isMe),
                      ],
                    );
                  }
                  return _buildMessageBubble(msg, isMe);
                },
              ),
            ),

            if (_isTyping) ...[
              Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                child: Row(
                  children: [
                    Text(
                      '${widget.name} is typing...',
                      style: const TextStyle(fontSize: 11, color: Colors.black38, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],

            // Quick reply pills
            _buildQuickRepliesRow(),

            // Bottom Input bar
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarWidget() {
    if (widget.isImage) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: AssetImage(widget.avatar),
      );
    } else {
      return CircleAvatar(
        radius: 18,
        backgroundColor: const Color(0xFFE5ECFF),
        child: Text(
          widget.avatar,
          style: const TextStyle(color: Color(0xFF1E56B3), fontWeight: FontWeight.bold, fontSize: 11),
        ),
      );
    }
  }

  Widget _buildProductCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
              child: Image.asset(
                'assets/images/clay_pitcher.png',
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 44,
                  height: 44,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Artisanal Clay Pitcher',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Sustainable Edit • \$125.00',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                CustomSnackBar.show(
                  context,
                  message: 'Viewing item details...',
                  type: SnackBarType.info,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2E4E), // Navy blue
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  'View',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF1F2E4E) : const Color(0xFFECEFF1),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 0),
                  bottomRight: Radius.circular(isMe ? 0 : 16),
                ),
              ),
              child: Text(
                msg['text'] as String,
                style: TextStyle(
                  color: isMe ? Colors.white : AppColors.primary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: EdgeInsets.only(
            left: isMe ? 0 : 4.0,
            right: isMe ? 4.0 : 0,
            bottom: 12.0,
          ),
          child: Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(
                msg['time'] as String,
                style: const TextStyle(fontSize: 10, color: Colors.black38),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                const Icon(Icons.done_all, color: Colors.green, size: 14),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickRepliesRow() {
    final suggestions = ['Is shipping included?', 'Tell me more about the kiln.'];
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: GestureDetector(
              onTap: () => _sendMessage(suggestions[index]),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0DFDA).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  suggestions[index],
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2E4E),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      child: Row(
        children: [
          // Plus button
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.black45, size: 24),
            onPressed: () {},
          ),
          // Input field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEAEAEA).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.black38, fontSize: 13),
                        border: InputBorder.none,
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.sentiment_satisfied_alt_rounded, color: Colors.black38, size: 22),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          GestureDetector(
            onTap: () => _sendMessage(_textController.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF7F7DF4), // Lavender/purple send button
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add({
      'sender': 'bot',
      'text': 'Hello! I\'m QuickFix Assistant 🤖. I can help you book emergency home repairs, track technicians, or answer questions about our services. What do you need help with?',
      'time': DateTime.now(),
      'context': 'greeting',
    });
  }

  // Send message to chatbot
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'sender': 'user',
        'text': text,
        'time': DateTime.now(),
      });
      _controller.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      final response = await Api.sendChatMessage(text);

      if (response != null && mounted) {
        setState(() {
          _messages.add({
            'sender': 'bot',
            'text': response['message'] ?? 'I apologize, I didn\'t understand that. Can you rephrase?',
            'time': DateTime.now(),
            'context': response['intent'],
            'serviceType': response['serviceType'],
            'priority': response['priority'],
          });
          _isTyping = false;
        });
      } else {
        setState(() {
          _messages.add({
            'sender': 'bot',
            'text': 'Sorry, I\'m having trouble connecting. Please try again.',
            'time': DateTime.now(),
          });
          _isTyping = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'bot',
          'text': 'An error occurred. Please try again later.',
          'time': DateTime.now(),
        });
        _isTyping = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isUser = msg['sender'] == 'user';
    final formattedTime = DateFormat('hh:mm a').format(msg['time']);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: isUser ? const Radius.circular(14) : const Radius.circular(0),
            bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(14),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg['text'],
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              formattedTime,
              style: TextStyle(
                color: isUser ? Colors.white70 : Colors.black45,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typingIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Dot(),
              SizedBox(width: 3),
              Dot(delay: Duration(milliseconds: 150)),
              SizedBox(width: 3),
              Dot(delay: Duration(milliseconds: 300)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return _typingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class Dot extends StatefulWidget {
  final Duration delay;
  const Dot({super.key, this.delay = Duration.zero});

  @override
  State<Dot> createState() => _DotState();
}

class _DotState extends State<Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _animation = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: const CircleAvatar(radius: 3, backgroundColor: Colors.black54),
    );
  }
}

import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_header.dart';
import '../chatbot_screen.dart';

class TechChatbotScreen extends StatelessWidget {
  const TechChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'AI Assistant',
            subtitle: 'Get help with your work',
            icon: Icons.chat_bubble,
            gradientColors: [AppTheme.accentPurple, AppTheme.accentPurple.withValues(alpha: 0.7)],
          ),
          const Expanded(
            child: ChatbotScreen(),
          ),
        ],
      ),
    );
  }
}

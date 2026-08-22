import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/chat_model.dart';
import '../theme/theme_controller.dart';
import '../utils/constants.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isCurrentUser;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isCurrentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
        child: Column(
          crossAxisAlignment: isCurrentUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isCurrentUser)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Text(
                  'DermaAI',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            if (message.imagePath != null && message.imagePath!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(message.imagePath!),
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isCurrentUser ? AppColors.userBubble : AppColors.aiBubble,
                borderRadius: BorderRadius.circular(18),
                border: isCurrentUser
                    ? null
                    : Border.all(color: AppColors.border, width: 1.4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: AppTextStyles.bodyText.copyWith(
                      color: isCurrentUser ? Colors.white : AppColors.textLight,
                    ),
                  ),
                  if (message.prediction != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCurrentUser
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.prediction!.diseaseName,
                              style: AppTextStyles.caption.copyWith(
                                color: isCurrentUser
                                    ? Colors.white
                                    : AppColors.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(message.prediction!.confidence * 100).toStringAsFixed(1)}% confidence',
                              style: AppTextStyles.caption.copyWith(
                                color: isCurrentUser
                                    ? Colors.white70
                                    : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 5, left: 4, right: 4),
              child: Text(
                DateFormat('HH:mm').format(message.timestamp),
                style: AppTextStyles.caption.copyWith(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({Key? key}) : super(key: key);

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      )..repeat(reverse: true);
    });

    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].forward(from: (i * 0.2) % 1.0);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.small,
        horizontal: AppSpacing.normal,
      ),
      child: Row(
        children: List.generate(3, (index) {
          return ScaleTransition(
            scale: Tween<double>(
              begin: 0.5,
              end: 1.0,
            ).animate(_controllers[index]),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: AppColors.muted,
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      ),
    );
  }
}

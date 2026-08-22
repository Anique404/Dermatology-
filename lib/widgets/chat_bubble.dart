import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_model.dart';
import '../utils/constants.dart';

// ============================================
// CHAT BUBBLE WIDGET
// ============================================
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
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.small,
          horizontal: AppSpacing.normal,
        ),
        child: Column(
          crossAxisAlignment: isCurrentUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Image preview if exists
            if (message.imagePath != null && message.imagePath!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.small),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppBorderRadius.normal),
                  child: Image.file(
                    File(message.imagePath!),
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            // Message bubble
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(AppSpacing.normal),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? AppColors.primaryColor
                    : AppColors.secondaryBg,
                borderRadius: BorderRadius.circular(AppBorderRadius.normal),
              ),
              child: Column(
                crossAxisAlignment: isCurrentUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: AppTextStyles.bodyText.copyWith(
                      color: isCurrentUser ? Colors.white : AppColors.textLight,
                    ),
                  ),
                  // Prediction if exists
                  if (message.prediction != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.normal),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.small),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.small,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: isCurrentUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Disease: ${message.prediction!.diseaseName}',
                              style: AppTextStyles.caption.copyWith(
                                color: isCurrentUser
                                    ? Colors.white
                                    : AppColors.accentTeal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Confidence: ${(message.prediction!.confidence * 100).toStringAsFixed(2)}%',
                              style: AppTextStyles.caption.copyWith(
                                color: isCurrentUser
                                    ? Colors.white70
                                    : AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Timestamp
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.small),
              child: Text(
                DateFormat('HH:mm').format(message.timestamp),
                style: AppTextStyles.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// TYPING INDICATOR WIDGET
// ============================================
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
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.accentTeal,
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      ),
    );
  }
}

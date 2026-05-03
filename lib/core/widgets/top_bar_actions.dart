import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class NotificationBadgeButton extends StatefulWidget {
  const NotificationBadgeButton({super.key, required this.onPressed});

  final FutureOr<void> Function() onPressed;

  @override
  State<NotificationBadgeButton> createState() =>
      _NotificationBadgeButtonState();
}

class _NotificationBadgeButtonState extends State<NotificationBadgeButton> {
  late Future<int> _unreadFuture;

  @override
  void initState() {
    super.initState();
    _unreadFuture = NotificationService.instance.getUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _unreadFuture,
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: InkWell(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: -7,
                      top: -8,
                      child: _UnreadBadge(count: unreadCount),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleTap() async {
    await widget.onPressed();
    if (!mounted) return;
    setState(() {
      _unreadFuture = NotificationService.instance.getUnreadCount();
    });
  }
}

class MobileNotificationBadgeButton extends StatefulWidget {
  const MobileNotificationBadgeButton({super.key, required this.onPressed});

  final FutureOr<void> Function() onPressed;

  @override
  State<MobileNotificationBadgeButton> createState() =>
      _MobileNotificationBadgeButtonState();
}

class _MobileNotificationBadgeButtonState
    extends State<MobileNotificationBadgeButton> {
  late Future<int> _unreadFuture;

  @override
  void initState() {
    super.initState();
    _unreadFuture = NotificationService.instance.getUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _unreadFuture,
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        return IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: AppColors.textSecondary,
                size: 22,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -8,
                  top: -8,
                  child: _UnreadBadge(count: unreadCount),
                ),
            ],
          ),
          onPressed: _handleTap,
        );
      },
    );
  }

  Future<void> _handleTap() async {
    await widget.onPressed();
    if (!mounted) return;
    setState(() {
      _unreadFuture = NotificationService.instance.getUnreadCount();
    });
  }
}

class ProfileAvatarButton extends StatelessWidget {
  const ProfileAvatarButton({
    super.key,
    required this.initials,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
    this.radius = 18,
    this.padding = EdgeInsets.zero,
  });

  final String initials;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: padding,
            child: CircleAvatar(
              radius: radius,
              backgroundColor: backgroundColor,
              child: Text(
                initials,
                style: AppTextStyles.caption.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.surface, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTextStyles.overline.copyWith(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

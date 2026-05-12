import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/notifications/providers/notification_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_avatar.dart';

class NotificationBadgeButton extends ConsumerWidget {
  const NotificationBadgeButton({super.key, required this.onPressed});

  final FutureOr<void> Function() onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsProvider).valueOrNull ?? 0;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () async {
          await onPressed();
          ref.read(unreadNotificationsProvider.notifier).refresh();
        },
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
              Icon(
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
  }
}

class MobileNotificationBadgeButton extends ConsumerWidget {
  const MobileNotificationBadgeButton({super.key, required this.onPressed});

  final FutureOr<void> Function() onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsProvider).valueOrNull ?? 0;
    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
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
      onPressed: () async {
        await onPressed();
        ref.read(unreadNotificationsProvider.notifier).refresh();
      },
    );
  }
}

class ProfileAvatarButton extends StatelessWidget {
  const ProfileAvatarButton({
    super.key,
    required this.initials,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
    this.avatarUrl,
    this.radius = 18,
    this.padding = EdgeInsets.zero,
  });

  final String initials;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;
  final String? avatarUrl;
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
            child: AppAvatar(
              radius: radius,
              avatarUrl: avatarUrl,
              initials: initials,
              backgroundColor: backgroundColor,
              textColor: textColor,
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

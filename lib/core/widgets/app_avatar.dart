import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.initials,
    required this.backgroundColor,
    required this.textColor,
    this.avatarUrl,
    this.radius = 18,
    this.borderColor,
  });

  final String initials;
  final String? avatarUrl;
  final Color backgroundColor;
  final Color textColor;
  final double radius;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final url = avatarUrl?.trim();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null || url.isEmpty
          ? _FallbackAvatar(
              initials: initials,
              backgroundColor: backgroundColor,
              textColor: textColor,
              radius: radius,
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _FallbackAvatar(
                initials: initials,
                backgroundColor: backgroundColor,
                textColor: textColor,
                radius: radius,
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return _FallbackAvatar(
                  initials: initials,
                  backgroundColor: backgroundColor,
                  textColor: textColor,
                  radius: radius,
                  showLoading: true,
                );
              },
            ),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({
    required this.initials,
    required this.backgroundColor,
    required this.textColor,
    required this.radius,
    this.showLoading = false,
  });

  final String initials;
  final Color backgroundColor;
  final Color textColor;
  final double radius;
  final bool showLoading;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: Center(
        child: showLoading
            ? SizedBox(
                width: radius,
                height: radius,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textColor,
                ),
              )
            : Text(
                initials,
                style: AppTextStyles.caption.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: radius <= 16 ? 11 : radius * 0.72,
                ),
              ),
      ),
    );
  }
}

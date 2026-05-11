import 'package:flutter/material.dart';

/// Reusable user avatar with a first-letter fallback when no image is available.
class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double radius;
  final Color backgroundColor;
  final Color textColor;
  final TextStyle? textStyle;

  const UserAvatar({
    super.key,
    required this.avatarUrl,
    required this.name,
    required this.radius,
    required this.backgroundColor,
    required this.textColor,
    this.textStyle,
  });

  bool get _hasValidAvatar {
    final raw = avatarUrl?.trim();
    if (raw == null || raw.isEmpty) return false;
    final uri = Uri.tryParse(raw);
    if (uri == null) return false;
    final scheme = uri.scheme.toLowerCase();
    return scheme == 'http' || scheme == 'https';
  }

  String get _initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  Widget _fallback() {
    return Center(
      child: Text(
        _initial,
        style:
            textStyle ??
            TextStyle(color: textColor, fontWeight: FontWeight.w700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(shape: BoxShape.circle, color: backgroundColor),
      clipBehavior: Clip.antiAlias,
      child: _hasValidAvatar
          ? Image.network(
              avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(),
            )
          : _fallback(),
    );
  }
}

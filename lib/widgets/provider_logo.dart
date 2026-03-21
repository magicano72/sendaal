import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Circular provider logo that resolves Directus asset UUIDs to full URLs.
/// Falls back to an initial/placeholder when missing or on load error.
class ProviderLogo extends StatelessWidget {
  final String? logoUuid;
  final String? providerName;
  final double size;

  const ProviderLogo({
    super.key,
    required this.logoUuid,
    this.providerName,
    this.size = 40,
  });

  String? get _url =>
      logoUuid == null || logoUuid!.isEmpty
          ? null
          : 'https://sendaal-directus.csiwm3.easypanel.host/assets/$logoUuid';

  @override
  Widget build(BuildContext context) {
    final url = _url;
    final radius = size / 2;

    if (url == null) {
      return _placeholder(radius);
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _placeholder(radius),
        placeholder: (_, __) => _placeholder(radius, isLoading: true),
      ),
    );
  }

  Widget _placeholder(double radius, {bool isLoading = false}) {
    final initial = (providerName?.trim().isNotEmpty ?? false)
        ? providerName!.trim()[0].toUpperCase()
        : null;
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE0E0E0),
      child: isLoading
          ? SizedBox(
              width: radius,
              height: radius,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textSecondary),
              ),
            )
          : initial != null
              ? Text(
                  initial,
                  style: const TextStyle(
                    color: Color(0xFF616161),
                    fontWeight: FontWeight.w700,
                  ),
                )
              : const Icon(Icons.account_balance, color: Color(0xFF616161)),
    );
  }
}

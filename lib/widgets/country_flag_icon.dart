import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';

/// Circle flag with fallback for missing/unknown codes.
class CountryFlagIcon extends StatelessWidget {
  final String? countryCode;
  final double size;

  const CountryFlagIcon({super.key, this.countryCode, this.size = 24});

  String? _normalized() {
    if (countryCode == null || countryCode!.isEmpty) return null;
    final code = countryCode!.toUpperCase();
    if (code == 'UK') return 'GB';
    return code;
  }

  @override
  Widget build(BuildContext context) {
    final code = _normalized();
    if (code == null) return _placeholder();
    return CountryFlag.fromCountryCode(
      code,
      width: size,
      height: size,
      shape: const Circle(),
    );
  }

  Widget _placeholder() => CircleAvatar(
        radius: size / 2,
        backgroundColor: const Color(0xFFE0E0E0),
      );
}

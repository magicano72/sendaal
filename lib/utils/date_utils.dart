/// Parses a Directus UTC datetime string and converts to device local time.
/// Directus returns timestamps without 'Z' suffix — we append it to mark as UTC.
DateTime? parseDirectusDate(String? dateStr) {
  if (dateStr == null) return null;
  try {
    // Append 'Z' if not already present to mark as UTC
    final normalized = dateStr.endsWith('Z') ? dateStr : '${dateStr}Z';
    return DateTime.parse(normalized).toLocal();
  } catch (_) {
    return null;
  }
}

/// Non-nullable version with fallback to now
DateTime parseDirectusDateOrNow(String? dateStr) {
  return parseDirectusDate(dateStr) ?? DateTime.now();
}

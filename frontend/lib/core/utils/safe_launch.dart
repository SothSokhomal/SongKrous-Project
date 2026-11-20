import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Reduces any "phone number" string to something safe to put in a `tel:` URI:
/// digits only, with at most one leading `+`. Returns null when what is left
/// can't be a real number (fewer than 3 or more than 16 digits), so malformed
/// or hostile input can never reach the URL launcher.
String? sanitizePhone(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed.length > 64) return null;
  final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length < 3 || digits.length > 16) return null;
  return trimmed.startsWith('+') ? '+$digits' : digits;
}

/// Opens the phone app for [raw]. Never throws: returns false when the number
/// is invalid, the device can't place calls (simulator, tablet) or the launch
/// fails, so the caller can show a friendly fallback.
Future<bool> placeCall(String? raw) async {
  final number = sanitizePhone(raw);
  if (number == null) return false;
  final uri = Uri(scheme: 'tel', path: number);
  try {
    if (!await canLaunchUrl(uri)) return false;
    return await launchUrl(uri);
  } catch (_) {
    return false;
  }
}

/// Injection point so the call screen can be tested without a real phone app.
final phoneLauncherProvider = Provider<Future<bool> Function(String?)>(
  (ref) => placeCall,
);

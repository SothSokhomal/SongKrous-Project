import 'package:flutter/services.dart';

import '../constants/app_strings.dart';

/// Khmer numerals (០-៩) → ASCII so a Khmer keyboard works the same as a
/// Latin one.
String asciiDigits(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    if (r >= 0x17E0 && r <= 0x17E9) {
      b.writeCharCode(0x30 + (r - 0x17E0));
    } else {
      b.writeCharCode(r);
    }
  }
  return b.toString();
}

/// Digits only, Khmer numerals normalised, trunk `0` dropped (`012…` → `12…`),
/// capped at 9 digits (Cambodian national numbers are 8–9 digits).
String cleanPhoneDigits(String input) {
  var d = asciiDigits(input).replaceAll(RegExp(r'[^0-9]'), '');
  if (d.startsWith('0')) d = d.substring(1);
  return d.length > 9 ? d.substring(0, 9) : d;
}

/// `12855706` → `12 855 706`; `128557061` → `12 855 7061`.
String groupPhone(String digits) {
  final d = digits;
  if (d.length <= 2) return d;
  if (d.length <= 5) return '${d.substring(0, 2)} ${d.substring(2)}';
  return '${d.substring(0, 2)} ${d.substring(2, 5)} ${d.substring(5)}';
}

/// What the field shows while typing: keeps a typed trunk `0`
/// (`012 855 706`) or none (`12 855 706`); spaces are inserted automatically,
/// and at most 10 / 9 digits are kept.
String formatPhoneInput(String input) {
  var d = asciiDigits(input).replaceAll(RegExp(r'[^0-9]'), '');
  final trunk = d.startsWith('0');
  final max = trunk ? 10 : 9;
  if (d.length > max) d = d.substring(0, max);
  if (!trunk) return groupPhone(d);
  // 0XX XXX XXX(X)
  if (d.length <= 3) return d;
  if (d.length <= 6) return '${d.substring(0, 3)} ${d.substring(3)}';
  return '${d.substring(0, 3)} ${d.substring(3, 6)} ${d.substring(6)}';
}

/// Valid enough for the prototype: 8–9 national digits.
bool isValidPhone(String digits) => digits.length >= 8 && digits.length <= 9;

/// Live `12 855 706` formatting while typing.
///
/// The text is shown in the active language's numerals (Khmer digits in KH
/// mode); [cleanPhoneDigits] reads either back.
class PhoneInputFormatter extends TextInputFormatter {
  const PhoneInputFormatter(this.lang);

  final AppLang lang;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = AppStrings.digits(formatPhoneInput(newValue.text), lang);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Keeps only digits (Khmer numerals normalised) and at most [length] of them.
class OtpDigitsFormatter extends TextInputFormatter {
  const OtpDigitsFormatter(this.length);
  final int length;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var d = asciiDigits(newValue.text).replaceAll(RegExp(r'[^0-9]'), '');
    if (d.length > length) d = d.substring(0, length);
    return TextEditingValue(
      text: d,
      selection: TextSelection.collapsed(offset: d.length),
    );
  }
}

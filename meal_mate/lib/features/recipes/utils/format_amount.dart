/// Formats a scaled ingredient amount for display.
///
/// - Whole numbers (e.g., 2.0) are displayed as integers: "2"
/// - Decimals are shown to at most 2 decimal places with trailing zeros stripped.
///   e.g., 0.5 -> "0.5", 0.6666 -> "0.67", 1.50 -> "1.5"
String formatAmount(double amount) {
  // If the value is effectively a whole number, return without decimal point.
  if (amount == amount.truncate().toDouble()) {
    return amount.truncate().toString();
  }

  // Otherwise round to 2 decimal places and strip trailing zeros.
  final fixed = amount.toStringAsFixed(2);

  // Remove trailing zeros after the decimal point.
  String result = fixed.replaceAll(RegExp(r'0+$'), '');

  // Remove trailing decimal point if all decimals were stripped.
  result = result.replaceAll(RegExp(r'\.$'), '');

  return result;
}

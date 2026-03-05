import 'package:flutter_test/flutter_test.dart';
import 'package:meal_mate/features/recipes/utils/format_amount.dart';

void main() {
  // ---------------------------------------------------------------------------
  // formatAmount tests
  // ---------------------------------------------------------------------------

  group('formatAmount', () {
    test('whole number 1.0 returns "1"', () {
      expect(formatAmount(1.0), '1');
    });

    test('0.5 returns "0.5"', () {
      expect(formatAmount(0.5), '0.5');
    });

    test('repeating 0.6666 returns "0.67"', () {
      expect(formatAmount(0.6666), '0.67');
    });

    test('whole number 2.0 returns "2"', () {
      expect(formatAmount(2.0), '2');
    });

    test('1.50 returns "1.5" (strips trailing zero)', () {
      expect(formatAmount(1.50), '1.5');
    });

    test('0.333333 returns "0.33"', () {
      expect(formatAmount(0.333333), '0.33');
    });
  });

  // ---------------------------------------------------------------------------
  // Scaling math tests
  // ---------------------------------------------------------------------------

  group('scaling math', () {
    double scaleAmount(
        double amount, int originalServings, int selectedServings) {
      return (amount / originalServings) * selectedServings;
    }

    test('2 cups from 4 servings to 8 servings returns 4.0', () {
      expect(scaleAmount(2, 4, 8), 4.0);
    });

    test('1.5 tsp from 2 servings to 1 serving returns 0.75', () {
      expect(scaleAmount(1.5, 2, 1), 0.75);
    });

    test('3 units from 3 servings to 3 servings returns 3.0', () {
      expect(scaleAmount(3, 3, 3), 3.0);
    });
  });
}

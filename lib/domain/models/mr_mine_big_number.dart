import 'dart:math' as math;

/// Immutable Dart implementation of the official Mr. Mine BigNumber value type.
///
/// Reference: https://mrmine.com/game/desktop/Core/BigNumber.js
///
/// Stores:
///   value = coefficient * 10 ^ exponent
/// where [coefficient] is normalized such that `1.0 <= abs(coefficient) < 10.0`
/// (or `0.0` for zero), and [exponent] is an integer power of 10.
///
/// Supports numbers well beyond double.maxFinite (~1.79e308), negative values,
/// the source-exact 10-power addition/subtraction cutoff, comparisons, and
/// reversible decimal/scientific string serialization suitable for JSON.
class MrMineBigNumber implements Comparable<MrMineBigNumber> {
  final double coefficient;
  final int exponent;

  static const MrMineBigNumber zero = MrMineBigNumber.raw(0.0, 0);
  static const MrMineBigNumber one = MrMineBigNumber.raw(1.0, 0);

  /// Constructs an already normalized instance directly.
  const MrMineBigNumber.raw(this.coefficient, this.exponent);

  /// Constructs a [MrMineBigNumber] from a [num].
  factory MrMineBigNumber([num value = 0]) {
    if (value == 0) return zero;
    final (c, e) = _normalize(value.toDouble(), 0);
    return MrMineBigNumber.raw(c, e);
  }

  /// Constructs from an explicit coefficient and exponent, normalizing as needed.
  /// Equivalent to source `new BigNumber(coefficient, exponent)`.
  factory MrMineBigNumber.fromParts(num coefficient, int exponent) {
    if (coefficient == 0) return zero;
    final (c, e) = _normalize(coefficient.toDouble(), exponent);
    return MrMineBigNumber.raw(c, e);
  }

  /// Constructs from a [num].
  factory MrMineBigNumber.fromNum(num value) => MrMineBigNumber(value);

  /// Parses decimal integers, decimals, and scientific notation strings.
  /// Equivalent to source string constructor `new BigNumber("432e2")`.
  /// Handles values far beyond double.maxFinite without overflow.
  factory MrMineBigNumber.fromString(String text) => parse(text);

  /// JSON deserialization supporting String, num, or existing [MrMineBigNumber].
  factory MrMineBigNumber.fromJson(Object? json) {
    if (json == null) return zero;
    if (json is MrMineBigNumber) return json;
    if (json is num) return MrMineBigNumber.fromNum(json);
    if (json is String) return MrMineBigNumber.parse(json);
    throw FormatException('Cannot deserialize MrMineBigNumber from $json');
  }

  /// Normalizes a coefficient and integer exponent so that `1.0 <= abs(c) < 10.0`
  /// or `c == 0.0`. Follows source `normalize()`.
  static (double, int) _normalize(double coeff, int exp) {
    if (coeff.isNaN || coeff.isInfinite) {
      return (coeff, exp);
    }
    if (coeff == 0.0) {
      return (0.0, 0);
    }

    var c = coeff;
    var e = exp;
    final absC = c.abs();

    if (absC >= 10.0) {
      final delta = (math.log(absC) / math.ln10).floor();
      if (delta > 0) {
        c /= math.pow(10.0, delta);
        e += delta;
      }
      while (c.abs() >= 10.0) {
        c /= 10.0;
        e += 1;
      }
    } else if (absC < 1.0) {
      final delta = -(math.log(absC) / math.ln10).floor();
      if (delta > 0) {
        c *= math.pow(10.0, delta);
        e -= delta;
      }
      while (c != 0.0 && c.abs() < 1.0) {
        c *= 10.0;
        e -= 1;
      }
    }

    return (c, e);
  }

  /// Parses arbitrary decimal or scientific notation strings without double overflow.
  static MrMineBigNumber parse(String input) {
    final cleaned = input.replaceAll(',', '').trim();
    if (cleaned.isEmpty) {
      throw const FormatException('Cannot parse empty string as MrMineBigNumber');
    }

    final isNegative = cleaned.startsWith('-');
    var s = (isNegative || cleaned.startsWith('+')) ? cleaned.substring(1) : cleaned;

    if (s.isEmpty) {
      throw FormatException('Invalid number string: $input');
    }

    // Must contain at least one digit in the mantissa
    final eIdx = s.toLowerCase().indexOf('e');
    int explicitExp = 0;
    if (eIdx != -1) {
      final expStr = s.substring(eIdx + 1);
      final parsedExp = int.tryParse(expStr);
      if (parsedExp == null) {
        throw FormatException('Invalid exponent in: $input');
      }
      explicitExp = parsedExp;
      s = s.substring(0, eIdx);
    }

    if (s.isEmpty || !RegExp(r'\d').hasMatch(s)) {
      throw FormatException('Invalid number string (missing digits): $input');
    }

    final firstDot = s.indexOf('.');
    final lastDot = s.lastIndexOf('.');
    if (firstDot != lastDot) {
      throw FormatException('Multiple decimal points in: $input');
    }

    final dotIdx = firstDot;
    String intPart = dotIdx == -1 ? s : s.substring(0, dotIdx);
    String fracPart = dotIdx == -1 ? '' : s.substring(dotIdx + 1);

    if ((intPart.isNotEmpty && !RegExp(r'^\d+$').hasMatch(intPart)) ||
        (fracPart.isNotEmpty && !RegExp(r'^\d+$').hasMatch(fracPart))) {
      throw FormatException('Invalid characters in: $input');
    }

    intPart = intPart.replaceFirst(RegExp(r'^0+'), '');

    if (intPart.isNotEmpty) {
      final intExp = intPart.length - 1;
      final totalExp = explicitExp + intExp;

      final allDigits = intPart + fracPart;
      final sigDigits = allDigits.length > 17 ? allDigits.substring(0, 17) : allDigits;
      final coeffStr =
          '${sigDigits[0]}.${sigDigits.length > 1 ? sigDigits.substring(1) : "0"}';
      var coeff = double.parse(coeffStr);
      if (isNegative) coeff = -coeff;
      return MrMineBigNumber.fromParts(coeff, totalExp);
    } else {
      final firstNonZero = fracPart.indexOf(RegExp(r'[1-9]'));
      if (firstNonZero == -1) {
        return zero;
      }
      final fracExp = -(firstNonZero + 1);
      final totalExp = explicitExp + fracExp;
      final remainingFrac = fracPart.substring(firstNonZero);
      final sigDigits =
          remainingFrac.length > 17 ? remainingFrac.substring(0, 17) : remainingFrac;
      final coeffStr =
          '${sigDigits[0]}.${sigDigits.length > 1 ? sigDigits.substring(1) : "0"}';
      var coeff = double.parse(coeffStr);
      if (isNegative) coeff = -coeff;
      return MrMineBigNumber.fromParts(coeff, totalExp);
    }
  }

  /// Parses input string or returns `null` if invalid.
  static MrMineBigNumber? tryParse(String? input) {
    if (input == null) return null;
    try {
      return parse(input);
    } catch (_) {
      return null;
    }
  }

  bool get isZero => coefficient == 0.0;
  bool get isNegative => coefficient < 0.0;
  bool get isPositive => coefficient > 0.0;

  bool get isNaN => coefficient.isNaN;
  bool get isInfinite => coefficient.isInfinite;
  bool get isFinite => !isNaN && !isInfinite;

  /// Negates the value. Matches source `negate()`.
  MrMineBigNumber negate() {
    if (coefficient == 0.0) return zero;
    return MrMineBigNumber.raw(-coefficient, exponent);
  }

  MrMineBigNumber operator -() => negate();

  /// Adds [other]. Matches source `add(other)`.
  ///
  /// When `exponent - other.exponent > 10`, [other] is dropped.
  /// When `exponent - other.exponent < -10`, [this] is dropped.
  MrMineBigNumber add(MrMineBigNumber other) {
    final powerDifference = exponent - other.exponent;
    if (powerDifference > 10) {
      return this;
    }
    if (powerDifference < -10) {
      return other;
    }
    if (powerDifference == 0) {
      final (c, e) = _normalize(coefficient + other.coefficient, exponent);
      return MrMineBigNumber.raw(c, e);
    } else if (powerDifference > 0) {
      final resCoeff =
          coefficient * math.pow(10.0, powerDifference) + other.coefficient;
      final (c, e) = _normalize(resCoeff, other.exponent);
      return MrMineBigNumber.raw(c, e);
    } else {
      final tempBase = other.coefficient * math.pow(10.0, -powerDifference);
      final (c, e) = _normalize(coefficient + tempBase, exponent);
      return MrMineBigNumber.raw(c, e);
    }
  }

  MrMineBigNumber operator +(MrMineBigNumber other) => add(other);

  /// Subtracts [other]. Matches source `subtract(other)`.
  MrMineBigNumber subtract(MrMineBigNumber other) => add(other.negate());

  MrMineBigNumber operator -(MrMineBigNumber other) => subtract(other);

  /// Multiplies by [other]. Matches source `multiply(other)`.
  MrMineBigNumber multiply(MrMineBigNumber other) {
    if (coefficient == 0.0 || other.coefficient == 0.0) {
      return zero;
    }
    final (c, e) = _normalize(
      coefficient * other.coefficient,
      exponent + other.exponent,
    );
    return MrMineBigNumber.raw(c, e);
  }

  MrMineBigNumber operator *(MrMineBigNumber other) => multiply(other);

  /// Divides by [other]. Matches source `divide(other)`.
  MrMineBigNumber divide(MrMineBigNumber other) {
    if (other.coefficient == 0.0) {
      throw UnsupportedError('Division by zero');
    }
    if (coefficient == 0.0) {
      return zero;
    }
    var resCoeff = coefficient / other.coefficient;
    var resExp = exponent - other.exponent;
    // Source behavior: if result.coefficient < 10000, scale up by 10000 and adjust exponent.
    if (resCoeff < 10000.0) {
      resCoeff *= 10000.0;
      resExp -= 4;
    }
    final (c, e) = _normalize(resCoeff, resExp);
    return MrMineBigNumber.raw(c, e);
  }

  MrMineBigNumber operator /(MrMineBigNumber other) => divide(other);

  /// Multiplies by a [num] factor.
  MrMineBigNumber multiplyNum(num factor) =>
      multiply(MrMineBigNumber.fromNum(factor));

  /// Divides by a [num] divisor.
  MrMineBigNumber divideNum(num divisor) =>
      divide(MrMineBigNumber.fromNum(divisor));

  /// Increments by 1. Matches source `increment()`.
  MrMineBigNumber increment() => add(one);

  /// Decrements by 1. Matches source `decrement()`.
  MrMineBigNumber decrement() => subtract(one);

  /// Inverts the number (1 / this). Matches source `invert()`.
  MrMineBigNumber invert() {
    if (coefficient == 0.0) {
      throw UnsupportedError('Division by zero');
    }
    return MrMineBigNumber.fromParts(1.0 / coefficient, -exponent);
  }

  /// Raises this number to [power]. Matches source `pow(other)`.
  MrMineBigNumber pow(num power) {
    if (coefficient == 0.0) return zero;
    final resCoeff = math.pow(coefficient, power).toDouble();
    final rawExp = exponent * power;
    final expFloor = rawExp.floor();
    final expFrac = rawExp - expFloor;
    var finalCoeff = resCoeff;
    if (expFrac > 0) {
      finalCoeff *= math.pow(10.0, expFrac);
    }
    final (c, e) = _normalize(finalCoeff, expFloor);
    return MrMineBigNumber.raw(c, e);
  }

  /// Strict equality check matching official Mr. Mine `equals(other)`.
  ///
  /// Uses exact coefficient and exponent equality:
  /// `other.exponent == this.exponent && other.coefficient == this.coefficient`
  bool equals(MrMineBigNumber other) =>
      exponent == other.exponent && coefficient == other.coefficient;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MrMineBigNumber) return false;
    return equals(other);
  }

  @override
  int get hashCode => Object.hash(coefficient, exponent);

  /// Less-than comparison. Matches source `lessThan(other)`.
  bool lessThan(MrMineBigNumber other) {
    if (coefficient == 0.0) {
      return other.coefficient > 0.0;
    }
    if (other.coefficient == 0.0) {
      return coefficient < 0.0;
    }
    if ((coefficient < 0.0) != (other.coefficient < 0.0)) {
      return coefficient < other.coefficient;
    }
    final sign = coefficient > 0.0 ? 1 : -1;
    if (sign * exponent > sign * other.exponent) {
      return false;
    } else {
      if (exponent == other.exponent) {
        return coefficient < other.coefficient;
      } else {
        return true;
      }
    }
  }

  bool operator <(Object other) {
    if (other is MrMineBigNumber) return lessThan(other);
    if (other is num) return lessThan(MrMineBigNumber.fromNum(other));
    return false;
  }

  /// Greater-than comparison. Matches source `greaterThan(other)`.
  bool greaterThan(MrMineBigNumber other) => other.lessThan(this);

  bool operator >(Object other) {
    if (other is MrMineBigNumber) return greaterThan(other);
    if (other is num) return greaterThan(MrMineBigNumber.fromNum(other));
    return false;
  }

  /// Greater-than-or-equal comparison. Matches source `greaterThanOrEqualTo(other)`.
  bool greaterThanOrEqualTo(MrMineBigNumber other) => !lessThan(other);

  bool operator >=(Object other) {
    if (other is MrMineBigNumber) return greaterThanOrEqualTo(other);
    if (other is num) return greaterThanOrEqualTo(MrMineBigNumber.fromNum(other));
    return false;
  }

  /// Less-than-or-equal comparison. Matches source `lessThanOrEqualTo(other)`.
  bool lessThanOrEqualTo(MrMineBigNumber other) => !greaterThan(other);

  bool operator <=(Object other) {
    if (other is MrMineBigNumber) return lessThanOrEqualTo(other);
    if (other is num) return lessThanOrEqualTo(MrMineBigNumber.fromNum(other));
    return false;
  }

  @override
  int compareTo(MrMineBigNumber other) {
    if (lessThan(other)) return -1;
    if (other.lessThan(this)) return 1;
    return 0;
  }

  /// Clamps value between [min] and [max].
  MrMineBigNumber clamp(MrMineBigNumber min, MrMineBigNumber max) {
    if (lessThan(min)) return min;
    if (greaterThan(max)) return max;
    return this;
  }

  /// Converts to double. Matches source `toFloat(maxDigits)`.
  double toFloat([int maxDigits = -1]) {
    if (maxDigits > 0) {
      final exp = exponent < maxDigits ? exponent : maxDigits;
      if (exp >= 0) {
        return coefficient * math.pow(10.0, exp);
      } else {
        return coefficient / math.pow(10.0, -exp);
      }
    }
    if (exponent >= 0) {
      return coefficient * math.pow(10.0, exponent);
    } else {
      return coefficient / math.pow(10.0, -exponent);
    }
  }

  double toDouble() => toFloat();

  /// Floor operation matching official Mr. Mine `floor()`.
  /// Note: Returns `zero` if exponent is outside the open range `(-15, 15)`.
  MrMineBigNumber floor() {
    if (exponent < 15 && exponent > -15) {
      final val = (coefficient * math.pow(10.0, exponent)).floorToDouble();
      return MrMineBigNumber.fromParts(val, 0);
    }
    return zero;
  }

  /// Ceiling operation matching official Mr. Mine `ceiling()`.
  /// Note: Returns `zero` if exponent is outside the open range `(-15, 15)`.
  MrMineBigNumber ceiling() {
    if (exponent < 15 && exponent > -15) {
      final val = (coefficient * math.pow(10.0, exponent)).ceilToDouble();
      return MrMineBigNumber.fromParts(val, 0);
    }
    return zero;
  }

  /// Round operation matching official Mr. Mine `round()`.
  MrMineBigNumber round() {
    final floorResult = floor();
    if (subtract(floorResult).greaterThan(const MrMineBigNumber.raw(5.0, -1))) {
      return ceiling();
    }
    return floorResult;
  }

  /// Decimal string encoding matching official Mr. Mine `BigNumber.toString()`.
  ///
  /// Matches source display semantics directly using `Math.floor(toFloat(15))`
  /// without epsilon adjustments.
  /// For values with `exponent > 15`, digits beyond the 15th are zeroed out.
  /// Note: Source `toString()` is lossy for fractional exponents (< 0) or
  /// precision exceeding 15 digits. For lossless save persistence, use [toSaveString] / [toJson].
  @override
  String toString() {
    if (coefficient == 0.0) return '0';
    const maxDigits = 15;
    final floatVal = toFloat(maxDigits);
    final floored = floatVal.floor();
    var stringValue = floored.toString();
    if (exponent > maxDigits) {
      stringValue += '0' * (exponent - maxDigits);
    }
    return stringValue;
  }

  /// Reversible lossless scientific serialization for persistence/saves (`${coefficient}e$exponent`).
  String toSaveString() {
    if (coefficient == 0.0) return '0';
    return '${coefficient}e$exponent';
  }

  /// Scientific notation representation (e.g. `1.5e20`).
  String toScientificString() => toSaveString();

  /// JSON serialization producing the exact lossless scientific representation.
  String toJson() => toSaveString();
}

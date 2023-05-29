import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:intl/number_symbols.dart';
import 'package:intl/number_symbols_data.dart';

class Amount {
  Amount({
    required BigInt rawValue,
    required this.fractionDigits,
  })  : assert(fractionDigits >= 0),
        _value = rawValue;

  /// special zero case with [fractionDigits] set to 0
  static Amount get zero => Amount(
        rawValue: BigInt.zero,
        fractionDigits: 0,
      );

  /// truncate decimal value to [fractionDigits] places
  Amount.fromDecimal(Decimal amount, {required this.fractionDigits})
      : assert(fractionDigits >= 0),
        _value = amount.shift(fractionDigits).toBigInt();

  static Amount? tryParseFiatString(
    String value, {
    required String locale,
  }) {
    final parts = value.split(" ");

    if (parts.first.isEmpty) {
      return null;
    }

    String str = parts.first;
    if (str.startsWith(RegExp(r'[+-]'))) {
      str = str.substring(1);
    }

    if (str.isEmpty) {
      return null;
    }

    // get number symbols for decimal place and group separator
    final numberSymbols = numberFormatSymbols[locale] as NumberSymbols? ??
        numberFormatSymbols[locale.substring(0, 2)] as NumberSymbols?;

    final groupSeparator = numberSymbols?.GROUP_SEP ?? ",";
    final decimalSeparator = numberSymbols?.DECIMAL_SEP ?? ".";

    str = str.replaceAll(groupSeparator, "");

    final decimalString = str.replaceFirst(decimalSeparator, ".");

    return Decimal.tryParse(decimalString)?.toAmount(fractionDigits: 2);
  }

  // ===========================================================================
  // ======= Instance properties ===============================================

  final int fractionDigits;
  final BigInt _value;

  // ===========================================================================
  // ======= Getters ===========================================================

  /// raw base value
  BigInt get raw => _value;

  /// actual decimal vale represented
  Decimal get decimal => Decimal.fromBigInt(raw).shift(-1 * fractionDigits);

  /// convenience getter
  @Deprecated("provided for convenience only. Use fractionDigits instead.")
  int get decimals => fractionDigits;

  // ===========================================================================
  // ======= Serialization =====================================================

  Map<String, dynamic> toMap() {
    return {"raw": raw.toString(), "fractionDigits": fractionDigits};
  }

  String toJsonString() {
    return jsonEncode(toMap());
  }

  String fiatString({
    required String locale,
  }) {
    final wholeNumber = decimal.truncate();

    // get number symbols for decimal place and group separator
    final numberSymbols = numberFormatSymbols[locale] as NumberSymbols? ??
        numberFormatSymbols[locale.substring(0, 2)] as NumberSymbols?;

    final String separator = numberSymbols?.DECIMAL_SEP ?? ".";

    final fraction = decimal - wholeNumber;

    String wholeNumberString = wholeNumber.toStringAsFixed(0);
    // insert group separator
    final regex = RegExp(r'\B(?=(\d{3})+(?!\d))');
    wholeNumberString = wholeNumberString.replaceAllMapped(
      regex,
      (m) => "${m.group(0)}${numberSymbols?.GROUP_SEP ?? ","}",
    );

    return "$wholeNumberString$separator${fraction.toStringAsFixed(2).substring(2)}";
  }
  // String localizedStringAsFixed({
  //   required String locale,
  //   int? decimalPlaces,
  // }) {
  //   decimalPlaces ??= fractionDigits;
  //   assert(decimalPlaces >= 0);
  //
  //   final wholeNumber = decimal.truncate();
  //
  //   if (decimalPlaces == 0) {
  //     return wholeNumber.toStringAsFixed(0);
  //   }
  //
  //   final String separator =
  //       (numberFormatSymbols[locale] as NumberSymbols?)?.DECIMAL_SEP ??
  //           (numberFormatSymbols[locale.substring(0, 2)] as NumberSymbols?)
  //               ?.DECIMAL_SEP ??
  //           ".";
  //
  //   final fraction = decimal - wholeNumber;
  //
  //   return "${wholeNumber.toStringAsFixed(0)}$separator${fraction.toStringAsFixed(decimalPlaces).substring(2)}";
  // }

  // ===========================================================================
  // ======= Deserialization ===================================================

  static Amount fromSerializedJsonString(String json) {
    final map = jsonDecode(json) as Map;
    return Amount(
      rawValue: BigInt.parse(map["raw"] as String),
      fractionDigits: map["fractionDigits"] as int,
    );
  }

  // ===========================================================================
  // ======= operators =========================================================

  bool operator >(Amount other) => decimal > other.decimal;

  bool operator <(Amount other) => decimal < other.decimal;

  bool operator >=(Amount other) => decimal >= other.decimal;

  bool operator <=(Amount other) => decimal <= other.decimal;

  Amount operator +(Amount other) {
    if (fractionDigits != other.fractionDigits) {
      throw ArgumentError(
          "fractionDigits do not match: this=$this, other=$other");
    }
    return Amount(
      rawValue: raw + other.raw,
      fractionDigits: fractionDigits,
    );
  }

  Amount operator -(Amount other) {
    if (fractionDigits != other.fractionDigits) {
      throw ArgumentError(
          "fractionDigits do not match: this=$this, other=$other");
    }
    return Amount(
      rawValue: raw - other.raw,
      fractionDigits: fractionDigits,
    );
  }

  Amount operator *(Amount other) {
    if (fractionDigits != other.fractionDigits) {
      throw ArgumentError(
          "fractionDigits do not match: this=$this, other=$other");
    }
    return Amount(
      rawValue: raw * other.raw,
      fractionDigits: fractionDigits,
    );
  }

  // ===========================================================================
  // ======= Overrides =========================================================

  @override
  String toString() => "Amount($raw, $fractionDigits)";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Amount &&
          runtimeType == other.runtimeType &&
          raw == other.raw &&
          fractionDigits == other.fractionDigits;

  @override
  int get hashCode => Object.hashAll([raw, fractionDigits]);
}

// =============================================================================
// =============================================================================
// ======= Extensions ==========================================================

extension DecimalAmountExt on Decimal {
  Amount toAmount({required int fractionDigits}) {
    return Amount.fromDecimal(
      this,
      fractionDigits: fractionDigits,
    );
  }
}

extension IntAmountExtension on int {
  Amount toAmountAsRaw({required int fractionDigits}) {
    return Amount(
      rawValue: BigInt.from(this),
      fractionDigits: fractionDigits,
    );
  }
}

import 'package:stackduo/utilities/logger.dart';

class SPCurrency {
  /// currency name
  final String name;

  /// currency symbol
  final String symbol;

  /// currency network
  final String network;

  /// has this currency extra id parameter
  final bool hasExtraId;

  /// name of extra id (if exists)
  final String? extraId;

  /// relative url for currency icon svg
  final String image;

  /// informational messages about the currency they are changing
  final List<dynamic> warningsFrom;

  /// informational messages about the currency for which they are exchanged
  final List<dynamic> warningsTo;

  SPCurrency({
    required this.name,
    required this.symbol,
    required this.network,
    required this.hasExtraId,
    required this.extraId,
    required this.image,
    required this.warningsFrom,
    required this.warningsTo,
  });

  factory SPCurrency.fromJson(Map<String, dynamic> json) {
    try {
      return SPCurrency(
        name: json["name"] as String,
        symbol: json["symbol"] as String,
        network: json["network"] as String? ?? "",
        hasExtraId: json["has_extra_id"] as bool,
        extraId: json["extra_id"] as String?,
        image: json["image"] as String,
        warningsFrom: json["warnings_from"] as List<dynamic>,
        warningsTo: json["warnings_to"] as List<dynamic>,
      );
    } catch (e, s) {
      Logging.instance.log("SPCurrency.fromJson failed to parse: $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    final map = {
      "name": name,
      "symbol": symbol,
      "network": network,
      "has_extra_id": hasExtraId,
      "extra_id": extraId,
      "image": image,
      "warnings_from": warningsFrom,
      "warnings_to": warningsTo,
    };

    return map;
  }

  SPCurrency copyWith({
    String? name,
    String? symbol,
    String? network,
    bool? hasExtraId,
    String? extraId,
    String? image,
    List<dynamic>? warningsFrom,
    List<dynamic>? warningsTo,
  }) {
    return SPCurrency(
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      network: network ?? this.network,
      hasExtraId: hasExtraId ?? this.hasExtraId,
      extraId: extraId ?? this.extraId,
      image: image ?? this.image,
      warningsFrom: warningsFrom ?? this.warningsFrom,
      warningsTo: warningsTo ?? this.warningsTo,
    );
  }

  @override
  String toString() {
    return "SPCurrency: ${toJson()}";
  }
}

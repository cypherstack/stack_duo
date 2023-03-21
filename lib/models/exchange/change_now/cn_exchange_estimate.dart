import 'package:decimal/decimal.dart';
import 'package:stackduo/utilities/logger.dart';

enum CNEstimateType { direct, reverse }

enum CNFlowType implements Comparable<CNFlowType> {
  standard("standard"),
  fixedRate("fixed-rate");

  const CNFlowType(this.value);

  final String value;

  @override
  int compareTo(CNFlowType other) => value.compareTo(other.value);
}

class CNExchangeEstimate {
  /// Ticker of the currency you want to exchange
  final String fromCurrency;

  /// Network of the currency you want to exchange
  final String fromNetwork;

  /// Ticker of the currency you want to receive
  final String toCurrency;

  /// Network of the currency you want to receive
  final String toNetwork;

  /// Type of exchange flow. Enum: ["standard", "fixed-rate"]
  final CNFlowType flow;

  /// Direction of exchange flow. Use "direct" value to set amount for
  /// currencyFrom and get amount of currencyTo. Use "reverse" value to set
  /// amount for currencyTo and get amount of currencyFrom.
  /// Enum: ["direct", "reverse"]
  final CNEstimateType type;

  /// (Optional) Use rateId for fixed-rate flow. If this field is true, you
  /// could use returned field "rateId" in next method for creating transaction
  /// to freeze estimated amount that you got in this method. Current estimated
  /// amount would be valid until time in field "validUntil"
  final String? rateId;

  /// Date and time before estimated amount would be freezed in case of using
  /// rateId. If you set param "useRateId" to true, you could use returned field
  /// "rateId" in next method for creating transaction to freeze estimated
  /// amount that you got in this method. Estimated amount would be valid until
  /// this date and time
  final String? validUntil;

  /// Dash-separated min and max estimated time in minutes
  final String? transactionSpeedForecast;

  /// Some warnings like warnings that transactions on this network
  /// take longer or that the currency has moved to another network
  final String? warningMessage;

  /// Exchange amount of fromCurrency (in case when type=reverse it is an
  /// estimated value)
  final Decimal fromAmount;

  /// Exchange amount of toCurrency (in case when type=direct it is an
  /// estimated value)
  final Decimal toAmount;

  CNExchangeEstimate({
    required this.fromCurrency,
    required this.fromNetwork,
    required this.toCurrency,
    required this.toNetwork,
    required this.flow,
    required this.type,
    this.rateId,
    this.validUntil,
    this.transactionSpeedForecast,
    this.warningMessage,
    required this.fromAmount,
    required this.toAmount,
  });

  factory CNExchangeEstimate.fromJson(Map<String, dynamic> json) {
    try {
      final flow = CNFlowType.values
          .firstWhere((element) => element.value == json["flow"]);
      final type = CNEstimateType.values
          .firstWhere((element) => element.name == json["type"]);

      return CNExchangeEstimate(
        fromCurrency: json["fromCurrency"] as String,
        fromNetwork: json["fromNetwork"] as String,
        toCurrency: json["toCurrency"] as String,
        toNetwork: json["toNetwork"] as String,
        flow: flow,
        type: type,
        rateId: json["rateId"] as String?,
        validUntil: json["validUntil"] as String?,
        transactionSpeedForecast: json["transactionSpeedForecast"] as String?,
        warningMessage: json["warningMessage"] as String?,
        fromAmount: Decimal.parse(json["fromAmount"].toString()),
        toAmount: Decimal.parse(json["toAmount"].toString()),
      );
    } catch (e, s) {
      Logging.instance
          .log("Failed to parse: $json \n$e\n$s", level: LogLevel.Fatal);
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "fromCurrency": fromCurrency,
      "fromNetwork": fromNetwork,
      "toCurrency": toCurrency,
      "toNetwork": toNetwork,
      "flow": flow,
      "type": type,
      "rateId": rateId,
      "validUntil": validUntil,
      "transactionSpeedForecast": transactionSpeedForecast,
      "warningMessage": warningMessage,
      "fromAmount": fromAmount,
      "toAmount": toAmount,
    };
  }

  CNExchangeEstimate copyWith({
    String? fromCurrency,
    String? fromNetwork,
    String? toCurrency,
    String? toNetwork,
    CNFlowType? flow,
    CNEstimateType? type,
    String? rateId,
    String? validUntil,
    String? transactionSpeedForecast,
    String? warningMessage,
    Decimal? fromAmount,
    Decimal? toAmount,
  }) {
    return CNExchangeEstimate(
      fromCurrency: fromCurrency ?? this.fromCurrency,
      fromNetwork: fromNetwork ?? this.fromNetwork,
      toCurrency: toCurrency ?? this.toCurrency,
      toNetwork: toNetwork ?? this.toNetwork,
      flow: flow ?? this.flow,
      type: type ?? this.type,
      rateId: rateId ?? this.rateId,
      validUntil: validUntil ?? this.validUntil,
      transactionSpeedForecast:
          transactionSpeedForecast ?? this.transactionSpeedForecast,
      warningMessage: warningMessage ?? this.warningMessage,
      fromAmount: fromAmount ?? this.fromAmount,
      toAmount: toAmount ?? this.toAmount,
    );
  }

  @override
  String toString() {
    return "EstimatedExchangeAmount: ${toJson()}";
  }
}

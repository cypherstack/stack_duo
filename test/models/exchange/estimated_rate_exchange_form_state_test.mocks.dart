// Mocks generated by Mockito 5.2.0 from annotations
// in stackwallet/test/models/exchange/estimated_rate_exchange_form_state_test.dart.
// Do not manually edit this file.

import 'dart:async' as _i5;

import 'package:decimal/decimal.dart' as _i7;
import 'package:http/http.dart' as _i4;
import 'package:mockito/mockito.dart' as _i1;
import 'package:stackwallet/models/exchange/change_now/available_floating_rate_pair.dart'
    as _i13;
import 'package:stackwallet/models/exchange/change_now/change_now_response.dart'
    as _i2;
import 'package:stackwallet/models/exchange/change_now/cn_exchange_estimate.dart'
    as _i9;
import 'package:stackwallet/models/exchange/change_now/currency.dart' as _i6;
import 'package:stackwallet/models/exchange/change_now/estimated_exchange_amount.dart'
    as _i8;
import 'package:stackwallet/models/exchange/change_now/exchange_transaction.dart'
    as _i11;
import 'package:stackwallet/models/exchange/change_now/exchange_transaction_status.dart'
    as _i12;
import 'package:stackwallet/models/exchange/change_now/fixed_rate_market.dart'
    as _i10;
import 'package:stackwallet/services/change_now/change_now.dart' as _i3;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types

class _FakeChangeNowResponse_0<T> extends _i1.Fake
    implements _i2.ChangeNowResponse<T> {}

/// A class which mocks [ChangeNow].
///
/// See the documentation for Mockito's code generation for more information.
class MockChangeNow extends _i1.Mock implements _i3.ChangeNow {
  MockChangeNow() {
    _i1.throwOnMissingStub(this);
  }

  @override
  set client(_i4.Client? _client) =>
      super.noSuchMethod(Invocation.setter(#client, _client),
          returnValueForMissingStub: null);
  @override
  _i5.Future<_i2.ChangeNowResponse<List<_i6.Currency>>> getAvailableCurrencies(
          {bool? fixedRate, bool? active}) =>
      (super.noSuchMethod(
          Invocation.method(#getAvailableCurrencies, [],
              {#fixedRate: fixedRate, #active: active}),
          returnValue: Future<_i2.ChangeNowResponse<List<_i6.Currency>>>.value(
              _FakeChangeNowResponse_0<List<_i6.Currency>>())) as _i5
          .Future<_i2.ChangeNowResponse<List<_i6.Currency>>>);
  @override
  _i5.Future<_i2.ChangeNowResponse<List<_i6.Currency>>> getPairedCurrencies(
          {String? ticker, bool? fixedRate}) =>
      (super.noSuchMethod(
          Invocation.method(#getPairedCurrencies, [],
              {#ticker: ticker, #fixedRate: fixedRate}),
          returnValue: Future<_i2.ChangeNowResponse<List<_i6.Currency>>>.value(
              _FakeChangeNowResponse_0<List<_i6.Currency>>())) as _i5
          .Future<_i2.ChangeNowResponse<List<_i6.Currency>>>);
  @override
  _i5.Future<_i2.ChangeNowResponse<_i7.Decimal>> getMinimalExchangeAmount(
          {String? fromTicker, String? toTicker, String? apiKey}) =>
      (super.noSuchMethod(
              Invocation.method(#getMinimalExchangeAmount, [], {
                #fromTicker: fromTicker,
                #toTicker: toTicker,
                #apiKey: apiKey
              }),
              returnValue: Future<_i2.ChangeNowResponse<_i7.Decimal>>.value(
                  _FakeChangeNowResponse_0<_i7.Decimal>()))
          as _i5.Future<_i2.ChangeNowResponse<_i7.Decimal>>);
  @override
  _i5.Future<_i2.ChangeNowResponse<_i8.EstimatedExchangeAmount>>
      getEstimatedExchangeAmount(
              {String? fromTicker,
              String? toTicker,
              _i7.Decimal? fromAmount,
              String? apiKey}) =>
          (super.noSuchMethod(
                  Invocation.method(#getEstimatedExchangeAmount, [], {
                    #fromTicker: fromTicker,
                    #toTicker: toTicker,
                    #fromAmount: fromAmount,
                    #apiKey: apiKey
                  }),
                  returnValue: Future<
                          _i2.ChangeNowResponse<
                              _i8.EstimatedExchangeAmount>>.value(
                      _FakeChangeNowResponse_0<_i8.EstimatedExchangeAmount>()))
              as _i5
                  .Future<_i2.ChangeNowResponse<_i8.EstimatedExchangeAmount>>);
  @override
  _i5.Future<_i2.ChangeNowResponse<_i9.CNExchangeEstimate>>
      getEstimatedExchangeAmountV2(
              {String? fromTicker,
              String? toTicker,
              _i9.CNEstimateType? fromOrTo,
              _i7.Decimal? amount,
              String? fromNetwork,
              String? toNetwork,
              _i9.CNFlowType? flow = _i9.CNFlowType.standard,
              String? apiKey}) =>
          (super.noSuchMethod(
                  Invocation.method(#getEstimatedExchangeAmountV2, [], {
                    #fromTicker: fromTicker,
                    #toTicker: toTicker,
                    #fromOrTo: fromOrTo,
                    #amount: amount,
                    #fromNetwork: fromNetwork,
                    #toNetwork: toNetwork,
                    #flow: flow,
                    #apiKey: apiKey
                  }),
                  returnValue: Future<
                          _i2.ChangeNowResponse<_i9.CNExchangeEstimate>>.value(
                      _FakeChangeNowResponse_0<_i9.CNExchangeEstimate>()))
              as _i5.Future<_i2.ChangeNowResponse<_i9.CNExchangeEstimate>>);
  @override
  _i5.Future<_i2.ChangeNowResponse<List<_i10.FixedRateMarket>>>
      getAvailableFixedRateMarkets({String? apiKey}) => (super.noSuchMethod(
          Invocation.method(
              #getAvailableFixedRateMarkets, [], {#apiKey: apiKey}),
          returnValue:
              Future<_i2.ChangeNowResponse<List<_i10.FixedRateMarket>>>.value(
                  _FakeChangeNowResponse_0<List<_i10.FixedRateMarket>>())) as _i5
          .Future<_i2.ChangeNowResponse<List<_i10.FixedRateMarket>>>);
  @override
  _i5.Future<_i2.ChangeNowResponse<_i11.ExchangeTransaction>>
      createStandardExchangeTransaction(
              {String? fromTicker,
              String? toTicker,
              String? receivingAddress,
              _i7.Decimal? amount,
              String? extraId = r'',
              String? userId = r'',
              String? contactEmail = r'',
              String? refundAddress = r'',
              String? refundExtraId = r'',
              String? apiKey}) =>
          (super.noSuchMethod(
              Invocation.method(#createStandardExchangeTransaction, [], {
                #fromTicker: fromTicker,
                #toTicker: toTicker,
                #receivingAddress: receivingAddress,
                #amount: amount,
                #extraId: extraId,
                #userId: userId,
                #contactEmail: contactEmail,
                #refundAddress: refundAddress,
                #refundExtraId: refundExtraId,
                #apiKey: apiKey
              }),
              returnValue: Future<
                      _i2.ChangeNowResponse<_i11.ExchangeTransaction>>.value(
                  _FakeChangeNowResponse_0<_i11.ExchangeTransaction>())) as _i5
              .Future<_i2.ChangeNowResponse<_i11.ExchangeTransaction>>);
  @override
  _i5.Future<_i2.ChangeNowResponse<_i11.ExchangeTransaction>>
      createFixedRateExchangeTransaction(
              {String? fromTicker,
              String? toTicker,
              String? receivingAddress,
              _i7.Decimal? amount,
              String? rateId,
              String? extraId = r'',
              String? userId = r'',
              String? contactEmail = r'',
              String? refundAddress = r'',
              String? refundExtraId = r'',
              String? apiKey}) =>
          (super.noSuchMethod(
              Invocation.method(#createFixedRateExchangeTransaction, [], {
                #fromTicker: fromTicker,
                #toTicker: toTicker,
                #receivingAddress: receivingAddress,
                #amount: amount,
                #rateId: rateId,
                #extraId: extraId,
                #userId: userId,
                #contactEmail: contactEmail,
                #refundAddress: refundAddress,
                #refundExtraId: refundExtraId,
                #apiKey: apiKey
              }),
              returnValue: Future<
                      _i2.ChangeNowResponse<_i11.ExchangeTransaction>>.value(
                  _FakeChangeNowResponse_0<_i11.ExchangeTransaction>())) as _i5
              .Future<_i2.ChangeNowResponse<_i11.ExchangeTransaction>>);
  @override
  _i5.Future<_i2.ChangeNowResponse<_i12.ExchangeTransactionStatus>>
      getTransactionStatus({String? id, String? apiKey}) => (super.noSuchMethod(
          Invocation.method(
              #getTransactionStatus, [], {#id: id, #apiKey: apiKey}),
          returnValue:
              Future<_i2.ChangeNowResponse<_i12.ExchangeTransactionStatus>>.value(
                  _FakeChangeNowResponse_0<_i12.ExchangeTransactionStatus>())) as _i5
          .Future<_i2.ChangeNowResponse<_i12.ExchangeTransactionStatus>>);
  @override
  _i5.Future<_i2.ChangeNowResponse<List<_i13.AvailableFloatingRatePair>>>
      getAvailableFloatingRatePairs({bool? includePartners = false}) => (super
          .noSuchMethod(
              Invocation.method(#getAvailableFloatingRatePairs, [],
                  {#includePartners: includePartners}),
              returnValue:
                  Future<_i2.ChangeNowResponse<List<_i13.AvailableFloatingRatePair>>>.value(
                      _FakeChangeNowResponse_0<List<_i13.AvailableFloatingRatePair>>())) as _i5
          .Future<_i2.ChangeNowResponse<List<_i13.AvailableFloatingRatePair>>>);
}

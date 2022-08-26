// Mocks generated by Mockito 5.2.0 from annotations
// in stackwallet/test/services/coins/dogecoin/dogecoin_wallet_test.dart.
// Do not manually edit this file.

import 'dart:async' as _i6;

import 'package:decimal/decimal.dart' as _i2;
import 'package:http/http.dart' as _i4;
import 'package:mockito/mockito.dart' as _i1;
import 'package:stackwallet/electrumx_rpc/cached_electrumx.dart' as _i7;
import 'package:stackwallet/electrumx_rpc/electrumx.dart' as _i5;
import 'package:stackwallet/services/price.dart' as _i9;
import 'package:stackwallet/services/transaction_notification_tracker.dart'
    as _i11;
import 'package:stackwallet/utilities/enums/coin_enum.dart' as _i8;
import 'package:stackwallet/utilities/prefs.dart' as _i3;
import 'package:tuple/tuple.dart' as _i10;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types

class _FakeDecimal_0 extends _i1.Fake implements _i2.Decimal {}

class _FakePrefs_1 extends _i1.Fake implements _i3.Prefs {}

class _FakeClient_2 extends _i1.Fake implements _i4.Client {}

/// A class which mocks [ElectrumX].
///
/// See the documentation for Mockito's code generation for more information.
class MockElectrumX extends _i1.Mock implements _i5.ElectrumX {
  MockElectrumX() {
    _i1.throwOnMissingStub(this);
  }

  @override
  set failovers(List<_i5.ElectrumXNode>? _failovers) =>
      super.noSuchMethod(Invocation.setter(#failovers, _failovers),
          returnValueForMissingStub: null);
  @override
  int get currentFailoverIndex =>
      (super.noSuchMethod(Invocation.getter(#currentFailoverIndex),
          returnValue: 0) as int);
  @override
  set currentFailoverIndex(int? _currentFailoverIndex) => super.noSuchMethod(
      Invocation.setter(#currentFailoverIndex, _currentFailoverIndex),
      returnValueForMissingStub: null);
  @override
  String get host =>
      (super.noSuchMethod(Invocation.getter(#host), returnValue: '') as String);
  @override
  int get port =>
      (super.noSuchMethod(Invocation.getter(#port), returnValue: 0) as int);
  @override
  bool get useSSL =>
      (super.noSuchMethod(Invocation.getter(#useSSL), returnValue: false)
          as bool);
  @override
  _i6.Future<dynamic> request(
          {String? command,
          List<dynamic>? args = const [],
          Duration? connectionTimeout = const Duration(seconds: 60),
          String? requestID,
          int? retries = 2}) =>
      (super.noSuchMethod(
          Invocation.method(#request, [], {
            #command: command,
            #args: args,
            #connectionTimeout: connectionTimeout,
            #requestID: requestID,
            #retries: retries
          }),
          returnValue: Future<dynamic>.value()) as _i6.Future<dynamic>);
  @override
  _i6.Future<List<Map<String, dynamic>>> batchRequest(
          {String? command,
          Map<String, List<dynamic>>? args,
          Duration? connectionTimeout = const Duration(seconds: 60),
          int? retries = 2}) =>
      (super.noSuchMethod(
              Invocation.method(#batchRequest, [], {
                #command: command,
                #args: args,
                #connectionTimeout: connectionTimeout,
                #retries: retries
              }),
              returnValue: Future<List<Map<String, dynamic>>>.value(
                  <Map<String, dynamic>>[]))
          as _i6.Future<List<Map<String, dynamic>>>);
  @override
  _i6.Future<bool> ping({String? requestID, int? retryCount = 1}) =>
      (super.noSuchMethod(
          Invocation.method(
              #ping, [], {#requestID: requestID, #retryCount: retryCount}),
          returnValue: Future<bool>.value(false)) as _i6.Future<bool>);
  @override
  _i6.Future<Map<String, dynamic>> getBlockHeadTip({String? requestID}) =>
      (super.noSuchMethod(
              Invocation.method(#getBlockHeadTip, [], {#requestID: requestID}),
              returnValue:
                  Future<Map<String, dynamic>>.value(<String, dynamic>{}))
          as _i6.Future<Map<String, dynamic>>);
  @override
  _i6.Future<Map<String, dynamic>> getServerFeatures({String? requestID}) =>
      (super.noSuchMethod(
          Invocation.method(#getServerFeatures, [], {#requestID: requestID}),
          returnValue:
              Future<Map<String, dynamic>>.value(<String, dynamic>{})) as _i6
          .Future<Map<String, dynamic>>);
  @override
  _i6.Future<String> broadcastTransaction({String? rawTx, String? requestID}) =>
      (super.noSuchMethod(
          Invocation.method(#broadcastTransaction, [],
              {#rawTx: rawTx, #requestID: requestID}),
          returnValue: Future<String>.value('')) as _i6.Future<String>);
  @override
  _i6.Future<Map<String, dynamic>> getBalance(
          {String? scripthash, String? requestID}) =>
      (super.noSuchMethod(
              Invocation.method(#getBalance, [],
                  {#scripthash: scripthash, #requestID: requestID}),
              returnValue:
                  Future<Map<String, dynamic>>.value(<String, dynamic>{}))
          as _i6.Future<Map<String, dynamic>>);
  @override
  _i6.Future<List<Map<String, dynamic>>> getHistory(
          {String? scripthash, String? requestID}) =>
      (super.noSuchMethod(
              Invocation.method(#getHistory, [],
                  {#scripthash: scripthash, #requestID: requestID}),
              returnValue: Future<List<Map<String, dynamic>>>.value(
                  <Map<String, dynamic>>[]))
          as _i6.Future<List<Map<String, dynamic>>>);
  @override
  _i6.Future<Map<String, List<Map<String, dynamic>>>> getBatchHistory(
          {Map<String, List<dynamic>>? args}) =>
      (super.noSuchMethod(
          Invocation.method(#getBatchHistory, [], {#args: args}),
          returnValue: Future<Map<String, List<Map<String, dynamic>>>>.value(
              <String, List<Map<String, dynamic>>>{})) as _i6
          .Future<Map<String, List<Map<String, dynamic>>>>);
  @override
  _i6.Future<List<Map<String, dynamic>>> getUTXOs(
          {String? scripthash, String? requestID}) =>
      (super.noSuchMethod(
          Invocation.method(
              #getUTXOs, [], {#scripthash: scripthash, #requestID: requestID}),
          returnValue: Future<List<Map<String, dynamic>>>.value(
              <Map<String, dynamic>>[])) as _i6
          .Future<List<Map<String, dynamic>>>);
  @override
  _i6.Future<Map<String, List<Map<String, dynamic>>>> getBatchUTXOs(
          {Map<String, List<dynamic>>? args}) =>
      (super.noSuchMethod(Invocation.method(#getBatchUTXOs, [], {#args: args}),
          returnValue: Future<Map<String, List<Map<String, dynamic>>>>.value(
              <String, List<Map<String, dynamic>>>{})) as _i6
          .Future<Map<String, List<Map<String, dynamic>>>>);
  @override
  _i6.Future<Map<String, dynamic>> getTransaction(
          {String? txHash, bool? verbose = true, String? requestID}) =>
      (super.noSuchMethod(
              Invocation.method(#getTransaction, [],
                  {#txHash: txHash, #verbose: verbose, #requestID: requestID}),
              returnValue:
                  Future<Map<String, dynamic>>.value(<String, dynamic>{}))
          as _i6.Future<Map<String, dynamic>>);
  @override
  _i6.Future<Map<String, dynamic>> getAnonymitySet(
          {String? groupId = r'1',
          String? blockhash = r'',
          String? requestID}) =>
      (super.noSuchMethod(
              Invocation.method(#getAnonymitySet, [], {
                #groupId: groupId,
                #blockhash: blockhash,
                #requestID: requestID
              }),
              returnValue:
                  Future<Map<String, dynamic>>.value(<String, dynamic>{}))
          as _i6.Future<Map<String, dynamic>>);
  @override
  _i6.Future<dynamic> getMintData({dynamic mints, String? requestID}) =>
      (super.noSuchMethod(
          Invocation.method(
              #getMintData, [], {#mints: mints, #requestID: requestID}),
          returnValue: Future<dynamic>.value()) as _i6.Future<dynamic>);
  @override
  _i6.Future<Map<String, dynamic>> getUsedCoinSerials(
          {String? requestID, int? startNumber}) =>
      (super.noSuchMethod(
              Invocation.method(#getUsedCoinSerials, [],
                  {#requestID: requestID, #startNumber: startNumber}),
              returnValue:
                  Future<Map<String, dynamic>>.value(<String, dynamic>{}))
          as _i6.Future<Map<String, dynamic>>);
  @override
  _i6.Future<int> getLatestCoinId({String? requestID}) => (super.noSuchMethod(
      Invocation.method(#getLatestCoinId, [], {#requestID: requestID}),
      returnValue: Future<int>.value(0)) as _i6.Future<int>);
  @override
  _i6.Future<Map<String, dynamic>> getFeeRate({String? requestID}) => (super
      .noSuchMethod(Invocation.method(#getFeeRate, [], {#requestID: requestID}),
          returnValue:
              Future<Map<String, dynamic>>.value(<String, dynamic>{})) as _i6
      .Future<Map<String, dynamic>>);
  @override
  _i6.Future<_i2.Decimal> estimateFee({String? requestID, int? blocks}) =>
      (super.noSuchMethod(
              Invocation.method(
                  #estimateFee, [], {#requestID: requestID, #blocks: blocks}),
              returnValue: Future<_i2.Decimal>.value(_FakeDecimal_0()))
          as _i6.Future<_i2.Decimal>);
  @override
  _i6.Future<_i2.Decimal> relayFee({String? requestID}) => (super.noSuchMethod(
          Invocation.method(#relayFee, [], {#requestID: requestID}),
          returnValue: Future<_i2.Decimal>.value(_FakeDecimal_0()))
      as _i6.Future<_i2.Decimal>);
}

/// A class which mocks [CachedElectrumX].
///
/// See the documentation for Mockito's code generation for more information.
class MockCachedElectrumX extends _i1.Mock implements _i7.CachedElectrumX {
  MockCachedElectrumX() {
    _i1.throwOnMissingStub(this);
  }

  @override
  String get server =>
      (super.noSuchMethod(Invocation.getter(#server), returnValue: '')
          as String);
  @override
  int get port =>
      (super.noSuchMethod(Invocation.getter(#port), returnValue: 0) as int);
  @override
  bool get useSSL =>
      (super.noSuchMethod(Invocation.getter(#useSSL), returnValue: false)
          as bool);
  @override
  _i3.Prefs get prefs => (super.noSuchMethod(Invocation.getter(#prefs),
      returnValue: _FakePrefs_1()) as _i3.Prefs);
  @override
  List<_i5.ElectrumXNode> get failovers =>
      (super.noSuchMethod(Invocation.getter(#failovers),
          returnValue: <_i5.ElectrumXNode>[]) as List<_i5.ElectrumXNode>);
  @override
  _i6.Future<Map<String, dynamic>> getAnonymitySet(
          {String? groupId, String? blockhash = r'', _i8.Coin? coin}) =>
      (super.noSuchMethod(
              Invocation.method(#getAnonymitySet, [],
                  {#groupId: groupId, #blockhash: blockhash, #coin: coin}),
              returnValue:
                  Future<Map<String, dynamic>>.value(<String, dynamic>{}))
          as _i6.Future<Map<String, dynamic>>);
  @override
  _i6.Future<Map<String, dynamic>> getTransaction(
          {String? txHash, _i8.Coin? coin, bool? verbose = true}) =>
      (super.noSuchMethod(
              Invocation.method(#getTransaction, [],
                  {#txHash: txHash, #coin: coin, #verbose: verbose}),
              returnValue:
                  Future<Map<String, dynamic>>.value(<String, dynamic>{}))
          as _i6.Future<Map<String, dynamic>>);
  @override
  _i6.Future<List<dynamic>> getUsedCoinSerials(
          {_i8.Coin? coin, int? startNumber = 0}) =>
      (super.noSuchMethod(
              Invocation.method(#getUsedCoinSerials, [],
                  {#coin: coin, #startNumber: startNumber}),
              returnValue: Future<List<dynamic>>.value(<dynamic>[]))
          as _i6.Future<List<dynamic>>);
  @override
  _i6.Future<void> clearSharedTransactionCache({_i8.Coin? coin}) =>
      (super.noSuchMethod(
          Invocation.method(#clearSharedTransactionCache, [], {#coin: coin}),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value()) as _i6.Future<void>);
}

/// A class which mocks [PriceAPI].
///
/// See the documentation for Mockito's code generation for more information.
class MockPriceAPI extends _i1.Mock implements _i9.PriceAPI {
  MockPriceAPI() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i4.Client get client => (super.noSuchMethod(Invocation.getter(#client),
      returnValue: _FakeClient_2()) as _i4.Client);
  @override
  void resetLastCalledToForceNextCallToUpdateCache() => super.noSuchMethod(
      Invocation.method(#resetLastCalledToForceNextCallToUpdateCache, []),
      returnValueForMissingStub: null);
  @override
  _i6.Future<Map<_i8.Coin, _i10.Tuple2<_i2.Decimal, double>>>
      getPricesAnd24hChange({String? baseCurrency}) => (super.noSuchMethod(
              Invocation.method(
                  #getPricesAnd24hChange, [], {#baseCurrency: baseCurrency}),
              returnValue:
                  Future<Map<_i8.Coin, _i10.Tuple2<_i2.Decimal, double>>>.value(
                      <_i8.Coin, _i10.Tuple2<_i2.Decimal, double>>{}))
          as _i6.Future<Map<_i8.Coin, _i10.Tuple2<_i2.Decimal, double>>>);
}

/// A class which mocks [TransactionNotificationTracker].
///
/// See the documentation for Mockito's code generation for more information.
class MockTransactionNotificationTracker extends _i1.Mock
    implements _i11.TransactionNotificationTracker {
  MockTransactionNotificationTracker() {
    _i1.throwOnMissingStub(this);
  }

  @override
  String get walletId =>
      (super.noSuchMethod(Invocation.getter(#walletId), returnValue: '')
          as String);
  @override
  List<String> get pendings =>
      (super.noSuchMethod(Invocation.getter(#pendings), returnValue: <String>[])
          as List<String>);
  @override
  List<String> get confirmeds => (super
          .noSuchMethod(Invocation.getter(#confirmeds), returnValue: <String>[])
      as List<String>);
  @override
  bool wasNotifiedPending(String? txid) =>
      (super.noSuchMethod(Invocation.method(#wasNotifiedPending, [txid]),
          returnValue: false) as bool);
  @override
  _i6.Future<void> addNotifiedPending(String? txid) =>
      (super.noSuchMethod(Invocation.method(#addNotifiedPending, [txid]),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value()) as _i6.Future<void>);
  @override
  bool wasNotifiedConfirmed(String? txid) =>
      (super.noSuchMethod(Invocation.method(#wasNotifiedConfirmed, [txid]),
          returnValue: false) as bool);
  @override
  _i6.Future<void> addNotifiedConfirmed(String? txid) =>
      (super.noSuchMethod(Invocation.method(#addNotifiedConfirmed, [txid]),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value()) as _i6.Future<void>);
}

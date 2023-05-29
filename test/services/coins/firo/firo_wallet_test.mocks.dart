// Mocks generated by Mockito 5.3.2 from annotations
// in stackwallet/test/services/coins/firo/firo_wallet_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i5;

import 'package:decimal/decimal.dart' as _i2;
import 'package:isar/isar.dart' as _i4;
import 'package:mockito/mockito.dart' as _i1;
import 'package:stackwallet/db/isar/main_db.dart' as _i9;
import 'package:stackwallet/electrumx_rpc/cached_electrumx.dart' as _i6;
import 'package:stackwallet/electrumx_rpc/electrumx.dart' as _i3;
import 'package:stackwallet/models/isar/models/block_explorer.dart' as _i11;
import 'package:stackwallet/models/isar/models/contact_entry.dart' as _i10;
import 'package:stackwallet/models/isar/models/isar_models.dart' as _i12;
import 'package:stackwallet/services/transaction_notification_tracker.dart'
    as _i8;
import 'package:stackwallet/utilities/enums/coin_enum.dart' as _i7;
import 'package:tuple/tuple.dart' as _i13;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeDecimal_0 extends _i1.SmartFake implements _i2.Decimal {
  _FakeDecimal_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeElectrumX_1 extends _i1.SmartFake implements _i3.ElectrumX {
  _FakeElectrumX_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeIsar_2 extends _i1.SmartFake implements _i4.Isar {
  _FakeIsar_2(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeQueryBuilder_3<OBJ, R, S> extends _i1.SmartFake
    implements _i4.QueryBuilder<OBJ, R, S> {
  _FakeQueryBuilder_3(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [ElectrumX].
///
/// See the documentation for Mockito's code generation for more information.
class MockElectrumX extends _i1.Mock implements _i3.ElectrumX {
  MockElectrumX() {
    _i1.throwOnMissingStub(this);
  }

  @override
  set failovers(List<_i3.ElectrumXNode>? _failovers) => super.noSuchMethod(
        Invocation.setter(
          #failovers,
          _failovers,
        ),
        returnValueForMissingStub: null,
      );
  @override
  int get currentFailoverIndex => (super.noSuchMethod(
        Invocation.getter(#currentFailoverIndex),
        returnValue: 0,
      ) as int);
  @override
  set currentFailoverIndex(int? _currentFailoverIndex) => super.noSuchMethod(
        Invocation.setter(
          #currentFailoverIndex,
          _currentFailoverIndex,
        ),
        returnValueForMissingStub: null,
      );
  @override
  String get host => (super.noSuchMethod(
        Invocation.getter(#host),
        returnValue: '',
      ) as String);
  @override
  int get port => (super.noSuchMethod(
        Invocation.getter(#port),
        returnValue: 0,
      ) as int);
  @override
  bool get useSSL => (super.noSuchMethod(
        Invocation.getter(#useSSL),
        returnValue: false,
      ) as bool);
  @override
  _i5.Future<dynamic> request({
    required String? command,
    List<dynamic>? args = const [],
    Duration? connectionTimeout = const Duration(seconds: 60),
    String? requestID,
    int? retries = 2,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #request,
          [],
          {
            #command: command,
            #args: args,
            #connectionTimeout: connectionTimeout,
            #requestID: requestID,
            #retries: retries,
          },
        ),
        returnValue: _i5.Future<dynamic>.value(),
      ) as _i5.Future<dynamic>);
  @override
  _i5.Future<List<Map<String, dynamic>>> batchRequest({
    required String? command,
    required Map<String, List<dynamic>>? args,
    Duration? connectionTimeout = const Duration(seconds: 60),
    int? retries = 2,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #batchRequest,
          [],
          {
            #command: command,
            #args: args,
            #connectionTimeout: connectionTimeout,
            #retries: retries,
          },
        ),
        returnValue: _i5.Future<List<Map<String, dynamic>>>.value(
            <Map<String, dynamic>>[]),
      ) as _i5.Future<List<Map<String, dynamic>>>);
  @override
  _i5.Future<bool> ping({
    String? requestID,
    int? retryCount = 1,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #ping,
          [],
          {
            #requestID: requestID,
            #retryCount: retryCount,
          },
        ),
        returnValue: _i5.Future<bool>.value(false),
      ) as _i5.Future<bool>);
  @override
  _i5.Future<Map<String, dynamic>> getBlockHeadTip({String? requestID}) =>
      (super.noSuchMethod(
        Invocation.method(
          #getBlockHeadTip,
          [],
          {#requestID: requestID},
        ),
        returnValue:
            _i5.Future<Map<String, dynamic>>.value(<String, dynamic>{}),
      ) as _i5.Future<Map<String, dynamic>>);
  @override
  _i5.Future<Map<String, dynamic>> getServerFeatures({String? requestID}) =>
      (super.noSuchMethod(
        Invocation.method(
          #getServerFeatures,
          [],
          {#requestID: requestID},
        ),
        returnValue:
            _i5.Future<Map<String, dynamic>>.value(<String, dynamic>{}),
      ) as _i5.Future<Map<String, dynamic>>);
  @override
  _i5.Future<String> broadcastTransaction({
    required String? rawTx,
    String? requestID,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #broadcastTransaction,
          [],
          {
            #rawTx: rawTx,
            #requestID: requestID,
          },
        ),
        returnValue: _i5.Future<String>.value(''),
      ) as _i5.Future<String>);
  @override
  _i5.Future<Map<String, dynamic>> getBalance({
    required String? scripthash,
    String? requestID,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #getBalance,
          [],
          {
            #scripthash: scripthash,
            #requestID: requestID,
          },
        ),
        returnValue:
            _i5.Future<Map<String, dynamic>>.value(<String, dynamic>{}),
      ) as _i5.Future<Map<String, dynamic>>);
  @override
  _i5.Future<List<Map<String, dynamic>>> getHistory({
    required String? scripthash,
    String? requestID,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #getHistory,
          [],
          {
            #scripthash: scripthash,
            #requestID: requestID,
          },
        ),
        returnValue: _i5.Future<List<Map<String, dynamic>>>.value(
            <Map<String, dynamic>>[]),
      ) as _i5.Future<List<Map<String, dynamic>>>);
  @override
  _i5.Future<Map<String, List<Map<String, dynamic>>>> getBatchHistory(
          {required Map<String, List<dynamic>>? args}) =>
      (super.noSuchMethod(
        Invocation.method(
          #getBatchHistory,
          [],
          {#args: args},
        ),
        returnValue: _i5.Future<Map<String, List<Map<String, dynamic>>>>.value(
            <String, List<Map<String, dynamic>>>{}),
      ) as _i5.Future<Map<String, List<Map<String, dynamic>>>>);
  @override
  _i5.Future<List<Map<String, dynamic>>> getUTXOs({
    required String? scripthash,
    String? requestID,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #getUTXOs,
          [],
          {
            #scripthash: scripthash,
            #requestID: requestID,
          },
        ),
        returnValue: _i5.Future<List<Map<String, dynamic>>>.value(
            <Map<String, dynamic>>[]),
      ) as _i5.Future<List<Map<String, dynamic>>>);
  @override
  _i5.Future<Map<String, List<Map<String, dynamic>>>> getBatchUTXOs(
          {required Map<String, List<dynamic>>? args}) =>
      (super.noSuchMethod(
        Invocation.method(
          #getBatchUTXOs,
          [],
          {#args: args},
        ),
        returnValue: _i5.Future<Map<String, List<Map<String, dynamic>>>>.value(
            <String, List<Map<String, dynamic>>>{}),
      ) as _i5.Future<Map<String, List<Map<String, dynamic>>>>);
  @override
  _i5.Future<Map<String, dynamic>> getTransaction({
    required String? txHash,
    bool? verbose = true,
    String? requestID,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #getTransaction,
          [],
          {
            #txHash: txHash,
            #verbose: verbose,
            #requestID: requestID,
          },
        ),
        returnValue:
            _i5.Future<Map<String, dynamic>>.value(<String, dynamic>{}),
      ) as _i5.Future<Map<String, dynamic>>);
  @override
  _i5.Future<Map<String, dynamic>> getAnonymitySet({
    String? groupId = r'1',
    String? blockhash = r'',
    String? requestID,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #getAnonymitySet,
          [],
          {
            #groupId: groupId,
            #blockhash: blockhash,
            #requestID: requestID,
          },
        ),
        returnValue:
            _i5.Future<Map<String, dynamic>>.value(<String, dynamic>{}),
      ) as _i5.Future<Map<String, dynamic>>);
  @override
  _i5.Future<dynamic> getMintData({
    dynamic mints,
    String? requestID,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #getMintData,
          [],
          {
            #mints: mints,
            #requestID: requestID,
          },
        ),
        returnValue: _i5.Future<dynamic>.value(),
      ) as _i5.Future<dynamic>);
  @override
  _i5.Future<Map<String, dynamic>> getUsedCoinSerials({
    String? requestID,
    required int? startNumber,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #getUsedCoinSerials,
          [],
          {
            #requestID: requestID,
            #startNumber: startNumber,
          },
        ),
        returnValue:
            _i5.Future<Map<String, dynamic>>.value(<String, dynamic>{}),
      ) as _i5.Future<Map<String, dynamic>>);
  @override
  _i5.Future<int> getLatestCoinId({String? requestID}) => (super.noSuchMethod(
        Invocation.method(
          #getLatestCoinId,
          [],
          {#requestID: requestID},
        ),
        returnValue: _i5.Future<int>.value(0),
      ) as _i5.Future<int>);
  @override
  _i5.Future<Map<String, dynamic>> getFeeRate({String? requestID}) =>
      (super.noSuchMethod(
        Invocation.method(
          #getFeeRate,
          [],
          {#requestID: requestID},
        ),
        returnValue:
            _i5.Future<Map<String, dynamic>>.value(<String, dynamic>{}),
      ) as _i5.Future<Map<String, dynamic>>);
  @override
  _i5.Future<_i2.Decimal> estimateFee({
    String? requestID,
    required int? blocks,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #estimateFee,
          [],
          {
            #requestID: requestID,
            #blocks: blocks,
          },
        ),
        returnValue: _i5.Future<_i2.Decimal>.value(_FakeDecimal_0(
          this,
          Invocation.method(
            #estimateFee,
            [],
            {
              #requestID: requestID,
              #blocks: blocks,
            },
          ),
        )),
      ) as _i5.Future<_i2.Decimal>);
  @override
  _i5.Future<_i2.Decimal> relayFee({String? requestID}) => (super.noSuchMethod(
        Invocation.method(
          #relayFee,
          [],
          {#requestID: requestID},
        ),
        returnValue: _i5.Future<_i2.Decimal>.value(_FakeDecimal_0(
          this,
          Invocation.method(
            #relayFee,
            [],
            {#requestID: requestID},
          ),
        )),
      ) as _i5.Future<_i2.Decimal>);
}

/// A class which mocks [CachedElectrumX].
///
/// See the documentation for Mockito's code generation for more information.
class MockCachedElectrumX extends _i1.Mock implements _i6.CachedElectrumX {
  MockCachedElectrumX() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i3.ElectrumX get electrumXClient => (super.noSuchMethod(
        Invocation.getter(#electrumXClient),
        returnValue: _FakeElectrumX_1(
          this,
          Invocation.getter(#electrumXClient),
        ),
      ) as _i3.ElectrumX);
  @override
  _i5.Future<Map<String, dynamic>> getAnonymitySet({
    required String? groupId,
    String? blockhash = r'',
    required _i7.Coin? coin,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #getAnonymitySet,
          [],
          {
            #groupId: groupId,
            #blockhash: blockhash,
            #coin: coin,
          },
        ),
        returnValue:
            _i5.Future<Map<String, dynamic>>.value(<String, dynamic>{}),
      ) as _i5.Future<Map<String, dynamic>>);
  @override
  String base64ToHex(String? source) => (super.noSuchMethod(
        Invocation.method(
          #base64ToHex,
          [source],
        ),
        returnValue: '',
      ) as String);
  @override
  String base64ToReverseHex(String? source) => (super.noSuchMethod(
        Invocation.method(
          #base64ToReverseHex,
          [source],
        ),
        returnValue: '',
      ) as String);
  @override
  _i5.Future<Map<String, dynamic>> getTransaction({
    required String? txHash,
    required _i7.Coin? coin,
    bool? verbose = true,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #getTransaction,
          [],
          {
            #txHash: txHash,
            #coin: coin,
            #verbose: verbose,
          },
        ),
        returnValue:
            _i5.Future<Map<String, dynamic>>.value(<String, dynamic>{}),
      ) as _i5.Future<Map<String, dynamic>>);
  @override
  _i5.Future<List<String>> getUsedCoinSerials({
    required _i7.Coin? coin,
    int? startNumber = 0,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #getUsedCoinSerials,
          [],
          {
            #coin: coin,
            #startNumber: startNumber,
          },
        ),
        returnValue: _i5.Future<List<String>>.value(<String>[]),
      ) as _i5.Future<List<String>>);
  @override
  _i5.Future<void> clearSharedTransactionCache({required _i7.Coin? coin}) =>
      (super.noSuchMethod(
        Invocation.method(
          #clearSharedTransactionCache,
          [],
          {#coin: coin},
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
}

/// A class which mocks [TransactionNotificationTracker].
///
/// See the documentation for Mockito's code generation for more information.
class MockTransactionNotificationTracker extends _i1.Mock
    implements _i8.TransactionNotificationTracker {
  MockTransactionNotificationTracker() {
    _i1.throwOnMissingStub(this);
  }

  @override
  String get walletId => (super.noSuchMethod(
        Invocation.getter(#walletId),
        returnValue: '',
      ) as String);
  @override
  List<String> get pendings => (super.noSuchMethod(
        Invocation.getter(#pendings),
        returnValue: <String>[],
      ) as List<String>);
  @override
  List<String> get confirmeds => (super.noSuchMethod(
        Invocation.getter(#confirmeds),
        returnValue: <String>[],
      ) as List<String>);
  @override
  bool wasNotifiedPending(String? txid) => (super.noSuchMethod(
        Invocation.method(
          #wasNotifiedPending,
          [txid],
        ),
        returnValue: false,
      ) as bool);
  @override
  _i5.Future<void> addNotifiedPending(String? txid) => (super.noSuchMethod(
        Invocation.method(
          #addNotifiedPending,
          [txid],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
  @override
  bool wasNotifiedConfirmed(String? txid) => (super.noSuchMethod(
        Invocation.method(
          #wasNotifiedConfirmed,
          [txid],
        ),
        returnValue: false,
      ) as bool);
  @override
  _i5.Future<void> addNotifiedConfirmed(String? txid) => (super.noSuchMethod(
        Invocation.method(
          #addNotifiedConfirmed,
          [txid],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
  @override
  _i5.Future<void> deleteTransaction(String? txid) => (super.noSuchMethod(
        Invocation.method(
          #deleteTransaction,
          [txid],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
}

/// A class which mocks [MainDB].
///
/// See the documentation for Mockito's code generation for more information.
class MockMainDB extends _i1.Mock implements _i9.MainDB {
  MockMainDB() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i4.Isar get isar => (super.noSuchMethod(
        Invocation.getter(#isar),
        returnValue: _FakeIsar_2(
          this,
          Invocation.getter(#isar),
        ),
      ) as _i4.Isar);
  @override
  _i5.Future<bool> initMainDB({_i4.Isar? mock}) => (super.noSuchMethod(
        Invocation.method(
          #initMainDB,
          [],
          {#mock: mock},
        ),
        returnValue: _i5.Future<bool>.value(false),
      ) as _i5.Future<bool>);
  @override
  List<_i10.ContactEntry> getContactEntries() => (super.noSuchMethod(
        Invocation.method(
          #getContactEntries,
          [],
        ),
        returnValue: <_i10.ContactEntry>[],
      ) as List<_i10.ContactEntry>);
  @override
  _i5.Future<bool> deleteContactEntry({required String? id}) =>
      (super.noSuchMethod(
        Invocation.method(
          #deleteContactEntry,
          [],
          {#id: id},
        ),
        returnValue: _i5.Future<bool>.value(false),
      ) as _i5.Future<bool>);
  @override
  _i5.Future<bool> isContactEntryExists({required String? id}) =>
      (super.noSuchMethod(
        Invocation.method(
          #isContactEntryExists,
          [],
          {#id: id},
        ),
        returnValue: _i5.Future<bool>.value(false),
      ) as _i5.Future<bool>);
  @override
  _i10.ContactEntry? getContactEntry({required String? id}) =>
      (super.noSuchMethod(Invocation.method(
        #getContactEntry,
        [],
        {#id: id},
      )) as _i10.ContactEntry?);
  @override
  _i5.Future<bool> putContactEntry(
          {required _i10.ContactEntry? contactEntry}) =>
      (super.noSuchMethod(
        Invocation.method(
          #putContactEntry,
          [],
          {#contactEntry: contactEntry},
        ),
        returnValue: _i5.Future<bool>.value(false),
      ) as _i5.Future<bool>);
  @override
  _i11.TransactionBlockExplorer? getTransactionBlockExplorer(
          {required _i7.Coin? coin}) =>
      (super.noSuchMethod(Invocation.method(
        #getTransactionBlockExplorer,
        [],
        {#coin: coin},
      )) as _i11.TransactionBlockExplorer?);
  @override
  _i5.Future<int> putTransactionBlockExplorer(
          _i11.TransactionBlockExplorer? explorer) =>
      (super.noSuchMethod(
        Invocation.method(
          #putTransactionBlockExplorer,
          [explorer],
        ),
        returnValue: _i5.Future<int>.value(0),
      ) as _i5.Future<int>);
  @override
  _i4.QueryBuilder<_i12.Address, _i12.Address, _i4.QAfterWhereClause>
      getAddresses(String? walletId) => (super.noSuchMethod(
            Invocation.method(
              #getAddresses,
              [walletId],
            ),
            returnValue: _FakeQueryBuilder_3<_i12.Address, _i12.Address,
                _i4.QAfterWhereClause>(
              this,
              Invocation.method(
                #getAddresses,
                [walletId],
              ),
            ),
          ) as _i4
              .QueryBuilder<_i12.Address, _i12.Address, _i4.QAfterWhereClause>);
  @override
  _i5.Future<int> putAddress(_i12.Address? address) => (super.noSuchMethod(
        Invocation.method(
          #putAddress,
          [address],
        ),
        returnValue: _i5.Future<int>.value(0),
      ) as _i5.Future<int>);
  @override
  _i5.Future<List<int>> putAddresses(List<_i12.Address>? addresses) =>
      (super.noSuchMethod(
        Invocation.method(
          #putAddresses,
          [addresses],
        ),
        returnValue: _i5.Future<List<int>>.value(<int>[]),
      ) as _i5.Future<List<int>>);
  @override
  _i5.Future<List<int>> updateOrPutAddresses(List<_i12.Address>? addresses) =>
      (super.noSuchMethod(
        Invocation.method(
          #updateOrPutAddresses,
          [addresses],
        ),
        returnValue: _i5.Future<List<int>>.value(<int>[]),
      ) as _i5.Future<List<int>>);
  @override
  _i5.Future<_i12.Address?> getAddress(
    String? walletId,
    String? address,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #getAddress,
          [
            walletId,
            address,
          ],
        ),
        returnValue: _i5.Future<_i12.Address?>.value(),
      ) as _i5.Future<_i12.Address?>);
  @override
  _i5.Future<int> updateAddress(
    _i12.Address? oldAddress,
    _i12.Address? newAddress,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #updateAddress,
          [
            oldAddress,
            newAddress,
          ],
        ),
        returnValue: _i5.Future<int>.value(0),
      ) as _i5.Future<int>);
  @override
  _i4.QueryBuilder<_i12.Transaction, _i12.Transaction, _i4.QAfterWhereClause>
      getTransactions(String? walletId) => (super.noSuchMethod(
            Invocation.method(
              #getTransactions,
              [walletId],
            ),
            returnValue: _FakeQueryBuilder_3<_i12.Transaction, _i12.Transaction,
                _i4.QAfterWhereClause>(
              this,
              Invocation.method(
                #getTransactions,
                [walletId],
              ),
            ),
          ) as _i4.QueryBuilder<_i12.Transaction, _i12.Transaction,
              _i4.QAfterWhereClause>);
  @override
  _i5.Future<int> putTransaction(_i12.Transaction? transaction) =>
      (super.noSuchMethod(
        Invocation.method(
          #putTransaction,
          [transaction],
        ),
        returnValue: _i5.Future<int>.value(0),
      ) as _i5.Future<int>);
  @override
  _i5.Future<List<int>> putTransactions(List<_i12.Transaction>? transactions) =>
      (super.noSuchMethod(
        Invocation.method(
          #putTransactions,
          [transactions],
        ),
        returnValue: _i5.Future<List<int>>.value(<int>[]),
      ) as _i5.Future<List<int>>);
  @override
  _i5.Future<_i12.Transaction?> getTransaction(
    String? walletId,
    String? txid,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #getTransaction,
          [
            walletId,
            txid,
          ],
        ),
        returnValue: _i5.Future<_i12.Transaction?>.value(),
      ) as _i5.Future<_i12.Transaction?>);
  @override
  _i5.Stream<_i12.Transaction?> watchTransaction({
    required int? id,
    bool? fireImmediately = false,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #watchTransaction,
          [],
          {
            #id: id,
            #fireImmediately: fireImmediately,
          },
        ),
        returnValue: _i5.Stream<_i12.Transaction?>.empty(),
      ) as _i5.Stream<_i12.Transaction?>);
  @override
  _i4.QueryBuilder<_i12.UTXO, _i12.UTXO, _i4.QAfterWhereClause> getUTXOs(
          String? walletId) =>
      (super.noSuchMethod(
        Invocation.method(
          #getUTXOs,
          [walletId],
        ),
        returnValue:
            _FakeQueryBuilder_3<_i12.UTXO, _i12.UTXO, _i4.QAfterWhereClause>(
          this,
          Invocation.method(
            #getUTXOs,
            [walletId],
          ),
        ),
      ) as _i4.QueryBuilder<_i12.UTXO, _i12.UTXO, _i4.QAfterWhereClause>);
  @override
  _i5.Future<void> putUTXO(_i12.UTXO? utxo) => (super.noSuchMethod(
        Invocation.method(
          #putUTXO,
          [utxo],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
  @override
  _i5.Future<void> putUTXOs(List<_i12.UTXO>? utxos) => (super.noSuchMethod(
        Invocation.method(
          #putUTXOs,
          [utxos],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
  @override
  _i5.Future<void> updateUTXOs(
    String? walletId,
    List<_i12.UTXO>? utxos,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #updateUTXOs,
          [
            walletId,
            utxos,
          ],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
  @override
  _i5.Stream<_i12.UTXO?> watchUTXO({
    required int? id,
    bool? fireImmediately = false,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #watchUTXO,
          [],
          {
            #id: id,
            #fireImmediately: fireImmediately,
          },
        ),
        returnValue: _i5.Stream<_i12.UTXO?>.empty(),
      ) as _i5.Stream<_i12.UTXO?>);
  @override
  _i4.QueryBuilder<_i12.TransactionNote, _i12.TransactionNote,
      _i4.QAfterWhereClause> getTransactionNotes(
          String? walletId) =>
      (super.noSuchMethod(
        Invocation.method(
          #getTransactionNotes,
          [walletId],
        ),
        returnValue: _FakeQueryBuilder_3<_i12.TransactionNote,
            _i12.TransactionNote, _i4.QAfterWhereClause>(
          this,
          Invocation.method(
            #getTransactionNotes,
            [walletId],
          ),
        ),
      ) as _i4.QueryBuilder<_i12.TransactionNote, _i12.TransactionNote,
          _i4.QAfterWhereClause>);
  @override
  _i5.Future<void> putTransactionNote(_i12.TransactionNote? transactionNote) =>
      (super.noSuchMethod(
        Invocation.method(
          #putTransactionNote,
          [transactionNote],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
  @override
  _i5.Future<void> putTransactionNotes(
          List<_i12.TransactionNote>? transactionNotes) =>
      (super.noSuchMethod(
        Invocation.method(
          #putTransactionNotes,
          [transactionNotes],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
  @override
  _i5.Future<_i12.TransactionNote?> getTransactionNote(
    String? walletId,
    String? txid,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #getTransactionNote,
          [
            walletId,
            txid,
          ],
        ),
        returnValue: _i5.Future<_i12.TransactionNote?>.value(),
      ) as _i5.Future<_i12.TransactionNote?>);
  @override
  _i5.Stream<_i12.TransactionNote?> watchTransactionNote({
    required int? id,
    bool? fireImmediately = false,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #watchTransactionNote,
          [],
          {
            #id: id,
            #fireImmediately: fireImmediately,
          },
        ),
        returnValue: _i5.Stream<_i12.TransactionNote?>.empty(),
      ) as _i5.Stream<_i12.TransactionNote?>);
  @override
  _i4.QueryBuilder<_i12.AddressLabel, _i12.AddressLabel, _i4.QAfterWhereClause>
      getAddressLabels(String? walletId) => (super.noSuchMethod(
            Invocation.method(
              #getAddressLabels,
              [walletId],
            ),
            returnValue: _FakeQueryBuilder_3<_i12.AddressLabel,
                _i12.AddressLabel, _i4.QAfterWhereClause>(
              this,
              Invocation.method(
                #getAddressLabels,
                [walletId],
              ),
            ),
          ) as _i4.QueryBuilder<_i12.AddressLabel, _i12.AddressLabel,
              _i4.QAfterWhereClause>);
  @override
  _i5.Future<int> putAddressLabel(_i12.AddressLabel? addressLabel) =>
      (super.noSuchMethod(
        Invocation.method(
          #putAddressLabel,
          [addressLabel],
        ),
        returnValue: _i5.Future<int>.value(0),
      ) as _i5.Future<int>);
  @override
  int putAddressLabelSync(_i12.AddressLabel? addressLabel) =>
      (super.noSuchMethod(
        Invocation.method(
          #putAddressLabelSync,
          [addressLabel],
        ),
        returnValue: 0,
      ) as int);
  @override
  _i5.Future<void> putAddressLabels(List<_i12.AddressLabel>? addressLabels) =>
      (super.noSuchMethod(
        Invocation.method(
          #putAddressLabels,
          [addressLabels],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
  @override
  _i5.Future<_i12.AddressLabel?> getAddressLabel(
    String? walletId,
    String? addressString,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #getAddressLabel,
          [
            walletId,
            addressString,
          ],
        ),
        returnValue: _i5.Future<_i12.AddressLabel?>.value(),
      ) as _i5.Future<_i12.AddressLabel?>);
  @override
  _i12.AddressLabel? getAddressLabelSync(
    String? walletId,
    String? addressString,
  ) =>
      (super.noSuchMethod(Invocation.method(
        #getAddressLabelSync,
        [
          walletId,
          addressString,
        ],
      )) as _i12.AddressLabel?);
  @override
  _i5.Stream<_i12.AddressLabel?> watchAddressLabel({
    required int? id,
    bool? fireImmediately = false,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #watchAddressLabel,
          [],
          {
            #id: id,
            #fireImmediately: fireImmediately,
          },
        ),
        returnValue: _i5.Stream<_i12.AddressLabel?>.empty(),
      ) as _i5.Stream<_i12.AddressLabel?>);
  @override
  _i5.Future<int> updateAddressLabel(_i12.AddressLabel? addressLabel) =>
      (super.noSuchMethod(
        Invocation.method(
          #updateAddressLabel,
          [addressLabel],
        ),
        returnValue: _i5.Future<int>.value(0),
      ) as _i5.Future<int>);
  @override
  _i5.Future<void> deleteWalletBlockchainData(String? walletId) =>
      (super.noSuchMethod(
        Invocation.method(
          #deleteWalletBlockchainData,
          [walletId],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
  @override
  _i5.Future<void> deleteAddressLabels(String? walletId) => (super.noSuchMethod(
        Invocation.method(
          #deleteAddressLabels,
          [walletId],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
  @override
  _i5.Future<void> deleteTransactionNotes(String? walletId) =>
      (super.noSuchMethod(
        Invocation.method(
          #deleteTransactionNotes,
          [walletId],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
  @override
  _i5.Future<void> addNewTransactionData(
    List<_i13.Tuple2<_i12.Transaction, _i12.Address?>>? transactionsData,
    String? walletId,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #addNewTransactionData,
          [
            transactionsData,
            walletId,
          ],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
  @override
  _i4.QueryBuilder<_i12.EthContract, _i12.EthContract, _i4.QWhere>
      getEthContracts() => (super.noSuchMethod(
            Invocation.method(
              #getEthContracts,
              [],
            ),
            returnValue: _FakeQueryBuilder_3<_i12.EthContract, _i12.EthContract,
                _i4.QWhere>(
              this,
              Invocation.method(
                #getEthContracts,
                [],
              ),
            ),
          ) as _i4
              .QueryBuilder<_i12.EthContract, _i12.EthContract, _i4.QWhere>);
  @override
  _i5.Future<_i12.EthContract?> getEthContract(String? contractAddress) =>
      (super.noSuchMethod(
        Invocation.method(
          #getEthContract,
          [contractAddress],
        ),
        returnValue: _i5.Future<_i12.EthContract?>.value(),
      ) as _i5.Future<_i12.EthContract?>);
  @override
  _i12.EthContract? getEthContractSync(String? contractAddress) =>
      (super.noSuchMethod(Invocation.method(
        #getEthContractSync,
        [contractAddress],
      )) as _i12.EthContract?);
  @override
  _i5.Future<int> putEthContract(_i12.EthContract? contract) =>
      (super.noSuchMethod(
        Invocation.method(
          #putEthContract,
          [contract],
        ),
        returnValue: _i5.Future<int>.value(0),
      ) as _i5.Future<int>);
  @override
  _i5.Future<void> putEthContracts(List<_i12.EthContract>? contracts) =>
      (super.noSuchMethod(
        Invocation.method(
          #putEthContracts,
          [contracts],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
}
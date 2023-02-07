// Mocks generated by Mockito 5.3.2 from annotations
// in stackwallet/test/electrumx_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i3;
import 'dart:ui' as _i8;

import 'package:mockito/mockito.dart' as _i1;
import 'package:stackwallet/electrumx_rpc/rpc.dart' as _i2;
import 'package:stackwallet/pages/exchange_view/sub_widgets/exchange_rate_sheet.dart'
    as _i6;
import 'package:stackwallet/utilities/enums/backup_frequency_type.dart' as _i7;
import 'package:stackwallet/utilities/enums/sync_type_enum.dart' as _i5;
import 'package:stackwallet/utilities/prefs.dart' as _i4;

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

class _FakeDuration_0 extends _i1.SmartFake implements Duration {
  _FakeDuration_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [JsonRPC].
///
/// See the documentation for Mockito's code generation for more information.
class MockJsonRPC extends _i1.Mock implements _i2.JsonRPC {
  MockJsonRPC() {
    _i1.throwOnMissingStub(this);
  }

  @override
  bool get useSSL => (super.noSuchMethod(
        Invocation.getter(#useSSL),
        returnValue: false,
      ) as bool);
  @override
  set useSSL(bool? _useSSL) => super.noSuchMethod(
        Invocation.setter(
          #useSSL,
          _useSSL,
        ),
        returnValueForMissingStub: null,
      );
  @override
  String get host => (super.noSuchMethod(
        Invocation.getter(#host),
        returnValue: '',
      ) as String);
  @override
  set host(String? _host) => super.noSuchMethod(
        Invocation.setter(
          #host,
          _host,
        ),
        returnValueForMissingStub: null,
      );
  @override
  int get port => (super.noSuchMethod(
        Invocation.getter(#port),
        returnValue: 0,
      ) as int);
  @override
  set port(int? _port) => super.noSuchMethod(
        Invocation.setter(
          #port,
          _port,
        ),
        returnValueForMissingStub: null,
      );
  @override
  Duration get connectionTimeout => (super.noSuchMethod(
        Invocation.getter(#connectionTimeout),
        returnValue: _FakeDuration_0(
          this,
          Invocation.getter(#connectionTimeout),
        ),
      ) as Duration);
  @override
  set connectionTimeout(Duration? _connectionTimeout) => super.noSuchMethod(
        Invocation.setter(
          #connectionTimeout,
          _connectionTimeout,
        ),
        returnValueForMissingStub: null,
      );
  @override
  _i3.Future<dynamic> request(String? jsonRpcRequest) => (super.noSuchMethod(
        Invocation.method(
          #request,
          [jsonRpcRequest],
        ),
        returnValue: _i3.Future<dynamic>.value(),
      ) as _i3.Future<dynamic>);
}

/// A class which mocks [Prefs].
///
/// See the documentation for Mockito's code generation for more information.
class MockPrefs extends _i1.Mock implements _i4.Prefs {
  MockPrefs() {
    _i1.throwOnMissingStub(this);
  }

  @override
  bool get isInitialized => (super.noSuchMethod(
        Invocation.getter(#isInitialized),
        returnValue: false,
      ) as bool);
  @override
  int get lastUnlockedTimeout => (super.noSuchMethod(
        Invocation.getter(#lastUnlockedTimeout),
        returnValue: 0,
      ) as int);
  @override
  set lastUnlockedTimeout(int? lastUnlockedTimeout) => super.noSuchMethod(
        Invocation.setter(
          #lastUnlockedTimeout,
          lastUnlockedTimeout,
        ),
        returnValueForMissingStub: null,
      );
  @override
  int get lastUnlocked => (super.noSuchMethod(
        Invocation.getter(#lastUnlocked),
        returnValue: 0,
      ) as int);
  @override
  set lastUnlocked(int? lastUnlocked) => super.noSuchMethod(
        Invocation.setter(
          #lastUnlocked,
          lastUnlocked,
        ),
        returnValueForMissingStub: null,
      );
  @override
  int get currentNotificationId => (super.noSuchMethod(
        Invocation.getter(#currentNotificationId),
        returnValue: 0,
      ) as int);
  @override
  List<String> get walletIdsSyncOnStartup => (super.noSuchMethod(
        Invocation.getter(#walletIdsSyncOnStartup),
        returnValue: <String>[],
      ) as List<String>);
  @override
  set walletIdsSyncOnStartup(List<String>? walletIdsSyncOnStartup) =>
      super.noSuchMethod(
        Invocation.setter(
          #walletIdsSyncOnStartup,
          walletIdsSyncOnStartup,
        ),
        returnValueForMissingStub: null,
      );
  @override
  _i5.SyncingType get syncType => (super.noSuchMethod(
        Invocation.getter(#syncType),
        returnValue: _i5.SyncingType.currentWalletOnly,
      ) as _i5.SyncingType);
  @override
  set syncType(_i5.SyncingType? syncType) => super.noSuchMethod(
        Invocation.setter(
          #syncType,
          syncType,
        ),
        returnValueForMissingStub: null,
      );
  @override
  bool get wifiOnly => (super.noSuchMethod(
        Invocation.getter(#wifiOnly),
        returnValue: false,
      ) as bool);
  @override
  set wifiOnly(bool? wifiOnly) => super.noSuchMethod(
        Invocation.setter(
          #wifiOnly,
          wifiOnly,
        ),
        returnValueForMissingStub: null,
      );
  @override
  bool get showFavoriteWallets => (super.noSuchMethod(
        Invocation.getter(#showFavoriteWallets),
        returnValue: false,
      ) as bool);
  @override
  set showFavoriteWallets(bool? showFavoriteWallets) => super.noSuchMethod(
        Invocation.setter(
          #showFavoriteWallets,
          showFavoriteWallets,
        ),
        returnValueForMissingStub: null,
      );
  @override
  String get language => (super.noSuchMethod(
        Invocation.getter(#language),
        returnValue: '',
      ) as String);
  @override
  set language(String? newLanguage) => super.noSuchMethod(
        Invocation.setter(
          #language,
          newLanguage,
        ),
        returnValueForMissingStub: null,
      );
  @override
  String get currency => (super.noSuchMethod(
        Invocation.getter(#currency),
        returnValue: '',
      ) as String);
  @override
  set currency(String? newCurrency) => super.noSuchMethod(
        Invocation.setter(
          #currency,
          newCurrency,
        ),
        returnValueForMissingStub: null,
      );
  @override
  _i6.ExchangeRateType get exchangeRateType => (super.noSuchMethod(
        Invocation.getter(#exchangeRateType),
        returnValue: _i6.ExchangeRateType.estimated,
      ) as _i6.ExchangeRateType);
  @override
  set exchangeRateType(_i6.ExchangeRateType? exchangeRateType) =>
      super.noSuchMethod(
        Invocation.setter(
          #exchangeRateType,
          exchangeRateType,
        ),
        returnValueForMissingStub: null,
      );
  @override
  bool get useBiometrics => (super.noSuchMethod(
        Invocation.getter(#useBiometrics),
        returnValue: false,
      ) as bool);
  @override
  set useBiometrics(bool? useBiometrics) => super.noSuchMethod(
        Invocation.setter(
          #useBiometrics,
          useBiometrics,
        ),
        returnValueForMissingStub: null,
      );
  @override
  bool get hasPin => (super.noSuchMethod(
        Invocation.getter(#hasPin),
        returnValue: false,
      ) as bool);
  @override
  set hasPin(bool? hasPin) => super.noSuchMethod(
        Invocation.setter(
          #hasPin,
          hasPin,
        ),
        returnValueForMissingStub: null,
      );
  @override
  int get familiarity => (super.noSuchMethod(
        Invocation.getter(#familiarity),
        returnValue: 0,
      ) as int);
  @override
  set familiarity(int? familiarity) => super.noSuchMethod(
        Invocation.setter(
          #familiarity,
          familiarity,
        ),
        returnValueForMissingStub: null,
      );
  @override
  bool get showTestNetCoins => (super.noSuchMethod(
        Invocation.getter(#showTestNetCoins),
        returnValue: false,
      ) as bool);
  @override
  set showTestNetCoins(bool? showTestNetCoins) => super.noSuchMethod(
        Invocation.setter(
          #showTestNetCoins,
          showTestNetCoins,
        ),
        returnValueForMissingStub: null,
      );
  @override
  bool get isAutoBackupEnabled => (super.noSuchMethod(
        Invocation.getter(#isAutoBackupEnabled),
        returnValue: false,
      ) as bool);
  @override
  set isAutoBackupEnabled(bool? isAutoBackupEnabled) => super.noSuchMethod(
        Invocation.setter(
          #isAutoBackupEnabled,
          isAutoBackupEnabled,
        ),
        returnValueForMissingStub: null,
      );
  @override
  set autoBackupLocation(String? autoBackupLocation) => super.noSuchMethod(
        Invocation.setter(
          #autoBackupLocation,
          autoBackupLocation,
        ),
        returnValueForMissingStub: null,
      );
  @override
  _i7.BackupFrequencyType get backupFrequencyType => (super.noSuchMethod(
        Invocation.getter(#backupFrequencyType),
        returnValue: _i7.BackupFrequencyType.everyTenMinutes,
      ) as _i7.BackupFrequencyType);
  @override
  set backupFrequencyType(_i7.BackupFrequencyType? backupFrequencyType) =>
      super.noSuchMethod(
        Invocation.setter(
          #backupFrequencyType,
          backupFrequencyType,
        ),
        returnValueForMissingStub: null,
      );
  @override
  set lastAutoBackup(DateTime? lastAutoBackup) => super.noSuchMethod(
        Invocation.setter(
          #lastAutoBackup,
          lastAutoBackup,
        ),
        returnValueForMissingStub: null,
      );
  @override
  bool get hideBlockExplorerWarning => (super.noSuchMethod(
        Invocation.getter(#hideBlockExplorerWarning),
        returnValue: false,
      ) as bool);
  @override
  set hideBlockExplorerWarning(bool? hideBlockExplorerWarning) =>
      super.noSuchMethod(
        Invocation.setter(
          #hideBlockExplorerWarning,
          hideBlockExplorerWarning,
        ),
        returnValueForMissingStub: null,
      );
  @override
  bool get gotoWalletOnStartup => (super.noSuchMethod(
        Invocation.getter(#gotoWalletOnStartup),
        returnValue: false,
      ) as bool);
  @override
  set gotoWalletOnStartup(bool? gotoWalletOnStartup) => super.noSuchMethod(
        Invocation.setter(
          #gotoWalletOnStartup,
          gotoWalletOnStartup,
        ),
        returnValueForMissingStub: null,
      );
  @override
  set startupWalletId(String? startupWalletId) => super.noSuchMethod(
        Invocation.setter(
          #startupWalletId,
          startupWalletId,
        ),
        returnValueForMissingStub: null,
      );
  @override
  bool get externalCalls => (super.noSuchMethod(
        Invocation.getter(#externalCalls),
        returnValue: false,
      ) as bool);
  @override
  set externalCalls(bool? externalCalls) => super.noSuchMethod(
        Invocation.setter(
          #externalCalls,
          externalCalls,
        ),
        returnValueForMissingStub: null,
      );
  @override
  bool get hasListeners => (super.noSuchMethod(
        Invocation.getter(#hasListeners),
        returnValue: false,
      ) as bool);
  @override
  _i3.Future<void> init() => (super.noSuchMethod(
        Invocation.method(
          #init,
          [],
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);
  @override
  _i3.Future<void> incrementCurrentNotificationIndex() => (super.noSuchMethod(
        Invocation.method(
          #incrementCurrentNotificationIndex,
          [],
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);
  @override
  _i3.Future<bool> isExternalCallsSet() => (super.noSuchMethod(
        Invocation.method(
          #isExternalCallsSet,
          [],
        ),
        returnValue: _i3.Future<bool>.value(false),
      ) as _i3.Future<bool>);
  @override
  _i3.Future<void> saveUserID(String? userId) => (super.noSuchMethod(
        Invocation.method(
          #saveUserID,
          [userId],
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);
  @override
  _i3.Future<void> saveSignupEpoch(int? signupEpoch) => (super.noSuchMethod(
        Invocation.method(
          #saveSignupEpoch,
          [signupEpoch],
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);
  @override
  void addListener(_i8.VoidCallback? listener) => super.noSuchMethod(
        Invocation.method(
          #addListener,
          [listener],
        ),
        returnValueForMissingStub: null,
      );
  @override
  void removeListener(_i8.VoidCallback? listener) => super.noSuchMethod(
        Invocation.method(
          #removeListener,
          [listener],
        ),
        returnValueForMissingStub: null,
      );
  @override
  void dispose() => super.noSuchMethod(
        Invocation.method(
          #dispose,
          [],
        ),
        returnValueForMissingStub: null,
      );
  @override
  void notifyListeners() => super.noSuchMethod(
        Invocation.method(
          #notifyListeners,
          [],
        ),
        returnValueForMissingStub: null,
      );
}

// Mocks generated by Mockito 5.4.2 from annotations
// in stackduo/test/screen_tests/settings_view/settings_subviews/wallet_settings_subviews/rename_wallet_view_screen_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i3;

import 'package:mockito/mockito.dart' as _i1;
import 'package:stackduo/services/wallets_service.dart' as _i2;
import 'package:stackduo/utilities/enums/coin_enum.dart' as _i4;

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

/// A class which mocks [WalletsService].
///
/// See the documentation for Mockito's code generation for more information.
class MockWalletsService extends _i1.Mock implements _i2.WalletsService {
  @override
  _i3.Future<Map<String, _i2.WalletInfo>> get walletNames =>
      (super.noSuchMethod(
        Invocation.getter(#walletNames),
        returnValue: _i3.Future<Map<String, _i2.WalletInfo>>.value(
            <String, _i2.WalletInfo>{}),
      ) as _i3.Future<Map<String, _i2.WalletInfo>>);
  @override
  bool get hasListeners => (super.noSuchMethod(
        Invocation.getter(#hasListeners),
        returnValue: false,
      ) as bool);
  @override
  _i3.Future<bool> renameWallet({
    required String? from,
    required String? to,
    required bool? shouldNotifyListeners,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #renameWallet,
          [],
          {
            #from: from,
            #to: to,
            #shouldNotifyListeners: shouldNotifyListeners,
          },
        ),
        returnValue: _i3.Future<bool>.value(false),
      ) as _i3.Future<bool>);
  @override
  Map<String, _i2.WalletInfo> fetchWalletsData() => (super.noSuchMethod(
        Invocation.method(
          #fetchWalletsData,
          [],
        ),
        returnValue: <String, _i2.WalletInfo>{},
      ) as Map<String, _i2.WalletInfo>);
  @override
  _i3.Future<void> addExistingStackWallet({
    required String? name,
    required String? walletId,
    required _i4.Coin? coin,
    required bool? shouldNotifyListeners,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #addExistingStackWallet,
          [],
          {
            #name: name,
            #walletId: walletId,
            #coin: coin,
            #shouldNotifyListeners: shouldNotifyListeners,
          },
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);
  @override
  _i3.Future<String?> addNewWallet({
    required String? name,
    required _i4.Coin? coin,
    required bool? shouldNotifyListeners,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #addNewWallet,
          [],
          {
            #name: name,
            #coin: coin,
            #shouldNotifyListeners: shouldNotifyListeners,
          },
        ),
        returnValue: _i3.Future<String?>.value(),
      ) as _i3.Future<String?>);
  @override
  _i3.Future<List<String>> getFavoriteWalletIds() => (super.noSuchMethod(
        Invocation.method(
          #getFavoriteWalletIds,
          [],
        ),
        returnValue: _i3.Future<List<String>>.value(<String>[]),
      ) as _i3.Future<List<String>>);
  @override
  _i3.Future<void> saveFavoriteWalletIds(List<String>? walletIds) =>
      (super.noSuchMethod(
        Invocation.method(
          #saveFavoriteWalletIds,
          [walletIds],
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);
  @override
  _i3.Future<void> addFavorite(String? walletId) => (super.noSuchMethod(
        Invocation.method(
          #addFavorite,
          [walletId],
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);
  @override
  _i3.Future<void> removeFavorite(String? walletId) => (super.noSuchMethod(
        Invocation.method(
          #removeFavorite,
          [walletId],
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);
  @override
  _i3.Future<void> moveFavorite({
    required int? fromIndex,
    required int? toIndex,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #moveFavorite,
          [],
          {
            #fromIndex: fromIndex,
            #toIndex: toIndex,
          },
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);
  @override
  _i3.Future<bool> checkForDuplicate(String? name) => (super.noSuchMethod(
        Invocation.method(
          #checkForDuplicate,
          [name],
        ),
        returnValue: _i3.Future<bool>.value(false),
      ) as _i3.Future<bool>);
  @override
  _i3.Future<String?> getWalletId(String? walletName) => (super.noSuchMethod(
        Invocation.method(
          #getWalletId,
          [walletName],
        ),
        returnValue: _i3.Future<String?>.value(),
      ) as _i3.Future<String?>);
  @override
  _i3.Future<bool> isMnemonicVerified({required String? walletId}) =>
      (super.noSuchMethod(
        Invocation.method(
          #isMnemonicVerified,
          [],
          {#walletId: walletId},
        ),
        returnValue: _i3.Future<bool>.value(false),
      ) as _i3.Future<bool>);
  @override
  _i3.Future<void> setMnemonicVerified({required String? walletId}) =>
      (super.noSuchMethod(
        Invocation.method(
          #setMnemonicVerified,
          [],
          {#walletId: walletId},
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);
  @override
  _i3.Future<int> deleteWallet(
    String? name,
    bool? shouldNotifyListeners,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #deleteWallet,
          [
            name,
            shouldNotifyListeners,
          ],
        ),
        returnValue: _i3.Future<int>.value(0),
      ) as _i3.Future<int>);
  @override
  _i3.Future<void> refreshWallets(bool? shouldNotifyListeners) =>
      (super.noSuchMethod(
        Invocation.method(
          #refreshWallets,
          [shouldNotifyListeners],
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);
  @override
  void addListener(dynamic listener) => super.noSuchMethod(
        Invocation.method(
          #addListener,
          [listener],
        ),
        returnValueForMissingStub: null,
      );
  @override
  void removeListener(dynamic listener) => super.noSuchMethod(
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

// Mocks generated by Mockito 5.3.2 from annotations
// in stackwallet/test/services/wallets_service_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i3;

import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i4;
import 'package:mockito/mockito.dart' as _i1;
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart'
    as _i2;

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

/// A class which mocks [SecureStorageWrapper].
///
/// See the documentation for Mockito's code generation for more information.
class MockSecureStorageWrapper extends _i1.Mock
    implements _i2.SecureStorageWrapper {
  MockSecureStorageWrapper() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i3.Future<String?> read({
    required String? key,
    _i4.IOSOptions? iOptions,
    _i4.AndroidOptions? aOptions,
    _i4.LinuxOptions? lOptions,
    _i4.WebOptions? webOptions,
    _i4.MacOsOptions? mOptions,
    _i4.WindowsOptions? wOptions,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #read,
          [],
          {
            #key: key,
            #iOptions: iOptions,
            #aOptions: aOptions,
            #lOptions: lOptions,
            #webOptions: webOptions,
            #mOptions: mOptions,
            #wOptions: wOptions,
          },
        ),
        returnValue: _i3.Future<String?>.value(),
      ) as _i3.Future<String?>);
  @override
  _i3.Future<void> write({
    required String? key,
    required String? value,
    _i4.IOSOptions? iOptions,
    _i4.AndroidOptions? aOptions,
    _i4.LinuxOptions? lOptions,
    _i4.WebOptions? webOptions,
    _i4.MacOsOptions? mOptions,
    _i4.WindowsOptions? wOptions,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #write,
          [],
          {
            #key: key,
            #value: value,
            #iOptions: iOptions,
            #aOptions: aOptions,
            #lOptions: lOptions,
            #webOptions: webOptions,
            #mOptions: mOptions,
            #wOptions: wOptions,
          },
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);
  @override
  _i3.Future<void> delete({
    required String? key,
    _i4.IOSOptions? iOptions,
    _i4.AndroidOptions? aOptions,
    _i4.LinuxOptions? lOptions,
    _i4.WebOptions? webOptions,
    _i4.MacOsOptions? mOptions,
    _i4.WindowsOptions? wOptions,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #delete,
          [],
          {
            #key: key,
            #iOptions: iOptions,
            #aOptions: aOptions,
            #lOptions: lOptions,
            #webOptions: webOptions,
            #mOptions: mOptions,
            #wOptions: wOptions,
          },
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);
}

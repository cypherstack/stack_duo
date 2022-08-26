// Mocks generated by Mockito 5.2.0 from annotations
// in stackwallet/test/screen_tests/transaction_subviews/transaction_details_view_screen_test.dart.
// Do not manually edit this file.

import 'dart:async' as _i4;
import 'dart:ui' as _i5;

import 'package:mockito/mockito.dart' as _i1;
import 'package:stackwallet/models/contact.dart' as _i2;
import 'package:stackwallet/services/address_book_service.dart' as _i6;
import 'package:stackwallet/services/locale_service.dart' as _i7;
import 'package:stackwallet/services/notes_service.dart' as _i3;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types

class _FakeContact_0 extends _i1.Fake implements _i2.Contact {}

/// A class which mocks [NotesService].
///
/// See the documentation for Mockito's code generation for more information.
class MockNotesService extends _i1.Mock implements _i3.NotesService {
  @override
  String get walletId =>
      (super.noSuchMethod(Invocation.getter(#walletId), returnValue: '')
          as String);
  @override
  Map<String, String> get notesSync =>
      (super.noSuchMethod(Invocation.getter(#notesSync),
          returnValue: <String, String>{}) as Map<String, String>);
  @override
  _i4.Future<Map<String, String>> get notes => (super.noSuchMethod(
          Invocation.getter(#notes),
          returnValue: Future<Map<String, String>>.value(<String, String>{}))
      as _i4.Future<Map<String, String>>);
  @override
  bool get hasListeners =>
      (super.noSuchMethod(Invocation.getter(#hasListeners), returnValue: false)
          as bool);
  @override
  _i4.Future<Map<String, String>> search(String? text) => (super.noSuchMethod(
          Invocation.method(#search, [text]),
          returnValue: Future<Map<String, String>>.value(<String, String>{}))
      as _i4.Future<Map<String, String>>);
  @override
  _i4.Future<String> getNoteFor({String? txid}) =>
      (super.noSuchMethod(Invocation.method(#getNoteFor, [], {#txid: txid}),
          returnValue: Future<String>.value('')) as _i4.Future<String>);
  @override
  _i4.Future<void> editOrAddNote({String? txid, String? note}) =>
      (super.noSuchMethod(
          Invocation.method(#editOrAddNote, [], {#txid: txid, #note: note}),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value()) as _i4.Future<void>);
  @override
  _i4.Future<void> deleteNote({String? txid}) =>
      (super.noSuchMethod(Invocation.method(#deleteNote, [], {#txid: txid}),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value()) as _i4.Future<void>);
  @override
  void addListener(_i5.VoidCallback? listener) =>
      super.noSuchMethod(Invocation.method(#addListener, [listener]),
          returnValueForMissingStub: null);
  @override
  void removeListener(_i5.VoidCallback? listener) =>
      super.noSuchMethod(Invocation.method(#removeListener, [listener]),
          returnValueForMissingStub: null);
  @override
  void dispose() => super.noSuchMethod(Invocation.method(#dispose, []),
      returnValueForMissingStub: null);
  @override
  void notifyListeners() =>
      super.noSuchMethod(Invocation.method(#notifyListeners, []),
          returnValueForMissingStub: null);
}

/// A class which mocks [AddressBookService].
///
/// See the documentation for Mockito's code generation for more information.
class MockAddressBookService extends _i1.Mock
    implements _i6.AddressBookService {
  @override
  List<_i2.Contact> get contacts =>
      (super.noSuchMethod(Invocation.getter(#contacts),
          returnValue: <_i2.Contact>[]) as List<_i2.Contact>);
  @override
  _i4.Future<List<_i2.Contact>> get addressBookEntries =>
      (super.noSuchMethod(Invocation.getter(#addressBookEntries),
              returnValue: Future<List<_i2.Contact>>.value(<_i2.Contact>[]))
          as _i4.Future<List<_i2.Contact>>);
  @override
  bool get hasListeners =>
      (super.noSuchMethod(Invocation.getter(#hasListeners), returnValue: false)
          as bool);
  @override
  _i2.Contact getContactById(String? id) =>
      (super.noSuchMethod(Invocation.method(#getContactById, [id]),
          returnValue: _FakeContact_0()) as _i2.Contact);
  @override
  _i4.Future<List<_i2.Contact>> search(String? text) =>
      (super.noSuchMethod(Invocation.method(#search, [text]),
              returnValue: Future<List<_i2.Contact>>.value(<_i2.Contact>[]))
          as _i4.Future<List<_i2.Contact>>);
  @override
  bool matches(String? term, _i2.Contact? contact) =>
      (super.noSuchMethod(Invocation.method(#matches, [term, contact]),
          returnValue: false) as bool);
  @override
  _i4.Future<bool> addContact(_i2.Contact? contact) =>
      (super.noSuchMethod(Invocation.method(#addContact, [contact]),
          returnValue: Future<bool>.value(false)) as _i4.Future<bool>);
  @override
  _i4.Future<bool> editContact(_i2.Contact? editedContact) =>
      (super.noSuchMethod(Invocation.method(#editContact, [editedContact]),
          returnValue: Future<bool>.value(false)) as _i4.Future<bool>);
  @override
  _i4.Future<void> removeContact(String? id) =>
      (super.noSuchMethod(Invocation.method(#removeContact, [id]),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value()) as _i4.Future<void>);
  @override
  void addListener(_i5.VoidCallback? listener) =>
      super.noSuchMethod(Invocation.method(#addListener, [listener]),
          returnValueForMissingStub: null);
  @override
  void removeListener(_i5.VoidCallback? listener) =>
      super.noSuchMethod(Invocation.method(#removeListener, [listener]),
          returnValueForMissingStub: null);
  @override
  void dispose() => super.noSuchMethod(Invocation.method(#dispose, []),
      returnValueForMissingStub: null);
  @override
  void notifyListeners() =>
      super.noSuchMethod(Invocation.method(#notifyListeners, []),
          returnValueForMissingStub: null);
}

/// A class which mocks [LocaleService].
///
/// See the documentation for Mockito's code generation for more information.
class MockLocaleService extends _i1.Mock implements _i7.LocaleService {
  @override
  String get locale =>
      (super.noSuchMethod(Invocation.getter(#locale), returnValue: '')
          as String);
  @override
  bool get hasListeners =>
      (super.noSuchMethod(Invocation.getter(#hasListeners), returnValue: false)
          as bool);
  @override
  _i4.Future<void> loadLocale({bool? notify = true}) =>
      (super.noSuchMethod(Invocation.method(#loadLocale, [], {#notify: notify}),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value()) as _i4.Future<void>);
  @override
  void addListener(_i5.VoidCallback? listener) =>
      super.noSuchMethod(Invocation.method(#addListener, [listener]),
          returnValueForMissingStub: null);
  @override
  void removeListener(_i5.VoidCallback? listener) =>
      super.noSuchMethod(Invocation.method(#removeListener, [listener]),
          returnValueForMissingStub: null);
  @override
  void dispose() => super.noSuchMethod(Invocation.method(#dispose, []),
      returnValueForMissingStub: null);
  @override
  void notifyListeners() =>
      super.noSuchMethod(Invocation.method(#notifyListeners, []),
          returnValueForMissingStub: null);
}

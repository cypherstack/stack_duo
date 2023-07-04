import 'package:hive/hive.dart';
import 'package:stack_wallet_backup/secure_storage.dart';
import 'package:stackduo/utilities/logger.dart';

const String kBoxNameDesktopData = "desktopData";
const String _kKeyBlobKey = "swbKeyBlobKeyStringID";
const String _kKeyBlobVersionKey = "swbKeyBlobVersionKeyStringID";

const int kLatestBlobVersion = 2;

String _getMessageFromException(Object exception) {
  if (exception is IncorrectPassphraseOrVersion) {
    return exception.errMsg();
  }
  if (exception is BadDecryption) {
    return exception.errMsg();
  }
  if (exception is InvalidLength) {
    return exception.errMsg();
  }
  if (exception is EncodingError) {
    return exception.errMsg();
  }
  if (exception is VersionError) {
    return exception.errMsg();
  }

  return exception.toString();
}

class DPS {
  StorageCryptoHandler? _handler;

  StorageCryptoHandler get handler {
    if (_handler == null) {
      throw Exception(
          "DPS: attempted to access handler without proper authentication");
    }
    return _handler!;
  }

  DPS();

  Future<void> initFromNew(String passphrase) async {
    if (_handler != null) {
      throw Exception("DPS: attempted to re initialize with new passphrase");
    }

    try {
      _handler = await StorageCryptoHandler.fromNewPassphrase(
        passphrase,
        kLatestBlobVersion,
      );

      await _put(key: _kKeyBlobKey, value: await _handler!.getKeyBlob());
      await _updateStoredKeyBlobVersion(kLatestBlobVersion);
    } catch (e, s) {
      Logging.instance.log(
        "${_getMessageFromException(e)}\n$s",
        level: LogLevel.Error,
      );
      rethrow;
    }
  }

  Future<void> initFromExisting(String passphrase) async {
    if (_handler != null) {
      throw Exception(
          "DPS: attempted to re initialize with existing passphrase");
    }

    try {
      final keyBlob = await _get(key: _kKeyBlobKey);

      if (keyBlob == null) {
        throw Exception(
            "DPS: failed to find keyBlob while attempting to initialize with existing passphrase");
      }
      final blobVersion = await _getStoredKeyBlobVersion();
      _handler = await StorageCryptoHandler.fromExisting(
        passphrase,
        keyBlob,
        blobVersion,
      );
      if (blobVersion < kLatestBlobVersion) {
        // update blob
        await _handler!.resetPassphrase(passphrase, kLatestBlobVersion);
        await _put(key: _kKeyBlobKey, value: await _handler!.getKeyBlob());
        await _updateStoredKeyBlobVersion(kLatestBlobVersion);
      }
    } catch (e, s) {
      Logging.instance.log(
        "${_getMessageFromException(e)}\n$s",
        level: LogLevel.Error,
      );
      throw Exception(_getMessageFromException(e));
    }
  }

  Future<bool> verifyPassphrase(String passphrase) async {
    try {
      final keyBlob = await _get(key: _kKeyBlobKey);

      if (keyBlob == null) {
        // no passphrase key blob found so any passphrase is technically bad
        return false;
      }
      final blobVersion = await _getStoredKeyBlobVersion();
      await StorageCryptoHandler.fromExisting(passphrase, keyBlob, blobVersion);
      // existing passphrase matches key blob
      return true;
    } catch (e, s) {
      Logging.instance.log(
        "${_getMessageFromException(e)}\n$s",
        level: LogLevel.Warning,
      );
      // password is wrong or some other error
      return false;
    }
  }

  Future<bool> changePassphrase(
    String passphraseOld,
    String passphraseNew,
  ) async {
    try {
      final keyBlob = await _get(key: _kKeyBlobKey);

      if (keyBlob == null) {
        // no passphrase key blob found so any passphrase is technically bad
        return false;
      }

      if (!(await verifyPassphrase(passphraseOld))) {
        return false;
      }

      final blobVersion = await _getStoredKeyBlobVersion();
      await _handler!.resetPassphrase(passphraseNew, blobVersion);
      await _put(
        key: _kKeyBlobKey,
        value: await _handler!.getKeyBlob(),
      );
      await _updateStoredKeyBlobVersion(blobVersion);

      // successfully updated passphrase
      return true;
    } catch (e, s) {
      Logging.instance.log(
        "${_getMessageFromException(e)}\n$s",
        level: LogLevel.Warning,
      );
      return false;
    }
  }

  Future<bool> hasPassword() async {
    final keyBlob = await _get(key: _kKeyBlobKey);
    return keyBlob != null;
  }

  Future<int> _getStoredKeyBlobVersion() async {
    final keyBlobVersionString = await _get(key: _kKeyBlobVersionKey);
    return int.tryParse(keyBlobVersionString ?? "1") ?? 1;
  }

  Future<void> _updateStoredKeyBlobVersion(int version) async {
    await _put(key: _kKeyBlobVersionKey, value: version.toString());
  }

  Future<void> _put({required String key, required String value}) async {
    Box<String>? box;
    try {
      box = await Hive.openBox<String>(kBoxNameDesktopData);
      await box.put(key, value);
    } catch (e, s) {
      Logging.instance.log(
        "DPS failed put($key): $e\n$s",
        level: LogLevel.Fatal,
      );
    } finally {
      await box?.close();
    }
  }

  Future<String?> _get({required String key}) async {
    String? value;
    Box<String>? box;
    try {
      box = await Hive.openBox<String>(kBoxNameDesktopData);
      value = box.get(key);
    } catch (e, s) {
      Logging.instance.log(
        "DPS failed get($key): $e\n$s",
        level: LogLevel.Fatal,
      );
    } finally {
      await box?.close();
    }
    return value;
  }

  /// Dangerous. Used in one place and should not be called anywhere else.
  @Deprecated("Don't use this if at all possible")
  Future<void> deleteBox() async {
    await Hive.deleteBoxFromDisk(kBoxNameDesktopData);
  }
}

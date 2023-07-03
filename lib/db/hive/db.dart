import 'dart:isolate';

import 'package:cw_core/wallet_info.dart' as xmr;
import 'package:hive/hive.dart';
import 'package:mutex/mutex.dart';
import 'package:stackduo/models/exchange/response_objects/trade.dart';
import 'package:stackduo/models/node_model.dart';
import 'package:stackduo/models/notification_model.dart';
import 'package:stackduo/models/trade_wallet_lookup.dart';
import 'package:stackduo/services/wallets_service.dart';
import 'package:stackduo/utilities/enums/coin_enum.dart';
import 'package:stackduo/utilities/logger.dart';

class DB {
  // legacy (required for migrations)
  @Deprecated("Left over for migration from old versions of Stack Wallet")
  static const String boxNameAddressBook = "addressBook";
  static const String boxNameTrades = "exchangeTransactionsBox";

  // in use
  // TODO: migrate
  static const String boxNameNodeModels = "nodeModels";
  static const String boxNamePrimaryNodes = "primaryNodes";
  static const String boxNameAllWalletsData = "wallets";
  static const String boxNameNotifications = "notificationModels";
  static const String boxNameWatchedTransactions =
      "watchedTxNotificationModels";
  static const String boxNameWatchedTrades = "watchedTradesNotificationModels";
  static const String boxNameTradesV2 = "exchangeTradesBox";
  static const String boxNameTradeNotes = "tradeNotesBox";
  static const String boxNameTradeLookup = "tradeToTxidLookUpBox";
  static const String boxNameFavoriteWallets = "favoriteWallets";
  static const String boxNameWalletsToDeleteOnStart = "walletsToDeleteOnStart";
  static const String boxNamePriceCache = "priceAPIPrice24hCache";

  // in use (keep for now)
  static const String boxNameDBInfo = "dbInfo";
  static const String boxNamePrefs = "prefs";

  String _boxNameTxCache({required Coin coin}) => "${coin.name}_txCache";

  // firo only
  String _boxNameSetCache({required Coin coin}) =>
      "${coin.name}_anonymitySetCache";
  String _boxNameUsedSerialsCache({required Coin coin}) =>
      "${coin.name}_usedSerialsCache";

  Box<NodeModel>? _boxNodeModels;
  Box<NodeModel>? _boxPrimaryNodes;
  Box<dynamic>? _boxAllWalletsData;
  Box<NotificationModel>? _boxNotifications;
  Box<NotificationModel>? _boxWatchedTransactions;
  Box<NotificationModel>? _boxWatchedTrades;
  Box<Trade>? _boxTradesV2;
  Box<String>? _boxTradeNotes;
  Box<String>? _boxFavoriteWallets;
  Box<xmr.WalletInfo>? _walletInfoSource;
  Box<dynamic>? _boxPrefs;
  Box<TradeWalletLookup>? _boxTradeLookup;
  Box<dynamic>? _boxDBInfo;
  // Box<String>? _boxDesktopData;

  final Map<String, Box<dynamic>> _walletBoxes = {};

  final Map<Coin, Box<dynamic>> _txCacheBoxes = {};
  final Map<Coin, Box<dynamic>> _setCacheBoxes = {};
  final Map<Coin, Box<dynamic>> _usedSerialsCacheBoxes = {};

  // exposed for monero
  Box<xmr.WalletInfo> get moneroWalletInfoBox => _walletInfoSource!;

  // mutex for stack backup
  final mutex = Mutex();

  DB._();
  static final DB _instance = DB._();
  static DB get instance {
    // "This name does not uniquely identify an isolate. Multiple isolates in the same process may have the same debugName."
    // if (Isolate.current.debugName != "main") {
    // TODO: make sure this works properly
    if (Isolate.current.debugName != "main") {
      throw Exception(
          "DB.instance should not be accessed outside the main isolate!");
    }

    return _instance;
  }

  // open hive boxes
  Future<void> init() async {
    if (Hive.isBoxOpen(boxNameDBInfo)) {
      _boxDBInfo = Hive.box<dynamic>(boxNameDBInfo);
    } else {
      _boxDBInfo = await Hive.openBox<dynamic>(boxNameDBInfo);
    }
    await Hive.openBox<String>(boxNameWalletsToDeleteOnStart);

    if (Hive.isBoxOpen(boxNamePrefs)) {
      _boxPrefs = Hive.box<dynamic>(boxNamePrefs);
    } else {
      _boxPrefs = await Hive.openBox<dynamic>(boxNamePrefs);
    }

    if (Hive.isBoxOpen(boxNameNodeModels)) {
      _boxNodeModels = Hive.box<NodeModel>(boxNameNodeModels);
    } else {
      _boxNodeModels = await Hive.openBox<NodeModel>(boxNameNodeModels);
    }

    if (Hive.isBoxOpen(boxNamePrimaryNodes)) {
      _boxPrimaryNodes = Hive.box<NodeModel>(boxNamePrimaryNodes);
    } else {
      _boxPrimaryNodes = await Hive.openBox<NodeModel>(boxNamePrimaryNodes);
    }

    if (Hive.isBoxOpen(boxNameAllWalletsData)) {
      _boxAllWalletsData = Hive.box<dynamic>(boxNameAllWalletsData);
    } else {
      _boxAllWalletsData = await Hive.openBox<dynamic>(boxNameAllWalletsData);
    }

    _boxNotifications =
        await Hive.openBox<NotificationModel>(boxNameNotifications);
    _boxWatchedTransactions =
        await Hive.openBox<NotificationModel>(boxNameWatchedTransactions);
    _boxWatchedTrades =
        await Hive.openBox<NotificationModel>(boxNameWatchedTrades);
    _boxTradesV2 = await Hive.openBox<Trade>(boxNameTradesV2);
    _boxTradeNotes = await Hive.openBox<String>(boxNameTradeNotes);
    _boxTradeLookup = await Hive.openBox<TradeWalletLookup>(boxNameTradeLookup);
    _walletInfoSource =
        await Hive.openBox<xmr.WalletInfo>(xmr.WalletInfo.boxName);
    _boxFavoriteWallets = await Hive.openBox<String>(boxNameFavoriteWallets);

    await Future.wait([
      Hive.openBox<dynamic>(boxNamePriceCache),
      _loadWalletBoxes(),
    ]);
  }

  Future<void> _loadWalletBoxes() async {
    final names = _boxAllWalletsData!.get("names") as Map? ?? {};
    names.removeWhere((name, dyn) {
      final jsonObject = Map<String, dynamic>.from(dyn as Map);
      try {
        Coin.values.byName(jsonObject["coin"] as String);
        return false;
      } catch (e, s) {
        Logging.instance.log(
            "Error, ${jsonObject["coin"]} does not exist, $name wallet cannot be loaded",
            level: LogLevel.Error);
        return true;
      }
    });
    final mapped = Map<String, dynamic>.from(names).map((name, dyn) => MapEntry(
        name, WalletInfo.fromJson(Map<String, dynamic>.from(dyn as Map))));

    for (final entry in mapped.entries) {
      if (Hive.isBoxOpen(entry.value.walletId)) {
        _walletBoxes[entry.value.walletId] =
            Hive.box<dynamic>(entry.value.walletId);
      } else {
        _walletBoxes[entry.value.walletId] =
            await Hive.openBox<dynamic>(entry.value.walletId);
      }
    }
  }

  Future<Box<dynamic>> getTxCacheBox({required Coin coin}) async {
    return _txCacheBoxes[coin] ??=
        await Hive.openBox<dynamic>(_boxNameTxCache(coin: coin));
  }

  Future<void> closeTxCacheBox({required Coin coin}) async {
    await _txCacheBoxes[coin]?.close();
  }

  Future<Box<dynamic>> getAnonymitySetCacheBox({required Coin coin}) async {
    return _setCacheBoxes[coin] ??=
        await Hive.openBox<dynamic>(_boxNameSetCache(coin: coin));
  }

  Future<void> closeAnonymitySetCacheBox({required Coin coin}) async {
    await _setCacheBoxes[coin]?.close();
  }

  Future<Box<dynamic>> getUsedSerialsCacheBox({required Coin coin}) async {
    return _usedSerialsCacheBoxes[coin] ??=
        await Hive.openBox<dynamic>(_boxNameUsedSerialsCache(coin: coin));
  }

  Future<void> closeUsedSerialsCacheBox({required Coin coin}) async {
    await _usedSerialsCacheBoxes[coin]?.close();
  }

  /// Clear all cached transactions for the specified coin
  Future<void> clearSharedTransactionCache({required Coin coin}) async {
    await deleteAll<dynamic>(boxName: _boxNameTxCache(coin: coin));
    if (coin == Coin.firo) {
      await deleteAll<dynamic>(boxName: _boxNameSetCache(coin: coin));
      await deleteAll<dynamic>(boxName: _boxNameUsedSerialsCache(coin: coin));
    }
  }

  /////////////////////////////////////////

  Future<void> addWalletBox({required String walletId}) async {
    if (_walletBoxes[walletId] != null) {
      throw Exception("Attempted overwrite of existing wallet box!");
    }
    _walletBoxes[walletId] = await Hive.openBox<dynamic>(walletId);
  }

  Future<void> removeWalletBox({required String walletId}) async {
    _walletBoxes.remove(walletId);
  }

  ///////////////////////////////////////////

  // reads

  List<dynamic> keys<T>({required String boxName}) =>
      Hive.box<T>(boxName).keys.toList(growable: false);

  List<T> values<T>({required String boxName}) =>
      Hive.box<T>(boxName).values.toList(growable: false);

  T? get<T>({
    required String boxName,
    required dynamic key,
  }) =>
      Hive.box<T>(boxName).get(key);

  bool containsKey<T>({required String boxName, required dynamic key}) =>
      Hive.box<T>(boxName).containsKey(key);

  // writes

  Future<void> put<T>(
          {required String boxName,
          required dynamic key,
          required T value}) async =>
      await mutex
          .protect(() async => await Hive.box<T>(boxName).put(key, value));

  Future<void> add<T>({required String boxName, required T value}) async =>
      await mutex.protect(() async => await Hive.box<T>(boxName).add(value));

  Future<void> addAll<T>(
          {required String boxName, required Iterable<T> values}) async =>
      await mutex
          .protect(() async => await Hive.box<T>(boxName).addAll(values));

  Future<void> delete<T>(
          {required dynamic key, required String boxName}) async =>
      await mutex.protect(() async => await Hive.box<T>(boxName).delete(key));

  Future<void> deleteAll<T>({required String boxName}) async =>
      await mutex.protect(() async => await Hive.box<T>(boxName).clear());

  Future<void> deleteBoxFromDisk({required String boxName}) async =>
      await mutex.protect(() async => await Hive.deleteBoxFromDisk(boxName));

  ///////////////////////////////////////////////////////////////////////////
  Future<bool> deleteEverything() async {
    try {
      await DB.instance.deleteBoxFromDisk(boxName: DB.boxNameAddressBook);
      await DB.instance.deleteBoxFromDisk(boxName: "debugInfoBox");
      await DB.instance.deleteBoxFromDisk(boxName: DB.boxNameNodeModels);
      await DB.instance.deleteBoxFromDisk(boxName: DB.boxNamePrimaryNodes);
      await DB.instance.deleteBoxFromDisk(boxName: DB.boxNameAllWalletsData);
      await DB.instance.deleteBoxFromDisk(boxName: DB.boxNameNotifications);
      await DB.instance
          .deleteBoxFromDisk(boxName: DB.boxNameWatchedTransactions);
      await DB.instance.deleteBoxFromDisk(boxName: DB.boxNameWatchedTrades);
      await DB.instance.deleteBoxFromDisk(boxName: DB.boxNameTrades);
      await DB.instance.deleteBoxFromDisk(boxName: DB.boxNameTradesV2);
      await DB.instance.deleteBoxFromDisk(boxName: DB.boxNameTradeNotes);
      await DB.instance.deleteBoxFromDisk(boxName: DB.boxNameTradeLookup);
      await DB.instance.deleteBoxFromDisk(boxName: DB.boxNameFavoriteWallets);
      await DB.instance.deleteBoxFromDisk(boxName: DB.boxNamePrefs);
      await DB.instance
          .deleteBoxFromDisk(boxName: DB.boxNameWalletsToDeleteOnStart);
      await DB.instance.deleteBoxFromDisk(boxName: DB.boxNamePriceCache);
      await DB.instance.deleteBoxFromDisk(boxName: DB.boxNameDBInfo);
      await DB.instance.deleteBoxFromDisk(boxName: "theme");
      return true;
    } catch (e, s) {
      Logging.instance.log("$e $s", level: LogLevel.Error);
      return false;
    }
  }
}

abstract class DBKeys {
  static const String cachedBalance = "cachedBalance";
  static const String cachedBalanceSecondary = "cachedBalanceSecondary";
  static const String isFavorite = "isFavorite";
  static const String id = "id";
  static const String storedChainHeight = "storedChainHeight";
}

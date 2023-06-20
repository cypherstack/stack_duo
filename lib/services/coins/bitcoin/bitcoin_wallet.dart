import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bech32/bech32.dart';
import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:bitcoindart/bitcoindart.dart';
import 'package:bs58check/bs58check.dart' as bs58check;
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:stackduo/db/isar/main_db.dart';
import 'package:stackduo/electrumx_rpc/cached_electrumx.dart';
import 'package:stackduo/electrumx_rpc/electrumx.dart';
import 'package:stackduo/exceptions/electrumx/no_such_transaction.dart';
import 'package:stackduo/models/balance.dart';
import 'package:stackduo/models/isar/models/isar_models.dart' as isar_models;
import 'package:stackduo/models/paymint/fee_object_model.dart';
import 'package:stackduo/models/signing_data.dart';
import 'package:stackduo/services/coins/coin_service.dart';
import 'package:stackduo/services/event_bus/events/global/node_connection_status_changed_event.dart';
import 'package:stackduo/services/event_bus/events/global/refresh_percent_changed_event.dart';
import 'package:stackduo/services/event_bus/events/global/updated_in_background_event.dart';
import 'package:stackduo/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackduo/services/event_bus/global_event_bus.dart';
import 'package:stackduo/services/mixins/coin_control_interface.dart';
import 'package:stackduo/services/mixins/electrum_x_parsing.dart';
import 'package:stackduo/services/mixins/paynym_wallet_interface.dart';
import 'package:stackduo/services/mixins/wallet_cache.dart';
import 'package:stackduo/services/mixins/wallet_db.dart';
import 'package:stackduo/services/mixins/xpubable.dart';
import 'package:stackduo/services/node_service.dart';
import 'package:stackduo/services/transaction_notification_tracker.dart';
import 'package:stackduo/utilities/address_utils.dart';
import 'package:stackduo/utilities/amount/amount.dart';
import 'package:stackduo/utilities/bip32_utils.dart';
import 'package:stackduo/utilities/constants.dart';
import 'package:stackduo/utilities/default_nodes.dart';
import 'package:stackduo/utilities/enums/coin_enum.dart';
import 'package:stackduo/utilities/enums/derive_path_type_enum.dart';
import 'package:stackduo/utilities/enums/fee_rate_type_enum.dart';
import 'package:stackduo/utilities/flutter_secure_storage_interface.dart';
import 'package:stackduo/utilities/format.dart';
import 'package:stackduo/utilities/logger.dart';
import 'package:stackduo/utilities/paynym_is_api.dart';
import 'package:stackduo/utilities/prefs.dart';
import 'package:stackduo/widgets/crypto_notifications.dart';
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';

const int MINIMUM_CONFIRMATIONS = 1;
final Amount DUST_LIMIT = Amount(
  rawValue: BigInt.from(294),
  fractionDigits: Coin.bitcoin.decimals,
);
final Amount DUST_LIMIT_P2PKH = Amount(
  rawValue: BigInt.from(546),
  fractionDigits: Coin.bitcoin.decimals,
);

const String GENESIS_HASH_MAINNET =
    "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f";
const String GENESIS_HASH_TESTNET =
    "000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943";

String constructDerivePath({
  required DerivePathType derivePathType,
  required int networkWIF,
  int account = 0,
  required int chain,
  required int index,
}) {
  String coinType;
  switch (networkWIF) {
    case 0x80: // btc mainnet wif
      coinType = "0"; // btc mainnet
      break;
    case 0xef: // btc testnet wif
      coinType = "1"; // btc testnet
      break;
    default:
      throw Exception("Invalid Bitcoin network wif used!");
  }

  int purpose;
  switch (derivePathType) {
    case DerivePathType.bip44:
      purpose = 44;
      break;
    case DerivePathType.bip49:
      purpose = 49;
      break;
    case DerivePathType.bip84:
      purpose = 84;
      break;
    default:
      throw Exception("DerivePathType $derivePathType not supported");
  }

  return "m/$purpose'/$coinType'/$account'/$chain/$index";
}

class BitcoinWallet extends CoinServiceAPI
    with
        WalletCache,
        WalletDB,
        ElectrumXParsing,
        PaynymWalletInterface,
        CoinControlInterface
    implements XPubAble {
  BitcoinWallet({
    required String walletId,
    required String walletName,
    required Coin coin,
    required ElectrumX client,
    required CachedElectrumX cachedClient,
    required TransactionNotificationTracker tracker,
    required SecureStorageInterface secureStore,
    MainDB? mockableOverride,
  }) {
    txTracker = tracker;
    _walletId = walletId;
    _walletName = walletName;
    _coin = coin;
    _electrumXClient = client;
    _cachedElectrumXClient = cachedClient;
    _secureStore = secureStore;
    initCache(walletId, coin);
    initWalletDB(mockableOverride: mockableOverride);
    initCoinControlInterface(
      walletId: walletId,
      walletName: walletName,
      coin: coin,
      db: db,
      getChainHeight: () => chainHeight,
      refreshedBalanceCallback: (balance) async {
        _balance = balance;
        await updateCachedBalance(_balance!);
      },
    );
    initPaynymWalletInterface(
      walletId: walletId,
      walletName: walletName,
      network: _network,
      coin: coin,
      db: db,
      electrumXClient: electrumXClient,
      secureStorage: secureStore,
      getMnemonicString: () => mnemonicString,
      getMnemonicPassphrase: () => mnemonicPassphrase,
      getChainHeight: () => chainHeight,
      // getCurrentChangeAddress: () => currentChangeAddressP2PKH,
      getCurrentChangeAddress: () => currentChangeAddress,
      estimateTxFee: estimateTxFee,
      prepareSend: prepareSend,
      getTxCount: getTxCount,
      fetchBuildTxData: fetchBuildTxData,
      refresh: refresh,
      checkChangeAddressForTransactions: _checkChangeAddressForTransactions,
      // checkChangeAddressForTransactions:
      //     _checkP2PKHChangeAddressForTransactions,
      dustLimitP2PKH: DUST_LIMIT_P2PKH.raw.toInt(),
      minConfirms: MINIMUM_CONFIRMATIONS,
      dustLimit: DUST_LIMIT.raw.toInt(),
    );
  }

  static const integrationTestFlag =
      bool.fromEnvironment("IS_INTEGRATION_TEST");

  final _prefs = Prefs.instance;

  Timer? timer;
  late final Coin _coin;

  late final TransactionNotificationTracker txTracker;

  NetworkType get _network {
    switch (coin) {
      case Coin.bitcoin:
        return bitcoin;
      case Coin.bitcoinTestNet:
        return testnet;
      default:
        throw Exception("Invalid network type!");
    }
  }

  @override
  set isFavorite(bool markFavorite) {
    _isFavorite = markFavorite;
    updateCachedIsFavorite(markFavorite);
  }

  @override
  bool get isFavorite => _isFavorite ??= getCachedIsFavorite();

  bool? _isFavorite;

  @override
  Coin get coin => _coin;

  @override
  Future<List<isar_models.UTXO>> get utxos => db.getUTXOs(walletId).findAll();

  @override
  Future<List<isar_models.Transaction>> get transactions => db
      .getTransactions(walletId)
      .filter()
      .not()
      .group((q) => q
          .subTypeEqualTo(isar_models.TransactionSubType.bip47Notification)
          .and()
          .typeEqualTo(isar_models.TransactionType.incoming))
      .sortByTimestampDesc()
      .findAll();

  @override
  Future<String> get currentReceivingAddress async =>
      (await _currentReceivingAddress).value;

  Future<isar_models.Address> get _currentReceivingAddress async =>
      (await db
          .getAddresses(walletId)
          .filter()
          .typeEqualTo(isar_models.AddressType.p2wpkh)
          .subTypeEqualTo(isar_models.AddressSubType.receiving)
          .sortByDerivationIndexDesc()
          .findFirst()) ??
      await _generateAddressForChain(0, 0, DerivePathTypeExt.primaryFor(coin));

  Future<String> get currentChangeAddress async =>
      (await _currentChangeAddress).value;

  Future<isar_models.Address> get _currentChangeAddress async =>
      (await db
          .getAddresses(walletId)
          .filter()
          .typeEqualTo(isar_models.AddressType.p2wpkh)
          .subTypeEqualTo(isar_models.AddressSubType.change)
          .sortByDerivationIndexDesc()
          .findFirst()) ??
      await _generateAddressForChain(1, 0, DerivePathTypeExt.primaryFor(coin));

  Future<String> get currentChangeAddressP2PKH async =>
      (await _currentChangeAddressP2PKH).value;

  Future<isar_models.Address> get _currentChangeAddressP2PKH async =>
      (await db
          .getAddresses(walletId)
          .filter()
          .typeEqualTo(isar_models.AddressType.p2pkh)
          .subTypeEqualTo(isar_models.AddressSubType.change)
          .sortByDerivationIndexDesc()
          .findFirst()) ??
      await _generateAddressForChain(1, 0, DerivePathType.bip44);

  @override
  Future<void> exit() async {
    _hasCalledExit = true;
    timer?.cancel();
    timer = null;
    stopNetworkAlivePinging();
  }

  bool _hasCalledExit = false;

  @override
  bool get hasCalledExit => _hasCalledExit;

  @override
  Future<FeeObject> get fees => _feeObject ??= _getFees();
  Future<FeeObject>? _feeObject;

  @override
  Future<int> get maxFee async {
    final fee = (await fees).fast as String;
    final satsFee = Decimal.parse(fee) *
        Decimal.fromInt(Constants.satsPerCoin(coin).toInt());
    return satsFee.floor().toBigInt().toInt();
  }

  @override
  Future<List<String>> get mnemonic => _getMnemonicList();

  @override
  Future<String?> get mnemonicString =>
      _secureStore.read(key: '${_walletId}_mnemonic');

  @override
  Future<String?> get mnemonicPassphrase => _secureStore.read(
        key: '${_walletId}_mnemonicPassphrase',
      );

  Future<int> get chainHeight async {
    try {
      final result = await _electrumXClient.getBlockHeadTip();
      final height = result["height"] as int;
      await updateCachedChainHeight(height);
      if (height > storedChainHeight) {
        GlobalEventBus.instance.fire(
          UpdatedInBackgroundEvent(
            "Updated current chain height in $walletId $walletName!",
            walletId,
          ),
        );
      }
      return height;
    } catch (e, s) {
      Logging.instance.log("Exception caught in chainHeight: $e\n$s",
          level: LogLevel.Error);
      return storedChainHeight;
    }
  }

  @override
  int get storedChainHeight => getCachedChainHeight();

  DerivePathType addressType({required String address}) {
    Uint8List? decodeBase58;
    Segwit? decodeBech32;
    try {
      decodeBase58 = bs58check.decode(address);
    } catch (err) {
      // Base58check decode fail
    }
    if (decodeBase58 != null) {
      if (decodeBase58[0] == _network.pubKeyHash) {
        // P2PKH
        return DerivePathType.bip44;
      }
      if (decodeBase58[0] == _network.scriptHash) {
        // P2SH
        return DerivePathType.bip49;
      }
      throw ArgumentError('Invalid version or Network mismatch');
    } else {
      try {
        decodeBech32 = segwit.decode(address);
      } catch (err) {
        // Bech32 decode fail
      }
      if (_network.bech32 != decodeBech32!.hrp) {
        throw ArgumentError('Invalid prefix or Network mismatch');
      }
      if (decodeBech32.version != 0) {
        throw ArgumentError('Invalid address version');
      }
      // P2WPKH
      return DerivePathType.bip84;
    }
  }

  bool longMutex = false;

  @override
  Future<void> recoverFromMnemonic({
    required String mnemonic,
    String? mnemonicPassphrase,
    required int maxUnusedAddressGap,
    required int maxNumberOfIndexesToCheck,
    required int height,
  }) async {
    longMutex = true;
    final start = DateTime.now();
    try {
      Logging.instance.log("IS_INTEGRATION_TEST: $integrationTestFlag",
          level: LogLevel.Info);
      if (!integrationTestFlag) {
        final features = await electrumXClient.getServerFeatures();
        Logging.instance.log("features: $features", level: LogLevel.Info);
        switch (coin) {
          case Coin.bitcoin:
            if (features['genesis_hash'] != GENESIS_HASH_MAINNET) {
              throw Exception("genesis hash does not match main net!");
            }
            break;
          case Coin.bitcoinTestNet:
            if (features['genesis_hash'] != GENESIS_HASH_TESTNET) {
              throw Exception("genesis hash does not match test net!");
            }
            break;
          default:
            throw Exception(
                "Attempted to generate a BitcoinWallet using a non bitcoin coin type: ${coin.name}");
        }
      }
      // check to make sure we aren't overwriting a mnemonic
      // this should never fail
      if ((await mnemonicString) != null ||
          (await this.mnemonicPassphrase) != null) {
        longMutex = false;
        throw Exception("Attempted to overwrite mnemonic on restore!");
      }
      await _secureStore.write(
          key: '${_walletId}_mnemonic', value: mnemonic.trim());
      await _secureStore.write(
        key: '${_walletId}_mnemonicPassphrase',
        value: mnemonicPassphrase ?? "",
      );

      await _recoverWalletFromBIP32SeedPhrase(
        mnemonic: mnemonic.trim(),
        mnemonicPassphrase: mnemonicPassphrase ?? "",
        maxUnusedAddressGap: maxUnusedAddressGap,
        maxNumberOfIndexesToCheck: maxNumberOfIndexesToCheck,
      );
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from recoverFromMnemonic(): $e\n$s",
          level: LogLevel.Error);
      longMutex = false;
      rethrow;
    }
    longMutex = false;

    final end = DateTime.now();
    Logging.instance.log(
        "$walletName recovery time: ${end.difference(start).inMilliseconds} millis",
        level: LogLevel.Info);
  }

  Future<Tuple3<List<isar_models.Address>, DerivePathType, int>> _checkGaps(
    int maxNumberOfIndexesToCheck,
    int maxUnusedAddressGap,
    int txCountBatchSize,
    bip32.BIP32 root,
    DerivePathType type,
    int chain,
  ) async {
    List<isar_models.Address> addressArray = [];
    int gapCounter = 0;
    int highestIndexWithHistory = 0;

    for (int index = 0;
        index < maxNumberOfIndexesToCheck && gapCounter < maxUnusedAddressGap;
        index += txCountBatchSize) {
      List<String> iterationsAddressArray = [];
      Logging.instance.log(
          "index: $index, \t GapCounter $chain ${type.name}: $gapCounter",
          level: LogLevel.Info);

      final _id = "k_$index";
      Map<String, String> txCountCallArgs = {};

      for (int j = 0; j < txCountBatchSize; j++) {
        final derivePath = constructDerivePath(
          derivePathType: type,
          networkWIF: root.network.wif,
          chain: chain,
          index: index + j,
        );
        final node = await Bip32Utils.getBip32NodeFromRoot(root, derivePath);

        String addressString;
        final data = PaymentData(pubkey: node.publicKey);
        isar_models.AddressType addrType;
        switch (type) {
          case DerivePathType.bip44:
            addressString = P2PKH(data: data, network: _network).data.address!;
            addrType = isar_models.AddressType.p2pkh;
            break;
          case DerivePathType.bip49:
            addressString = P2SH(
                    data: PaymentData(
                        redeem: P2WPKH(data: data, network: _network).data),
                    network: _network)
                .data
                .address!;
            addrType = isar_models.AddressType.p2sh;
            break;
          case DerivePathType.bip84:
            addressString = P2WPKH(network: _network, data: data).data.address!;
            addrType = isar_models.AddressType.p2wpkh;
            break;
          default:
            throw Exception("DerivePathType $type not supported");
        }

        final address = isar_models.Address(
          walletId: walletId,
          value: addressString,
          publicKey: node.publicKey,
          type: addrType,
          derivationIndex: index + j,
          derivationPath: isar_models.DerivationPath()..value = derivePath,
          subType: chain == 0
              ? isar_models.AddressSubType.receiving
              : isar_models.AddressSubType.change,
        );

        addressArray.add(address);

        txCountCallArgs.addAll({
          "${_id}_$j": addressString,
        });
      }

      // get address tx counts
      final counts = await _getBatchTxCount(addresses: txCountCallArgs);

      // check and add appropriate addresses
      for (int k = 0; k < txCountBatchSize; k++) {
        int count = counts["${_id}_$k"]!;
        if (count > 0) {
          iterationsAddressArray.add(txCountCallArgs["${_id}_$k"]!);

          // update highest
          highestIndexWithHistory = index + k;

          // reset counter
          gapCounter = 0;
        }

        // increase counter when no tx history found
        if (count == 0) {
          gapCounter++;
        }
      }
      // cache all the transactions while waiting for the current function to finish.
      unawaited(getTransactionCacheEarly(iterationsAddressArray));
    }
    return Tuple3(addressArray, type, highestIndexWithHistory);
  }

  Future<void> getTransactionCacheEarly(List<String> allAddresses) async {
    try {
      final List<Map<String, dynamic>> allTxHashes =
          await _fetchHistory(allAddresses);
      for (final txHash in allTxHashes) {
        try {
          unawaited(cachedElectrumXClient.getTransaction(
            txHash: txHash["tx_hash"] as String,
            verbose: true,
            coin: coin,
          ));
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      //
    }
  }

  Future<void> _recoverWalletFromBIP32SeedPhrase({
    required String mnemonic,
    required String mnemonicPassphrase,
    int maxUnusedAddressGap = 20,
    int maxNumberOfIndexesToCheck = 1000,
    bool isRescan = false,
  }) async {
    longMutex = true;

    final root = await Bip32Utils.getBip32Root(
      mnemonic,
      mnemonicPassphrase,
      _network,
    );

    final deriveTypes = [
      DerivePathType.bip44,
      DerivePathType.bip49,
      DerivePathType.bip84,
    ];

    final List<Future<Tuple3<List<isar_models.Address>, DerivePathType, int>>>
        receiveFutures = [];
    final List<Future<Tuple3<List<isar_models.Address>, DerivePathType, int>>>
        changeFutures = [];

    const receiveChain = 0;
    const changeChain = 1;
    const indexZero = 0;

    // actual size is 36 due to p2pkh, p2sh, and p2wpkh so 12x3
    const txCountBatchSize = 12;

    try {
      // receiving addresses
      Logging.instance.log(
        "checking receiving addresses...",
        level: LogLevel.Info,
      );

      for (final type in deriveTypes) {
        receiveFutures.add(
          _checkGaps(
            maxNumberOfIndexesToCheck,
            maxUnusedAddressGap,
            txCountBatchSize,
            root,
            type,
            receiveChain,
          ),
        );
      }

      // change addresses
      Logging.instance.log(
        "checking change addresses...",
        level: LogLevel.Info,
      );
      for (final type in deriveTypes) {
        changeFutures.add(
          _checkGaps(
            maxNumberOfIndexesToCheck,
            maxUnusedAddressGap,
            txCountBatchSize,
            root,
            type,
            changeChain,
          ),
        );
      }

      // io limitations may require running these linearly instead
      final futuresResult = await Future.wait([
        Future.wait(receiveFutures),
        Future.wait(changeFutures),
      ]);

      final receiveResults = futuresResult[0];
      final changeResults = futuresResult[1];

      final List<isar_models.Address> addressesToStore = [];

      int highestReceivingIndexWithHistory = 0;
      // If restoring a wallet that never received any funds, then set receivingArray manually
      // If we didn't do this, it'd store an empty array
      for (final tuple in receiveResults) {
        if (tuple.item1.isEmpty) {
          final address = await _generateAddressForChain(
            receiveChain,
            indexZero,
            tuple.item2,
          );
          addressesToStore.add(address);
        } else {
          highestReceivingIndexWithHistory =
              max(tuple.item3, highestReceivingIndexWithHistory);
          addressesToStore.addAll(tuple.item1);
        }
      }

      int highestChangeIndexWithHistory = 0;
      // If restoring a wallet that never sent any funds with change, then set changeArray
      // manually. If we didn't do this, it'd store an empty array.
      for (final tuple in changeResults) {
        if (tuple.item1.isEmpty) {
          final address = await _generateAddressForChain(
            changeChain,
            indexZero,
            tuple.item2,
          );
          addressesToStore.add(address);
        } else {
          highestChangeIndexWithHistory =
              max(tuple.item3, highestChangeIndexWithHistory);
          addressesToStore.addAll(tuple.item1);
        }
      }

      // remove extra addresses to help minimize risk of creating a large gap
      addressesToStore.removeWhere((e) =>
          e.subType == isar_models.AddressSubType.change &&
          e.derivationIndex > highestChangeIndexWithHistory);
      addressesToStore.removeWhere((e) =>
          e.subType == isar_models.AddressSubType.receiving &&
          e.derivationIndex > highestReceivingIndexWithHistory);

      if (isRescan) {
        await db.updateOrPutAddresses(addressesToStore);
      } else {
        await db.putAddresses(addressesToStore);
      }

      // get own payment code
      // isSegwit does not matter here at all
      final myCode = await getPaymentCode(isSegwit: false);

      // refresh transactions to pick up any received notification transactions
      await _refreshNotificationAddressTransactions();

      try {
        final Set<String> codesToCheck = {};
        final nym = await PaynymIsApi().nym(myCode.toString());
        if (nym.value != null) {
          for (final follower in nym.value!.followers) {
            codesToCheck.add(follower.code);
          }
          for (final following in nym.value!.following) {
            codesToCheck.add(following.code);
          }
        }

        // restore paynym transactions
        await restoreAllHistory(
          maxUnusedAddressGap: maxUnusedAddressGap,
          maxNumberOfIndexesToCheck: maxNumberOfIndexesToCheck,
          paymentCodeStrings: codesToCheck,
        );
      } catch (e, s) {
        Logging.instance.log(
          "Failed to check paynym.is followers/following for history during "
          "bitcoin wallet ($walletId $walletName) "
          "_recoverWalletFromBIP32SeedPhrase: $e/n$s",
          level: LogLevel.Error,
        );
      }

      await Future.wait([
        _refreshTransactions(),
        _updateUTXOs(),
      ]);

      await Future.wait([
        updateCachedId(walletId),
        updateCachedIsFavorite(false),
      ]);

      longMutex = false;
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from _recoverWalletFromBIP32SeedPhrase(): $e\n$s",
          level: LogLevel.Error);

      longMutex = false;
      rethrow;
    }
  }

  Future<bool> refreshIfThereIsNewData() async {
    if (longMutex) return false;
    if (_hasCalledExit) return false;
    Logging.instance.log("refreshIfThereIsNewData", level: LogLevel.Info);

    try {
      bool needsRefresh = false;
      Set<String> txnsToCheck = {};

      for (final String txid in txTracker.pendings) {
        if (!txTracker.wasNotifiedConfirmed(txid)) {
          txnsToCheck.add(txid);
        }
      }

      for (String txid in txnsToCheck) {
        final txn = await electrumXClient.getTransaction(txHash: txid);
        int confirmations = txn["confirmations"] as int? ?? 0;
        bool isUnconfirmed = confirmations < MINIMUM_CONFIRMATIONS;
        if (!isUnconfirmed) {
          // unconfirmedTxs = {};
          needsRefresh = true;
          break;
        }
      }
      if (!needsRefresh) {
        final allOwnAddresses = await _fetchAllOwnAddresses();
        List<Map<String, dynamic>> allTxs = await _fetchHistory(
            allOwnAddresses.map((e) => e.value).toList(growable: false));
        for (Map<String, dynamic> transaction in allTxs) {
          final txid = transaction['tx_hash'] as String;
          if ((await db
                  .getTransactions(walletId)
                  .filter()
                  .txidMatches(txid)
                  .findFirst()) ==
              null) {
            Logging.instance.log(
                " txid not found in address history already ${transaction['tx_hash']}",
                level: LogLevel.Info);
            needsRefresh = true;
            break;
          }
        }
      }
      return needsRefresh;
    } on NoSuchTransactionException catch (e) {
      // TODO: move direct transactions elsewhere
      await db.isar.writeTxn(() async {
        await db.isar.transactions.deleteByTxidWalletId(e.txid, walletId);
      });
      await txTracker.deleteTransaction(e.txid);
      return true;
    } catch (e, s) {
      Logging.instance.log(
          "Exception caught in refreshIfThereIsNewData: $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Future<void> getAllTxsToWatch() async {
    if (_hasCalledExit) return;
    List<isar_models.Transaction> unconfirmedTxnsToNotifyPending = [];
    List<isar_models.Transaction> unconfirmedTxnsToNotifyConfirmed = [];

    final currentChainHeight = await chainHeight;

    final txCount = await db.getTransactions(walletId).count();

    const paginateLimit = 50;

    for (int i = 0; i < txCount; i += paginateLimit) {
      final transactions = await db
          .getTransactions(walletId)
          .offset(i)
          .limit(paginateLimit)
          .findAll();
      for (final tx in transactions) {
        if (tx.isConfirmed(currentChainHeight, MINIMUM_CONFIRMATIONS)) {
          // get all transactions that were notified as pending but not as confirmed
          if (txTracker.wasNotifiedPending(tx.txid) &&
              !txTracker.wasNotifiedConfirmed(tx.txid)) {
            unconfirmedTxnsToNotifyConfirmed.add(tx);
          }
        } else {
          // get all transactions that were not notified as pending yet
          if (!txTracker.wasNotifiedPending(tx.txid)) {
            unconfirmedTxnsToNotifyPending.add(tx);
          }
        }
      }
    }

    // notify on unconfirmed transactions
    for (final tx in unconfirmedTxnsToNotifyPending) {
      final confirmations = tx.getConfirmations(currentChainHeight);

      if (tx.type == isar_models.TransactionType.incoming) {
        CryptoNotificationsEventBus.instance.fire(
          CryptoNotificationEvent(
            title: "Incoming transaction",
            walletId: walletId,
            walletName: walletName,
            date: DateTime.fromMillisecondsSinceEpoch(tx.timestamp * 1000),
            shouldWatchForUpdates: confirmations < MINIMUM_CONFIRMATIONS,
            coin: coin,
            txid: tx.txid,
            confirmations: confirmations,
            requiredConfirmations: MINIMUM_CONFIRMATIONS,
          ),
        );
        await txTracker.addNotifiedPending(tx.txid);
      } else if (tx.type == isar_models.TransactionType.outgoing) {
        CryptoNotificationsEventBus.instance.fire(
          CryptoNotificationEvent(
            title: "Sending transaction",
            walletId: walletId,
            date: DateTime.fromMillisecondsSinceEpoch(tx.timestamp * 1000),
            shouldWatchForUpdates: confirmations < MINIMUM_CONFIRMATIONS,
            txid: tx.txid,
            confirmations: confirmations,
            requiredConfirmations: MINIMUM_CONFIRMATIONS,
            walletName: walletName,
            coin: coin,
          ),
        );

        await txTracker.addNotifiedPending(tx.txid);
      }
    }

    // notify on confirmed
    for (final tx in unconfirmedTxnsToNotifyConfirmed) {
      if (tx.type == isar_models.TransactionType.incoming) {
        CryptoNotificationsEventBus.instance.fire(
          CryptoNotificationEvent(
            title: "Incoming transaction confirmed",
            walletId: walletId,
            date: DateTime.fromMillisecondsSinceEpoch(tx.timestamp * 1000),
            shouldWatchForUpdates: false,
            txid: tx.txid,
            requiredConfirmations: MINIMUM_CONFIRMATIONS,
            walletName: walletName,
            coin: coin,
          ),
        );

        await txTracker.addNotifiedConfirmed(tx.txid);
      } else if (tx.type == isar_models.TransactionType.outgoing) {
        CryptoNotificationsEventBus.instance.fire(
          CryptoNotificationEvent(
            title: "Outgoing transaction confirmed",
            walletId: walletId,
            date: DateTime.fromMillisecondsSinceEpoch(tx.timestamp * 1000),
            shouldWatchForUpdates: false,
            txid: tx.txid,
            requiredConfirmations: MINIMUM_CONFIRMATIONS,
            walletName: walletName,
            coin: coin,
          ),
        );

        await txTracker.addNotifiedConfirmed(tx.txid);
      }
    }
  }

  bool _shouldAutoSync = false;

  @override
  bool get shouldAutoSync => _shouldAutoSync;

  @override
  set shouldAutoSync(bool shouldAutoSync) {
    if (_shouldAutoSync != shouldAutoSync) {
      _shouldAutoSync = shouldAutoSync;
      if (!shouldAutoSync) {
        timer?.cancel();
        timer = null;
        stopNetworkAlivePinging();
      } else {
        startNetworkAlivePinging();
        refresh();
      }
    }
  }

  @override
  bool get isRefreshing => refreshMutex;

  bool refreshMutex = false;

  //TODO Show percentages properly/more consistently
  /// Refreshes display data for the wallet
  @override
  Future<void> refresh() async {
    if (refreshMutex) {
      Logging.instance.log("$walletId $walletName refreshMutex denied",
          level: LogLevel.Info);
      return;
    } else {
      refreshMutex = true;
    }

    try {
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.syncing,
          walletId,
          coin,
        ),
      );

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.0, walletId));

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.1, walletId));
      // isSegwit does not matter here at all
      final myCode = await getPaymentCode(isSegwit: false);
      final Set<String> codesToCheck = {};
      final nym = await PaynymIsApi().nym(myCode.toString());
      if (nym.value != null) {
        for (final follower in nym.value!.followers) {
          codesToCheck.add(follower.code);
        }
        for (final following in nym.value!.following) {
          codesToCheck.add(following.code);
        }
      }

      final currentHeight = await chainHeight;
      const storedHeight = 1; //await storedChainHeight;

      Logging.instance
          .log("chain height: $currentHeight", level: LogLevel.Info);
      // Logging.instance
      //     .log("cached height: $storedHeight", level: LogLevel.Info);

      if (currentHeight != storedHeight) {
        GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.2, walletId));
        await _checkChangeAddressForTransactions();
        await _checkP2PKHChangeAddressForTransactions();

        GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.3, walletId));
        await _checkCurrentReceivingAddressesForTransactions();

        GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.4, walletId));
        await checkAllCurrentReceivingPaynymAddressesForTransactions();

        final fetchFuture = _refreshTransactions();
        GlobalEventBus.instance
            .fire(RefreshPercentChangedEvent(0.50, walletId));

        final feeObj = _getFees();
        GlobalEventBus.instance
            .fire(RefreshPercentChangedEvent(0.60, walletId));

        GlobalEventBus.instance
            .fire(RefreshPercentChangedEvent(0.70, walletId));
        _feeObject = Future(() => feeObj);

        await fetchFuture;
        GlobalEventBus.instance
            .fire(RefreshPercentChangedEvent(0.80, walletId));

        await checkForNotificationTransactionsTo(codesToCheck);
        await _updateUTXOs();
        await getAllTxsToWatch();
        GlobalEventBus.instance
            .fire(RefreshPercentChangedEvent(0.90, walletId));
      }

      refreshMutex = false;
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(1.0, walletId));
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.synced,
          walletId,
          coin,
        ),
      );

      if (shouldAutoSync) {
        timer ??= Timer.periodic(const Duration(seconds: 30), (timer) async {
          Logging.instance.log(
              "Periodic refresh check for $walletId $walletName in object instance: $hashCode",
              level: LogLevel.Info);
          // chain height check currently broken
          // if ((await chainHeight) != (await storedChainHeight)) {
          if (await refreshIfThereIsNewData()) {
            await refresh();
            GlobalEventBus.instance.fire(UpdatedInBackgroundEvent(
                "New data found in $walletId $walletName in background!",
                walletId));
          }
          // }
        });
      }
    } catch (error, strace) {
      refreshMutex = false;
      GlobalEventBus.instance.fire(
        NodeConnectionStatusChangedEvent(
          NodeConnectionStatus.disconnected,
          walletId,
          coin,
        ),
      );
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.unableToSync,
          walletId,
          coin,
        ),
      );
      Logging.instance.log(
          "Caught exception in refreshWalletData(): $error\n$strace",
          level: LogLevel.Error);
    }
  }

  @override
  Future<Map<String, dynamic>> prepareSend({
    required String address,
    required Amount amount,
    Map<String, dynamic>? args,
  }) async {
    try {
      final feeRateType = args?["feeRate"];
      final customSatsPerVByte = args?["satsPerVByte"] as int?;
      final feeRateAmount = args?["feeRateAmount"];
      final utxos = args?["UTXOs"] as Set<isar_models.UTXO>?;

      if (customSatsPerVByte != null) {
        // check for send all
        bool isSendAll = false;
        if (amount == balance.spendable) {
          isSendAll = true;
        }

        final bool coinControl = utxos != null;

        final result = await coinSelection(
          satoshiAmountToSend: amount.raw.toInt(),
          selectedTxFeeRate: -1,
          satsPerVByte: customSatsPerVByte,
          recipientAddress: address,
          isSendAll: isSendAll,
          utxos: utxos?.toList(),
          coinControl: coinControl,
        );

        Logging.instance
            .log("PREPARE SEND RESULT: $result", level: LogLevel.Info);
        if (result is int) {
          switch (result) {
            case 1:
              throw Exception("Insufficient balance!");
            case 2:
              throw Exception("Insufficient funds to pay for transaction fee!");
            default:
              throw Exception("Transaction failed with error code $result");
          }
        } else {
          final hex = result["hex"];
          if (hex is String) {
            final fee = result["fee"] as int;
            final vSize = result["vSize"] as int;

            Logging.instance.log("txHex: $hex", level: LogLevel.Info);
            Logging.instance.log("fee: $fee", level: LogLevel.Info);
            Logging.instance.log("vsize: $vSize", level: LogLevel.Info);
            // fee should never be less than vSize sanity check
            if (fee < vSize) {
              throw Exception(
                  "Error in fee calculation: Transaction fee cannot be less than vSize");
            }
            return result as Map<String, dynamic>;
          } else {
            throw Exception("sent hex is not a String!!!");
          }
        }
      } else if (feeRateType is FeeRateType || feeRateAmount is int) {
        late final int rate;
        if (feeRateType is FeeRateType) {
          int fee = 0;
          final feeObject = await fees;
          switch (feeRateType) {
            case FeeRateType.fast:
              fee = feeObject.fast;
              break;
            case FeeRateType.average:
              fee = feeObject.medium;
              break;
            case FeeRateType.slow:
              fee = feeObject.slow;
              break;
            default:
              throw ArgumentError("Invalid use of custom fee");
          }
          rate = fee;
        } else {
          rate = feeRateAmount as int;
        }

        // check for send all
        bool isSendAll = false;
        if (amount == balance.spendable) {
          isSendAll = true;
        }

        final bool coinControl = utxos != null;

        final txData = await coinSelection(
          satoshiAmountToSend: amount.raw.toInt(),
          selectedTxFeeRate: rate,
          recipientAddress: address,
          isSendAll: isSendAll,
          utxos: utxos?.toList(),
          coinControl: coinControl,
        );

        Logging.instance.log("prepare send: $txData", level: LogLevel.Info);
        try {
          if (txData is int) {
            switch (txData) {
              case 1:
                throw Exception("Insufficient balance!");
              case 2:
                throw Exception(
                    "Insufficient funds to pay for transaction fee!");
              default:
                throw Exception("Transaction failed with error code $txData");
            }
          } else {
            final hex = txData["hex"];

            if (hex is String) {
              final fee = txData["fee"] as int;
              final vSize = txData["vSize"] as int;

              Logging.instance
                  .log("prepared txHex: $hex", level: LogLevel.Info);
              Logging.instance.log("prepared fee: $fee", level: LogLevel.Info);
              Logging.instance
                  .log("prepared vSize: $vSize", level: LogLevel.Info);

              // fee should never be less than vSize sanity check
              if (fee < vSize) {
                throw Exception(
                    "Error in fee calculation: Transaction fee cannot be less than vSize");
              }

              return txData as Map<String, dynamic>;
            } else {
              throw Exception("prepared hex is not a String!!!");
            }
          }
        } catch (e, s) {
          Logging.instance.log("Exception rethrown from prepareSend(): $e\n$s",
              level: LogLevel.Error);
          rethrow;
        }
      } else {
        throw ArgumentError("Invalid fee rate argument provided!");
      }
    } catch (e, s) {
      Logging.instance.log("Exception rethrown from prepareSend(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  @override
  Future<String> confirmSend({required Map<String, dynamic> txData}) async {
    try {
      Logging.instance.log("confirmSend txData: $txData", level: LogLevel.Info);

      final hex = txData["hex"] as String;

      final txHash = await _electrumXClient.broadcastTransaction(rawTx: hex);
      Logging.instance.log("Sent txHash: $txHash", level: LogLevel.Info);

      final utxos = txData["usedUTXOs"] as List<isar_models.UTXO>;

      // mark utxos as used
      await db.putUTXOs(utxos.map((e) => e.copyWith(used: true)).toList());

      return txHash;
    } catch (e, s) {
      Logging.instance.log("Exception rethrown from confirmSend(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  @override
  Future<bool> testNetworkConnection() async {
    try {
      final result = await _electrumXClient.ping();
      return result;
    } catch (_) {
      return false;
    }
  }

  Timer? _networkAliveTimer;

  void startNetworkAlivePinging() {
    // call once on start right away
    _periodicPingCheck();

    // then periodically check
    _networkAliveTimer = Timer.periodic(
      Constants.networkAliveTimerDuration,
      (_) async {
        _periodicPingCheck();
      },
    );
  }

  void _periodicPingCheck() async {
    bool hasNetwork = await testNetworkConnection();

    if (_isConnected != hasNetwork) {
      NodeConnectionStatus status = hasNetwork
          ? NodeConnectionStatus.connected
          : NodeConnectionStatus.disconnected;
      GlobalEventBus.instance
          .fire(NodeConnectionStatusChangedEvent(status, walletId, coin));

      _isConnected = hasNetwork;
      if (hasNetwork) {
        unawaited(refresh());
      }
    }
  }

  void stopNetworkAlivePinging() {
    _networkAliveTimer?.cancel();
    _networkAliveTimer = null;
  }

  bool _isConnected = false;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<void> initializeNew() async {
    Logging.instance
        .log("Generating new ${coin.prettyName} wallet.", level: LogLevel.Info);

    if (getCachedId() != null) {
      throw Exception(
          "Attempted to initialize a new wallet using an existing wallet ID!");
    }

    await _prefs.init();
    try {
      await _generateNewWallet();
    } catch (e, s) {
      Logging.instance.log("Exception rethrown from initializeNew(): $e\n$s",
          level: LogLevel.Fatal);
      rethrow;
    }
    await Future.wait([
      updateCachedId(walletId),
      updateCachedIsFavorite(false),
    ]);
  }

  @override
  Future<void> initializeExisting() async {
    Logging.instance.log("initializeExisting() ${coin.prettyName} wallet.",
        level: LogLevel.Info);

    if (getCachedId() == null) {
      throw Exception(
          "Attempted to initialize an existing wallet using an unknown wallet ID!");
    }

    await _prefs.init();

    // this will add the notification address to the db if it isn't
    // already there for older wallets
    await getMyNotificationAddress();

    // await _checkCurrentChangeAddressesForTransactions();
    // await _checkCurrentReceivingAddressesForTransactions();
  }

  // hack to add tx to txData before refresh completes
  // required based on current app architecture where we don't properly store
  // transactions locally in a good way
  @override
  Future<void> updateSentCachedTxData(Map<String, dynamic> txData) async {
    final transaction = isar_models.Transaction(
      walletId: walletId,
      txid: txData["txid"] as String,
      timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      type: isar_models.TransactionType.outgoing,
      subType: isar_models.TransactionSubType.none,
      // precision may be lost here hence the following amountString
      amount: (txData["recipientAmt"] as Amount).raw.toInt(),
      amountString: (txData["recipientAmt"] as Amount).toJsonString(),
      fee: txData["fee"] as int,
      height: null,
      isCancelled: false,
      isLelantus: false,
      otherData: null,
      slateId: null,
      nonce: null,
      inputs: [],
      outputs: [],
      numberOfMessages: null,
    );

    final address = txData["address"] is String
        ? await db.getAddress(walletId, txData["address"] as String)
        : null;

    await db.addNewTransactionData(
      [
        Tuple2(transaction, address),
      ],
      walletId,
    );
  }

  @override
  bool validateAddress(String address) {
    return Address.validateAddress(address, _network);
  }

  @override
  String get walletId => _walletId;
  late final String _walletId;

  @override
  String get walletName => _walletName;
  late String _walletName;

  // setter for updating on rename
  @override
  set walletName(String newName) => _walletName = newName;

  late ElectrumX _electrumXClient;

  ElectrumX get electrumXClient => _electrumXClient;

  late CachedElectrumX _cachedElectrumXClient;

  CachedElectrumX get cachedElectrumXClient => _cachedElectrumXClient;

  late SecureStorageInterface _secureStore;

  @override
  Future<void> updateNode(bool shouldRefresh) async {
    final failovers = NodeService(secureStorageInterface: _secureStore)
        .failoverNodesFor(coin: coin)
        .map((e) => ElectrumXNode(
              address: e.host,
              port: e.port,
              name: e.name,
              id: e.id,
              useSSL: e.useSSL,
            ))
        .toList();
    final newNode = await getCurrentNode();
    _electrumXClient = ElectrumX.from(
      node: newNode,
      prefs: _prefs,
      failovers: failovers,
    );
    _cachedElectrumXClient = CachedElectrumX.from(
      electrumXClient: _electrumXClient,
    );

    if (shouldRefresh) {
      unawaited(refresh());
    }
  }

  Future<List<String>> _getMnemonicList() async {
    final _mnemonicString = await mnemonicString;
    if (_mnemonicString == null) {
      return [];
    }
    final List<String> data = _mnemonicString.split(' ');
    return data;
  }

  Future<ElectrumXNode> getCurrentNode() async {
    final node = NodeService(secureStorageInterface: _secureStore)
            .getPrimaryNodeFor(coin: coin) ??
        DefaultNodes.getNodeFor(coin);

    return ElectrumXNode(
      address: node.host,
      port: node.port,
      name: node.name,
      useSSL: node.useSSL,
      id: node.id,
    );
  }

  Future<List<isar_models.Address>> _fetchAllOwnAddresses() async {
    final allAddresses = await db
        .getAddresses(walletId)
        .filter()
        .not()
        .group(
          (q) => q
              .typeEqualTo(isar_models.AddressType.nonWallet)
              .or()
              .subTypeEqualTo(isar_models.AddressSubType.nonWallet),
        )
        .findAll();
    return allAddresses;
  }

  Future<FeeObject> _getFees() async {
    try {
      //TODO adjust numbers for different speeds?
      const int f = 1, m = 5, s = 20;

      final fast = await electrumXClient.estimateFee(blocks: f);
      final medium = await electrumXClient.estimateFee(blocks: m);
      final slow = await electrumXClient.estimateFee(blocks: s);

      final feeObject = FeeObject(
        numberOfBlocksFast: f,
        numberOfBlocksAverage: m,
        numberOfBlocksSlow: s,
        fast: Amount.fromDecimal(
          fast,
          fractionDigits: coin.decimals,
        ).raw.toInt(),
        medium: Amount.fromDecimal(
          medium,
          fractionDigits: coin.decimals,
        ).raw.toInt(),
        slow: Amount.fromDecimal(
          slow,
          fractionDigits: coin.decimals,
        ).raw.toInt(),
      );

      Logging.instance.log("fetched fees: $feeObject", level: LogLevel.Info);
      return feeObject;
    } catch (e) {
      Logging.instance
          .log("Exception rethrown from _getFees(): $e", level: LogLevel.Error);
      rethrow;
    }
  }

  Future<void> _generateNewWallet() async {
    Logging.instance
        .log("IS_INTEGRATION_TEST: $integrationTestFlag", level: LogLevel.Info);
    if (!integrationTestFlag) {
      try {
        final features = await electrumXClient
            .getServerFeatures()
            .timeout(const Duration(seconds: 3));
        Logging.instance.log("features: $features", level: LogLevel.Info);
        switch (coin) {
          case Coin.bitcoin:
            if (features['genesis_hash'] != GENESIS_HASH_MAINNET) {
              throw Exception("genesis hash does not match main net!");
            }
            break;
          case Coin.bitcoinTestNet:
            if (features['genesis_hash'] != GENESIS_HASH_TESTNET) {
              throw Exception("genesis hash does not match test net!");
            }
            break;
          default:
            throw Exception(
                "Attempted to generate a BitcoinWallet using a non bitcoin coin type: ${coin.name}");
        }
      } catch (e, s) {
        Logging.instance.log("$e/n$s", level: LogLevel.Info);
      }
    }

    // this should never fail
    if ((await mnemonicString) != null || (await mnemonicPassphrase) != null) {
      throw Exception(
          "Attempted to overwrite mnemonic on generate new wallet!");
    }
    await _secureStore.write(
        key: '${_walletId}_mnemonic',
        value: bip39.generateMnemonic(strength: 128));
    await _secureStore.write(key: '${_walletId}_mnemonicPassphrase', value: "");

    // Generate and add addresses to relevant arrays
    final initialAddresses = await Future.wait([
      // P2WPKH
      _generateAddressForChain(0, 0, DerivePathType.bip84),
      _generateAddressForChain(1, 0, DerivePathType.bip84),

      // P2PKH
      _generateAddressForChain(0, 0, DerivePathType.bip44),
      _generateAddressForChain(1, 0, DerivePathType.bip44),

      // P2SH
      _generateAddressForChain(0, 0, DerivePathType.bip49),
      _generateAddressForChain(1, 0, DerivePathType.bip49),
    ]);

    // this will add the notification address to the db if it isn't
    // already there so it can be watched
    await getMyNotificationAddress();

    await db.putAddresses(initialAddresses);

    Logging.instance.log("_generateNewWalletFinished", level: LogLevel.Info);
  }

  /// Generates a new internal or external chain address for the wallet using a BIP84, BIP44, or BIP49 derivation path.
  /// [chain] - Use 0 for receiving (external), 1 for change (internal). Should not be any other value!
  /// [index] - This can be any integer >= 0
  Future<isar_models.Address> _generateAddressForChain(
    int chain,
    int index,
    DerivePathType derivePathType,
  ) async {
    final _mnemonic = await mnemonicString;
    final _mnemonicPassphrase = await mnemonicPassphrase;
    if (_mnemonicPassphrase == null) {
      Logging.instance.log(
          "Exception in _generateAddressForChain: mnemonic passphrase null, possible migration issue; if using internal builds, delete wallet and restore from seed, if using a release build, please file bug report",
          level: LogLevel.Error);
    }

    final derivePath = constructDerivePath(
      derivePathType: derivePathType,
      networkWIF: _network.wif,
      chain: chain,
      index: index,
    );
    final node = await Bip32Utils.getBip32Node(
      _mnemonic!,
      _mnemonicPassphrase!,
      _network,
      derivePath,
    );

    final data = PaymentData(pubkey: node.publicKey);
    String address;
    isar_models.AddressType addrType;

    switch (derivePathType) {
      case DerivePathType.bip44:
        address = P2PKH(data: data, network: _network).data.address!;
        addrType = isar_models.AddressType.p2pkh;
        break;
      case DerivePathType.bip49:
        address = P2SH(
                data: PaymentData(
                    redeem: P2WPKH(data: data, network: _network).data),
                network: _network)
            .data
            .address!;
        addrType = isar_models.AddressType.p2sh;
        break;
      case DerivePathType.bip84:
        address = P2WPKH(network: _network, data: data).data.address!;
        addrType = isar_models.AddressType.p2wpkh;
        break;
      default:
        throw Exception("DerivePathType $derivePathType not supported");
    }

    return isar_models.Address(
      walletId: walletId,
      value: address,
      publicKey: node.publicKey,
      type: addrType,
      derivationIndex: index,
      derivationPath: isar_models.DerivationPath()..value = derivePath,
      subType: chain == 0
          ? isar_models.AddressSubType.receiving
          : isar_models.AddressSubType.change,
    );
  }

  String _buildDerivationStorageKey({
    required int chain,
    required DerivePathType derivePathType,
  }) {
    String key;
    String chainId = chain == 0 ? "receive" : "change";
    switch (derivePathType) {
      case DerivePathType.bip44:
        key = "${walletId}_${chainId}DerivationsP2PKH";
        break;
      case DerivePathType.bip49:
        key = "${walletId}_${chainId}DerivationsP2SH";
        break;
      case DerivePathType.bip84:
        key = "${walletId}_${chainId}DerivationsP2WPKH";
        break;
      default:
        throw Exception("DerivePathType unsupported");
    }
    return key;
  }

  Future<Map<String, dynamic>> _fetchDerivations({
    required int chain,
    required DerivePathType derivePathType,
  }) async {
    // build lookup key
    final key = _buildDerivationStorageKey(
        chain: chain, derivePathType: derivePathType);

    // fetch current derivations
    final derivationsString = await _secureStore.read(key: key);
    return Map<String, dynamic>.from(
        jsonDecode(derivationsString ?? "{}") as Map);
  }

  Future<List<Map<String, dynamic>>> fastFetch(List<String> allTxHashes) async {
    List<Map<String, dynamic>> allTransactions = [];

    const futureLimit = 30;
    List<Future<Map<String, dynamic>>> transactionFutures = [];
    int currentFutureCount = 0;
    for (final txHash in allTxHashes) {
      Future<Map<String, dynamic>> transactionFuture =
          cachedElectrumXClient.getTransaction(
        txHash: txHash,
        verbose: true,
        coin: coin,
      );
      transactionFutures.add(transactionFuture);
      currentFutureCount++;
      if (currentFutureCount > futureLimit) {
        currentFutureCount = 0;
        await Future.wait(transactionFutures);
        for (final fTx in transactionFutures) {
          final tx = await fTx;

          allTransactions.add(tx);
        }
      }
    }
    if (currentFutureCount != 0) {
      currentFutureCount = 0;
      await Future.wait(transactionFutures);
      for (final fTx in transactionFutures) {
        final tx = await fTx;

        allTransactions.add(tx);
      }
    }
    return allTransactions;
  }

  Future<void> _updateUTXOs() async {
    final allAddresses = await _fetchAllOwnAddresses();

    try {
      final fetchedUtxoList = <List<Map<String, dynamic>>>[];

      final Map<int, Map<String, List<dynamic>>> batches = {};
      const batchSizeMax = 100;
      int batchNumber = 0;
      for (int i = 0; i < allAddresses.length; i++) {
        if (batches[batchNumber] == null) {
          batches[batchNumber] = {};
        }
        final scripthash =
            AddressUtils.convertToScriptHash(allAddresses[i].value, _network);
        batches[batchNumber]!.addAll({
          scripthash: [scripthash]
        });
        if (i % batchSizeMax == batchSizeMax - 1) {
          batchNumber++;
        }
      }

      for (int i = 0; i < batches.length; i++) {
        final response =
            await _electrumXClient.getBatchUTXOs(args: batches[i]!);
        for (final entry in response.entries) {
          if (entry.value.isNotEmpty) {
            fetchedUtxoList.add(entry.value);
          }
        }
      }

      final List<isar_models.UTXO> outputArray = [];

      for (int i = 0; i < fetchedUtxoList.length; i++) {
        for (int j = 0; j < fetchedUtxoList[i].length; j++) {
          final jsonUTXO = fetchedUtxoList[i][j];

          final txn = await cachedElectrumXClient.getTransaction(
            txHash: jsonUTXO["tx_hash"] as String,
            verbose: true,
            coin: coin,
          );

          // fetch stored tx to see if paynym notification tx and block utxo
          final storedTx = await db.getTransaction(
            walletId,
            jsonUTXO["tx_hash"] as String,
          );

          bool shouldBlock = false;
          String? blockReason;
          String? label;

          if (storedTx?.subType ==
              isar_models.TransactionSubType.bip47Notification) {
            if (storedTx?.type == isar_models.TransactionType.incoming) {
              shouldBlock = true;
              blockReason = "Incoming paynym notification transaction.";
            } else if (storedTx?.type == isar_models.TransactionType.outgoing) {
              shouldBlock = false;
              blockReason = "Paynym notification change output. Incautious "
                  "handling of change outputs from notification transactions "
                  "may cause unintended loss of privacy.";
              label = blockReason;
            }
          }

          final vout = jsonUTXO["tx_pos"] as int;

          final outputs = txn["vout"] as List;

          String? utxoOwnerAddress;
          // get UTXO owner address
          for (final output in outputs) {
            if (output["n"] == vout) {
              utxoOwnerAddress =
                  output["scriptPubKey"]?["addresses"]?[0] as String? ??
                      output["scriptPubKey"]?["address"] as String?;
            }
          }

          final utxo = isar_models.UTXO(
            walletId: walletId,
            txid: txn["txid"] as String,
            vout: vout,
            value: jsonUTXO["value"] as int,
            name: label ?? "",
            isBlocked: shouldBlock,
            blockedReason: blockReason,
            isCoinbase: txn["is_coinbase"] as bool? ?? false,
            blockHash: txn["blockhash"] as String?,
            blockHeight: jsonUTXO["height"] as int?,
            blockTime: txn["blocktime"] as int?,
            address: utxoOwnerAddress,
          );

          outputArray.add(utxo);
        }
      }

      Logging.instance
          .log('Outputs fetched: $outputArray', level: LogLevel.Info);

      await db.updateUTXOs(walletId, outputArray);

      // finally update balance
      await _updateBalance();
    } catch (e, s) {
      Logging.instance
          .log("Output fetch unsuccessful: $e\n$s", level: LogLevel.Error);
    }
  }

  Future<void> _updateBalance() async {
    await refreshBalance();
  }

  @override
  Balance get balance => _balance ??= getCachedBalance();
  Balance? _balance;

  Future<int> getTxCount({required String address}) async {
    String? scripthash;
    try {
      scripthash = AddressUtils.convertToScriptHash(address, _network);
      final transactions =
          await electrumXClient.getHistory(scripthash: scripthash);
      return transactions.length;
    } catch (e) {
      Logging.instance.log(
          "Exception rethrown in _getTxCount(address: $address, scripthash: $scripthash): $e",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Future<Map<String, int>> _getBatchTxCount({
    required Map<String, String> addresses,
  }) async {
    try {
      final Map<String, List<dynamic>> args = {};
      for (final entry in addresses.entries) {
        args[entry.key] = [
          AddressUtils.convertToScriptHash(entry.value, _network)
        ];
      }
      final response = await electrumXClient.getBatchHistory(args: args);

      final Map<String, int> result = {};
      for (final entry in response.entries) {
        result[entry.key] = entry.value.length;
      }
      return result;
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown in _getBatchTxCount(address: $addresses: $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Future<void> _checkReceivingAddressForTransactions() async {
    try {
      final currentReceiving = await _currentReceivingAddress;

      final int txCount = await getTxCount(address: currentReceiving.value);
      Logging.instance.log(
          'Number of txs for current receiving address $currentReceiving: $txCount',
          level: LogLevel.Info);

      if (txCount >= 1 || currentReceiving.derivationIndex < 0) {
        // First increment the receiving index
        final newReceivingIndex = currentReceiving.derivationIndex + 1;

        // Use new index to derive a new receiving address
        final newReceivingAddress = await _generateAddressForChain(
            0, newReceivingIndex, DerivePathTypeExt.primaryFor(coin));

        final existing = await db
            .getAddresses(walletId)
            .filter()
            .valueEqualTo(newReceivingAddress.value)
            .findFirst();
        if (existing == null) {
          // Add that new change address
          await db.putAddress(newReceivingAddress);
        } else {
          // we need to update the address
          await db.updateAddress(existing, newReceivingAddress);
        }
        // keep checking until address with no tx history is set as current
        await _checkReceivingAddressForTransactions();
      }
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from _checkReceivingAddressForTransactions(${DerivePathTypeExt.primaryFor(coin)}): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Future<void> _checkChangeAddressForTransactions() async {
    try {
      final currentChange = await _currentChangeAddress;
      final int txCount = await getTxCount(address: currentChange.value);
      Logging.instance.log(
          'Number of txs for current change address $currentChange: $txCount',
          level: LogLevel.Info);

      if (txCount >= 1 || currentChange.derivationIndex < 0) {
        // First increment the change index
        final newChangeIndex = currentChange.derivationIndex + 1;

        // Use new index to derive a new change address
        final newChangeAddress = await _generateAddressForChain(
            1, newChangeIndex, DerivePathTypeExt.primaryFor(coin));

        final existing = await db
            .getAddresses(walletId)
            .filter()
            .valueEqualTo(newChangeAddress.value)
            .findFirst();
        if (existing == null) {
          // Add that new change address
          await db.putAddress(newChangeAddress);
        } else {
          // we need to update the address
          await db.updateAddress(existing, newChangeAddress);
        }
        // keep checking until address with no tx history is set as current
        await _checkChangeAddressForTransactions();
      }
    } on SocketException catch (se, s) {
      Logging.instance.log(
          "SocketException caught in _checkReceivingAddressForTransactions(${DerivePathTypeExt.primaryFor(coin)}): $se\n$s",
          level: LogLevel.Error);
      return;
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from _checkReceivingAddressForTransactions(${DerivePathTypeExt.primaryFor(coin)}): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Future<void> _checkP2PKHChangeAddressForTransactions() async {
    try {
      final currentChange = await _currentChangeAddressP2PKH;
      final int txCount = await getTxCount(address: currentChange.value);
      Logging.instance.log(
          'Number of txs for current change address $currentChange: $txCount',
          level: LogLevel.Info);

      if (txCount >= 1 || currentChange.derivationIndex < 0) {
        // First increment the change index
        final newChangeIndex = currentChange.derivationIndex + 1;

        // Use new index to derive a new change address
        final newChangeAddress = await _generateAddressForChain(
            1, newChangeIndex, DerivePathType.bip44);

        final existing = await db
            .getAddresses(walletId)
            .filter()
            .valueEqualTo(newChangeAddress.value)
            .findFirst();
        if (existing == null) {
          // Add that new change address
          await db.putAddress(newChangeAddress);
        } else {
          // we need to update the address
          await db.updateAddress(existing, newChangeAddress);
        }
        // keep checking until address with no tx history is set as current
        await _checkP2PKHChangeAddressForTransactions();
      }
    } on SocketException catch (se, s) {
      Logging.instance.log(
          "SocketException caught in _checkReceivingAddressForTransactions(${DerivePathType.bip44}): $se\n$s",
          level: LogLevel.Error);
      return;
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from _checkReceivingAddressForTransactions(${DerivePathType.bip44}): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Future<void> _checkCurrentReceivingAddressesForTransactions() async {
    try {
      // for (final type in DerivePathType.values) {
      await _checkReceivingAddressForTransactions();
      // }
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from _checkCurrentReceivingAddressesForTransactions(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  /// public wrapper because dart can't test private...
  Future<void> checkCurrentReceivingAddressesForTransactions() async {
    if (Platform.environment["FLUTTER_TEST"] == "true") {
      try {
        return _checkCurrentReceivingAddressesForTransactions();
      } catch (_) {
        rethrow;
      }
    }
  }

  Future<void> _checkCurrentChangeAddressesForTransactions() async {
    try {
      // for (final type in DerivePathType.values) {
      await _checkChangeAddressForTransactions();
      // }
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from _checkCurrentChangeAddressesForTransactions(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  /// public wrapper because dart can't test private...
  Future<void> checkCurrentChangeAddressesForTransactions() async {
    if (Platform.environment["FLUTTER_TEST"] == "true") {
      try {
        return _checkCurrentChangeAddressesForTransactions();
      } catch (_) {
        rethrow;
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchHistory(
      List<String> allAddresses) async {
    try {
      List<Map<String, dynamic>> allTxHashes = [];

      final Map<int, Map<String, List<dynamic>>> batches = {};
      final Map<String, String> requestIdToAddressMap = {};
      const batchSizeMax = 100;
      int batchNumber = 0;
      for (int i = 0; i < allAddresses.length; i++) {
        if (batches[batchNumber] == null) {
          batches[batchNumber] = {};
        }
        final scripthash =
            AddressUtils.convertToScriptHash(allAddresses[i], _network);
        final id = Logger.isTestEnv ? "$i" : const Uuid().v1();
        requestIdToAddressMap[id] = allAddresses[i];
        batches[batchNumber]!.addAll({
          id: [scripthash]
        });
        if (i % batchSizeMax == batchSizeMax - 1) {
          batchNumber++;
        }
      }

      for (int i = 0; i < batches.length; i++) {
        final response =
            await _electrumXClient.getBatchHistory(args: batches[i]!);
        for (final entry in response.entries) {
          for (int j = 0; j < entry.value.length; j++) {
            entry.value[j]["address"] = requestIdToAddressMap[entry.key];
            if (!allTxHashes.contains(entry.value[j])) {
              allTxHashes.add(entry.value[j]);
            }
          }
        }
      }

      return allTxHashes;
    } catch (e, s) {
      Logging.instance.log("_fetchHistory: $e\n$s", level: LogLevel.Error);
      rethrow;
    }
  }

  bool _duplicateTxCheck(
      List<Map<String, dynamic>> allTransactions, String txid) {
    for (int i = 0; i < allTransactions.length; i++) {
      if (allTransactions[i]["txid"] == txid) {
        return true;
      }
    }
    return false;
  }

  Future<void> _refreshNotificationAddressTransactions() async {
    final address = await getMyNotificationAddress();
    final hashes = await _fetchHistory([address.value]);

    List<Map<String, dynamic>> allTransactions = [];

    final currentHeight = await chainHeight;

    for (final txHash in hashes) {
      final storedTx = await db
          .getTransactions(walletId)
          .filter()
          .txidEqualTo(txHash["tx_hash"] as String)
          .findFirst();

      // TODO: remove bip47Notification type check sometime after Q2 2023
      if (storedTx == null ||
          storedTx.subType ==
              isar_models.TransactionSubType.bip47Notification ||
          !storedTx.isConfirmed(currentHeight, MINIMUM_CONFIRMATIONS)) {
        final tx = await cachedElectrumXClient.getTransaction(
          txHash: txHash["tx_hash"] as String,
          verbose: true,
          coin: coin,
        );

        tx["address"] = await db
            .getAddresses(walletId)
            .filter()
            .valueEqualTo(txHash["address"] as String)
            .findFirst();
        tx["height"] = txHash["height"];
        allTransactions.add(tx);
      }
    }

    final List<Tuple2<isar_models.Transaction, isar_models.Address?>> txnsData =
        [];

    for (final txObject in allTransactions) {
      final data = await parseTransaction(
        txObject,
        cachedElectrumXClient,
        [address],
        coin,
        MINIMUM_CONFIRMATIONS,
        walletId,
      );

      txnsData.add(data);
    }
    await db.addNewTransactionData(txnsData, walletId);
  }

  Future<void> _refreshTransactions() async {
    final List<isar_models.Address> allAddresses =
        await _fetchAllOwnAddresses();

    final Set<Map<String, dynamic>> allTxHashes =
        (await _fetchHistory(allAddresses.map((e) => e.value).toList()))
            .toSet();

    // // prefetch/cache
    // Set<String> hashes = {};
    // for (var element in allReceivingTxHashes) {
    //   hashes.add(element['tx_hash'] as String);
    // }
    // await fastFetch(hashes.toList());

    List<Map<String, dynamic>> allTransactions = [];

    final currentHeight = await chainHeight;

    for (final txHash in allTxHashes) {
      final storedTx = await db
          .getTransactions(walletId)
          .filter()
          .txidEqualTo(txHash["tx_hash"] as String)
          .findFirst();

      // TODO: remove bip47Notification type check sometime after Q2 2023
      if (storedTx == null ||
          storedTx.subType ==
              isar_models.TransactionSubType.bip47Notification ||
          !storedTx.isConfirmed(currentHeight, MINIMUM_CONFIRMATIONS)) {
        final tx = await cachedElectrumXClient.getTransaction(
          txHash: txHash["tx_hash"] as String,
          verbose: true,
          coin: coin,
        );

        if (!_duplicateTxCheck(allTransactions, tx["txid"] as String)) {
          tx["address"] = await db
              .getAddresses(walletId)
              .filter()
              .valueEqualTo(txHash["address"] as String)
              .findFirst();
          tx["height"] = txHash["height"];
          allTransactions.add(tx);
        }
      }
    }

    // // prefetch/cache
    // Set<String> vHashes = {};
    // for (final txObject in allTransactions) {
    //   for (int i = 0; i < (txObject["vin"] as List).length; i++) {
    //     final input = txObject["vin"]![i] as Map;
    //     final prevTxid = input["txid"] as String;
    //     vHashes.add(prevTxid);
    //   }
    // }
    // await fastFetch(vHashes.toList());

    final List<Tuple2<isar_models.Transaction, isar_models.Address?>> txnsData =
        [];

    for (final txObject in allTransactions) {
      final data = await parseTransaction(
        txObject,
        cachedElectrumXClient,
        allAddresses,
        coin,
        MINIMUM_CONFIRMATIONS,
        walletId,
      );

      txnsData.add(data);
    }
    await db.addNewTransactionData(txnsData, walletId);

    // quick hack to notify manager to call notifyListeners if
    // transactions changed
    if (txnsData.isNotEmpty) {
      GlobalEventBus.instance.fire(
        UpdatedInBackgroundEvent(
          "Transactions updated/added for: $walletId $walletName  ",
          walletId,
        ),
      );
    }
  }

  int estimateTxFee({required int vSize, required int feeRatePerKB}) {
    return vSize * (feeRatePerKB / 1000).ceil();
  }

  /// The coinselection algorithm decides whether or not the user is eligible to make the transaction
  /// with [satoshiAmountToSend] and [selectedTxFeeRate]. If so, it will call buildTrasaction() and return
  /// a map containing the tx hex along with other important information. If not, then it will return
  /// an integer (1 or 2)
  dynamic coinSelection({
    required int satoshiAmountToSend,
    required int selectedTxFeeRate,
    required String recipientAddress,
    required bool coinControl,
    required bool isSendAll,
    int? satsPerVByte,
    int additionalOutputs = 0,
    List<isar_models.UTXO>? utxos,
  }) async {
    Logging.instance
        .log("Starting coinSelection ----------", level: LogLevel.Info);
    final List<isar_models.UTXO> availableOutputs = utxos ?? await this.utxos;
    final currentChainHeight = await chainHeight;
    final List<isar_models.UTXO> spendableOutputs = [];
    int spendableSatoshiValue = 0;

    // Build list of spendable outputs and totaling their satoshi amount
    for (final utxo in availableOutputs) {
      if (utxo.isBlocked == false &&
          utxo.isConfirmed(currentChainHeight, MINIMUM_CONFIRMATIONS) &&
          utxo.used != true) {
        spendableOutputs.add(utxo);
        spendableSatoshiValue += utxo.value;
      }
    }

    if (coinControl) {
      if (spendableOutputs.length < availableOutputs.length) {
        throw ArgumentError("Attempted to use an unavailable utxo");
      }
    }

    // don't care about sorting if using all utxos
    if (!coinControl) {
      // sort spendable by age (oldest first)
      spendableOutputs.sort((a, b) => b.blockTime!.compareTo(a.blockTime!));
    }

    Logging.instance.log("spendableOutputs.length: ${spendableOutputs.length}",
        level: LogLevel.Info);
    Logging.instance.log("availableOutputs.length: ${availableOutputs.length}",
        level: LogLevel.Info);
    Logging.instance
        .log("spendableOutputs: $spendableOutputs", level: LogLevel.Info);
    Logging.instance.log("spendableSatoshiValue: $spendableSatoshiValue",
        level: LogLevel.Info);
    Logging.instance
        .log("satoshiAmountToSend: $satoshiAmountToSend", level: LogLevel.Info);
    // If the amount the user is trying to send is smaller than the amount that they have spendable,
    // then return 1, which indicates that they have an insufficient balance.
    if (spendableSatoshiValue < satoshiAmountToSend) {
      return 1;
      // If the amount the user wants to send is exactly equal to the amount they can spend, then return
      // 2, which indicates that they are not leaving enough over to pay the transaction fee
    } else if (spendableSatoshiValue == satoshiAmountToSend && !isSendAll) {
      return 2;
    }
    // If neither of these statements pass, we assume that the user has a spendable balance greater
    // than the amount they're attempting to send. Note that this value still does not account for
    // the added transaction fee, which may require an extra input and will need to be checked for
    // later on.

    // Possible situation right here
    int satoshisBeingUsed = 0;
    int inputsBeingConsumed = 0;
    List<isar_models.UTXO> utxoObjectsToUse = [];

    if (!coinControl) {
      for (var i = 0;
          satoshisBeingUsed < satoshiAmountToSend &&
              i < spendableOutputs.length;
          i++) {
        utxoObjectsToUse.add(spendableOutputs[i]);
        satoshisBeingUsed += spendableOutputs[i].value;
        inputsBeingConsumed += 1;
      }
      for (int i = 0;
          i < additionalOutputs &&
              inputsBeingConsumed < spendableOutputs.length;
          i++) {
        utxoObjectsToUse.add(spendableOutputs[inputsBeingConsumed]);
        satoshisBeingUsed += spendableOutputs[inputsBeingConsumed].value;
        inputsBeingConsumed += 1;
      }
    } else {
      satoshisBeingUsed = spendableSatoshiValue;
      utxoObjectsToUse = spendableOutputs;
      inputsBeingConsumed = spendableOutputs.length;
    }

    Logging.instance
        .log("satoshisBeingUsed: $satoshisBeingUsed", level: LogLevel.Info);
    Logging.instance
        .log("inputsBeingConsumed: $inputsBeingConsumed", level: LogLevel.Info);
    Logging.instance
        .log('utxoObjectsToUse: $utxoObjectsToUse', level: LogLevel.Info);

    // numberOfOutputs' length must always be equal to that of recipientsArray and recipientsAmtArray
    List<String> recipientsArray = [recipientAddress];
    List<int> recipientsAmtArray = [satoshiAmountToSend];

    // gather required signing data
    final utxoSigningData = await fetchBuildTxData(utxoObjectsToUse);

    if (isSendAll) {
      Logging.instance
          .log("Attempting to send all $coin", level: LogLevel.Info);

      final int vSizeForOneOutput = (await buildTransaction(
        utxoSigningData: utxoSigningData,
        recipients: [recipientAddress],
        satoshiAmounts: [satoshisBeingUsed - 1],
      ))["vSize"] as int;
      int feeForOneOutput = satsPerVByte != null
          ? (satsPerVByte * vSizeForOneOutput)
          : estimateTxFee(
              vSize: vSizeForOneOutput,
              feeRatePerKB: selectedTxFeeRate,
            );

      if (satsPerVByte == null) {
        final int roughEstimate = roughFeeEstimate(
          spendableOutputs.length,
          1,
          selectedTxFeeRate,
        ).raw.toInt();
        if (feeForOneOutput < roughEstimate) {
          feeForOneOutput = roughEstimate;
        }
      }

      final int amount = satoshiAmountToSend - feeForOneOutput;
      dynamic txn = await buildTransaction(
        utxoSigningData: utxoSigningData,
        recipients: recipientsArray,
        satoshiAmounts: [amount],
      );
      Map<String, dynamic> transactionObject = {
        "hex": txn["hex"],
        "recipient": recipientsArray[0],
        "recipientAmt": Amount(
          rawValue: BigInt.from(amount),
          fractionDigits: coin.decimals,
        ),
        "fee": feeForOneOutput,
        "vSize": txn["vSize"],
        "usedUTXOs": utxoSigningData.map((e) => e.utxo).toList(),
      };
      return transactionObject;
    }

    final int vSizeForOneOutput;
    try {
      vSizeForOneOutput = (await buildTransaction(
        utxoSigningData: utxoSigningData,
        recipients: [recipientAddress],
        satoshiAmounts: [satoshisBeingUsed - 1],
      ))["vSize"] as int;
    } catch (e) {
      Logging.instance.log("vSizeForOneOutput: $e", level: LogLevel.Error);
      rethrow;
    }

    final int vSizeForTwoOutPuts;
    try {
      vSizeForTwoOutPuts = (await buildTransaction(
        utxoSigningData: utxoSigningData,
        recipients: [
          recipientAddress,
          await currentChangeAddress,
        ],
        satoshiAmounts: [
          satoshiAmountToSend,
          max(0, satoshisBeingUsed - satoshiAmountToSend - 1),
        ],
      ))["vSize"] as int;
    } catch (e) {
      Logging.instance.log("vSizeForTwoOutPuts: $e", level: LogLevel.Error);
      rethrow;
    }

    // Assume 1 output, only for recipient and no change
    final feeForOneOutput = satsPerVByte != null
        ? (satsPerVByte * vSizeForOneOutput)
        : estimateTxFee(
            vSize: vSizeForOneOutput,
            feeRatePerKB: selectedTxFeeRate,
          );
    // Assume 2 outputs, one for recipient and one for change
    final feeForTwoOutputs = satsPerVByte != null
        ? (satsPerVByte * vSizeForTwoOutPuts)
        : estimateTxFee(
            vSize: vSizeForTwoOutPuts,
            feeRatePerKB: selectedTxFeeRate,
          );

    Logging.instance
        .log("feeForTwoOutputs: $feeForTwoOutputs", level: LogLevel.Info);
    Logging.instance
        .log("feeForOneOutput: $feeForOneOutput", level: LogLevel.Info);

    if (satoshisBeingUsed - satoshiAmountToSend > feeForOneOutput) {
      if (satoshisBeingUsed - satoshiAmountToSend >
          feeForOneOutput + DUST_LIMIT.raw.toInt()) {
        // Here, we know that theoretically, we may be able to include another output(change) but we first need to
        // factor in the value of this output in satoshis.
        int changeOutputSize =
            satoshisBeingUsed - satoshiAmountToSend - feeForTwoOutputs;
        // We check to see if the user can pay for the new transaction with 2 outputs instead of one. If they can and
        // the second output's size > DUST_LIMIT satoshis, we perform the mechanics required to properly generate and use a new
        // change address.
        if (changeOutputSize > DUST_LIMIT.raw.toInt() &&
            satoshisBeingUsed - satoshiAmountToSend - changeOutputSize ==
                feeForTwoOutputs) {
          // generate new change address if current change address has been used
          await _checkChangeAddressForTransactions();
          final String newChangeAddress = await currentChangeAddress;

          int feeBeingPaid =
              satoshisBeingUsed - satoshiAmountToSend - changeOutputSize;

          recipientsArray.add(newChangeAddress);
          recipientsAmtArray.add(changeOutputSize);
          // At this point, we have the outputs we're going to use, the amounts to send along with which addresses
          // we intend to send these amounts to. We have enough to send instructions to build the transaction.
          Logging.instance.log('2 outputs in tx', level: LogLevel.Info);
          Logging.instance
              .log('Input size: $satoshisBeingUsed', level: LogLevel.Info);
          Logging.instance.log('Recipient output size: $satoshiAmountToSend',
              level: LogLevel.Info);
          Logging.instance.log('Change Output Size: $changeOutputSize',
              level: LogLevel.Info);
          Logging.instance.log(
              'Difference (fee being paid): $feeBeingPaid sats',
              level: LogLevel.Info);
          Logging.instance
              .log('Estimated fee: $feeForTwoOutputs', level: LogLevel.Info);
          dynamic txn = await buildTransaction(
            utxoSigningData: utxoSigningData,
            recipients: recipientsArray,
            satoshiAmounts: recipientsAmtArray,
          );

          // make sure minimum fee is accurate if that is being used
          if (txn["vSize"] - feeBeingPaid == 1) {
            int changeOutputSize =
                satoshisBeingUsed - satoshiAmountToSend - (txn["vSize"] as int);
            feeBeingPaid =
                satoshisBeingUsed - satoshiAmountToSend - changeOutputSize;
            recipientsAmtArray.removeLast();
            recipientsAmtArray.add(changeOutputSize);
            Logging.instance.log('Adjusted Input size: $satoshisBeingUsed',
                level: LogLevel.Info);
            Logging.instance.log(
                'Adjusted Recipient output size: $satoshiAmountToSend',
                level: LogLevel.Info);
            Logging.instance.log(
                'Adjusted Change Output Size: $changeOutputSize',
                level: LogLevel.Info);
            Logging.instance.log(
                'Adjusted Difference (fee being paid): $feeBeingPaid sats',
                level: LogLevel.Info);
            Logging.instance.log('Adjusted Estimated fee: $feeForTwoOutputs',
                level: LogLevel.Info);
            txn = await buildTransaction(
              utxoSigningData: utxoSigningData,
              recipients: recipientsArray,
              satoshiAmounts: recipientsAmtArray,
            );
          }

          Map<String, dynamic> transactionObject = {
            "hex": txn["hex"],
            "recipient": recipientsArray[0],
            "recipientAmt": Amount(
              rawValue: BigInt.from(recipientsAmtArray[0]),
              fractionDigits: coin.decimals,
            ),
            "fee": feeBeingPaid,
            "vSize": txn["vSize"],
            "usedUTXOs": utxoSigningData.map((e) => e.utxo).toList(),
          };
          return transactionObject;
        } else {
          // Something went wrong here. It either overshot or undershot the estimated fee amount or the changeOutputSize
          // is smaller than or equal to DUST_LIMIT. Revert to single output transaction.
          Logging.instance.log('1 output in tx', level: LogLevel.Info);
          Logging.instance
              .log('Input size: $satoshisBeingUsed', level: LogLevel.Info);
          Logging.instance.log('Recipient output size: $satoshiAmountToSend',
              level: LogLevel.Info);
          Logging.instance.log(
              'Difference (fee being paid): ${satoshisBeingUsed - satoshiAmountToSend} sats',
              level: LogLevel.Info);
          Logging.instance
              .log('Estimated fee: $feeForOneOutput', level: LogLevel.Info);
          dynamic txn = await buildTransaction(
            utxoSigningData: utxoSigningData,
            recipients: recipientsArray,
            satoshiAmounts: recipientsAmtArray,
          );
          Map<String, dynamic> transactionObject = {
            "hex": txn["hex"],
            "recipient": recipientsArray[0],
            "recipientAmt": Amount(
              rawValue: BigInt.from(recipientsAmtArray[0]),
              fractionDigits: coin.decimals,
            ),
            "fee": satoshisBeingUsed - satoshiAmountToSend,
            "vSize": txn["vSize"],
            "usedUTXOs": utxoSigningData.map((e) => e.utxo).toList(),
          };
          return transactionObject;
        }
      } else {
        // No additional outputs needed since adding one would mean that it'd be smaller than DUST_LIMIT sats
        // which makes it uneconomical to add to the transaction. Here, we pass data directly to instruct
        // the wallet to begin crafting the transaction that the user requested.
        Logging.instance.log('1 output in tx', level: LogLevel.Info);
        Logging.instance
            .log('Input size: $satoshisBeingUsed', level: LogLevel.Info);
        Logging.instance.log('Recipient output size: $satoshiAmountToSend',
            level: LogLevel.Info);
        Logging.instance.log(
            'Difference (fee being paid): ${satoshisBeingUsed - satoshiAmountToSend} sats',
            level: LogLevel.Info);
        Logging.instance
            .log('Estimated fee: $feeForOneOutput', level: LogLevel.Info);
        dynamic txn = await buildTransaction(
          utxoSigningData: utxoSigningData,
          recipients: recipientsArray,
          satoshiAmounts: recipientsAmtArray,
        );
        Map<String, dynamic> transactionObject = {
          "hex": txn["hex"],
          "recipient": recipientsArray[0],
          "recipientAmt": Amount(
            rawValue: BigInt.from(recipientsAmtArray[0]),
            fractionDigits: coin.decimals,
          ),
          "fee": satoshisBeingUsed - satoshiAmountToSend,
          "vSize": txn["vSize"],
          "usedUTXOs": utxoSigningData.map((e) => e.utxo).toList(),
        };
        return transactionObject;
      }
    } else if (satoshisBeingUsed - satoshiAmountToSend == feeForOneOutput) {
      // In this scenario, no additional change output is needed since inputs - outputs equal exactly
      // what we need to pay for fees. Here, we pass data directly to instruct the wallet to begin
      // crafting the transaction that the user requested.
      Logging.instance.log('1 output in tx', level: LogLevel.Info);
      Logging.instance
          .log('Input size: $satoshisBeingUsed', level: LogLevel.Info);
      Logging.instance.log('Recipient output size: $satoshiAmountToSend',
          level: LogLevel.Info);
      Logging.instance.log(
          'Fee being paid: ${satoshisBeingUsed - satoshiAmountToSend} sats',
          level: LogLevel.Info);
      Logging.instance
          .log('Estimated fee: $feeForOneOutput', level: LogLevel.Info);
      dynamic txn = await buildTransaction(
        utxoSigningData: utxoSigningData,
        recipients: recipientsArray,
        satoshiAmounts: recipientsAmtArray,
      );
      Map<String, dynamic> transactionObject = {
        "hex": txn["hex"],
        "recipient": recipientsArray[0],
        "recipientAmt": Amount(
          rawValue: BigInt.from(recipientsAmtArray[0]),
          fractionDigits: coin.decimals,
        ),
        "fee": feeForOneOutput,
        "vSize": txn["vSize"],
        "usedUTXOs": utxoSigningData.map((e) => e.utxo).toList(),
      };
      return transactionObject;
    } else {
      // Remember that returning 2 indicates that the user does not have a sufficient balance to
      // pay for the transaction fee. Ideally, at this stage, we should check if the user has any
      // additional outputs they're able to spend and then recalculate fees.
      Logging.instance.log(
          'Cannot pay tx fee - checking for more outputs and trying again',
          level: LogLevel.Warning);
      // try adding more outputs
      if (spendableOutputs.length > inputsBeingConsumed) {
        return coinSelection(
          satoshiAmountToSend: satoshiAmountToSend,
          selectedTxFeeRate: selectedTxFeeRate,
          satsPerVByte: satsPerVByte,
          recipientAddress: recipientAddress,
          isSendAll: isSendAll,
          additionalOutputs: additionalOutputs + 1,
          utxos: utxos,
          coinControl: coinControl,
        );
      }
      return 2;
    }
  }

  Future<List<SigningData>> fetchBuildTxData(
    List<isar_models.UTXO> utxosToUse,
  ) async {
    // return data
    List<SigningData> signingData = [];

    try {
      // Populating the addresses to check
      for (var i = 0; i < utxosToUse.length; i++) {
        if (utxosToUse[i].address == null) {
          final txid = utxosToUse[i].txid;
          final tx = await _cachedElectrumXClient.getTransaction(
            txHash: txid,
            coin: coin,
          );
          for (final output in tx["vout"] as List) {
            final n = output["n"];
            if (n != null && n == utxosToUse[i].vout) {
              utxosToUse[i] = utxosToUse[i].copyWith(
                address: output["scriptPubKey"]?["addresses"]?[0] as String? ??
                    output["scriptPubKey"]["address"] as String,
              );
            }
          }
        }

        final derivePathType = addressType(address: utxosToUse[i].address!);

        signingData.add(
          SigningData(
            derivePathType: derivePathType,
            utxo: utxosToUse[i],
          ),
        );
      }

      Map<DerivePathType, Map<String, dynamic>> receiveDerivations = {};
      Map<DerivePathType, Map<String, dynamic>> changeDerivations = {};

      for (final sd in signingData) {
        String? pubKey;
        String? wif;

        final address = await db.getAddress(walletId, sd.utxo.address!);
        if (address?.derivationPath != null) {
          final bip32.BIP32 node;
          if (address!.subType == isar_models.AddressSubType.paynymReceive) {
            final code = await paymentCodeStringByKey(address.otherData!);

            final bip47base = await getBip47BaseNode();

            final privateKey = await getPrivateKeyForPaynymReceivingAddress(
              paymentCodeString: code!,
              index: address.derivationIndex,
            );

            node = bip32.BIP32.fromPrivateKey(
              privateKey,
              bip47base.chainCode,
              bip32.NetworkType(
                wif: _network.wif,
                bip32: bip32.Bip32Type(
                  public: _network.bip32.public,
                  private: _network.bip32.private,
                ),
              ),
            );
          } else {
            node = await Bip32Utils.getBip32Node(
              (await mnemonicString)!,
              (await mnemonicPassphrase)!,
              _network,
              address.derivationPath!.value,
            );
          }

          wif = node.toWIF();
          pubKey = Format.uint8listToString(node.publicKey);
        }

        if (wif == null || pubKey == null) {
          // fetch receiving derivations if null
          receiveDerivations[sd.derivePathType] ??= await _fetchDerivations(
            chain: 0,
            derivePathType: sd.derivePathType,
          );
          final receiveDerivation =
              receiveDerivations[sd.derivePathType]![sd.utxo.address!];

          if (receiveDerivation != null) {
            pubKey = receiveDerivation["pubKey"] as String;
            wif = receiveDerivation["wif"] as String;
          } else {
            // fetch change derivations if null
            changeDerivations[sd.derivePathType] ??= await _fetchDerivations(
              chain: 1,
              derivePathType: sd.derivePathType,
            );
            final changeDerivation =
                changeDerivations[sd.derivePathType]![sd.utxo.address!];
            if (changeDerivation != null) {
              pubKey = changeDerivation["pubKey"] as String;
              wif = changeDerivation["wif"] as String;
            }
          }
        }

        if (wif != null && pubKey != null) {
          final PaymentData data;
          final Uint8List? redeemScript;

          switch (sd.derivePathType) {
            case DerivePathType.bip44:
              data = P2PKH(
                data: PaymentData(
                  pubkey: Format.stringToUint8List(pubKey),
                ),
                network: _network,
              ).data;
              redeemScript = null;
              break;

            case DerivePathType.bip49:
              final p2wpkh = P2WPKH(
                data: PaymentData(
                  pubkey: Format.stringToUint8List(pubKey),
                ),
                network: _network,
              ).data;
              redeemScript = p2wpkh.output;
              data = P2SH(
                data: PaymentData(redeem: p2wpkh),
                network: _network,
              ).data;
              break;

            case DerivePathType.bip84:
              data = P2WPKH(
                data: PaymentData(
                  pubkey: Format.stringToUint8List(pubKey),
                ),
                network: _network,
              ).data;
              redeemScript = null;
              break;

            default:
              throw Exception("DerivePathType unsupported");
          }

          final keyPair = ECPair.fromWIF(
            wif,
            network: _network,
          );

          sd.redeemScript = redeemScript;
          sd.output = data.output;
          sd.keyPair = keyPair;
        }
      }

      return signingData;
    } catch (e, s) {
      Logging.instance
          .log("fetchBuildTxData() threw: $e,\n$s", level: LogLevel.Error);
      rethrow;
    }
  }

  /// Builds and signs a transaction
  Future<Map<String, dynamic>> buildTransaction({
    required List<SigningData> utxoSigningData,
    required List<String> recipients,
    required List<int> satoshiAmounts,
  }) async {
    Logging.instance
        .log("Starting buildTransaction ----------", level: LogLevel.Info);

    final txb = TransactionBuilder(network: _network);
    txb.setVersion(1);

    // Add transaction inputs
    for (var i = 0; i < utxoSigningData.length; i++) {
      final txid = utxoSigningData[i].utxo.txid;
      txb.addInput(
        txid,
        utxoSigningData[i].utxo.vout,
        null,
        utxoSigningData[i].output!,
      );
    }

    // Add transaction output
    for (var i = 0; i < recipients.length; i++) {
      txb.addOutput(recipients[i], satoshiAmounts[i]);
    }

    try {
      // Sign the transaction accordingly
      for (var i = 0; i < utxoSigningData.length; i++) {
        txb.sign(
          vin: i,
          keyPair: utxoSigningData[i].keyPair!,
          witnessValue: utxoSigningData[i].utxo.value,
          redeemScript: utxoSigningData[i].redeemScript,
        );
      }
    } catch (e, s) {
      Logging.instance.log("Caught exception while signing transaction: $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }

    final builtTx = txb.build();
    final vSize = builtTx.virtualSize();

    return {"hex": builtTx.toHex(), "vSize": vSize};
  }

  @override
  Future<void> fullRescan(
    int maxUnusedAddressGap,
    int maxNumberOfIndexesToCheck,
  ) async {
    Logging.instance.log("Starting full rescan!", level: LogLevel.Info);
    longMutex = true;
    GlobalEventBus.instance.fire(
      WalletSyncStatusChangedEvent(
        WalletSyncStatus.syncing,
        walletId,
        coin,
      ),
    );

    // clear cache
    await _cachedElectrumXClient.clearSharedTransactionCache(coin: coin);

    // back up data
    // await _rescanBackup();

    await db.deleteWalletBlockchainData(walletId);
    await _deleteDerivations();

    try {
      final _mnemonic = await mnemonicString;
      final _mnemonicPassphrase = await mnemonicPassphrase;
      if (_mnemonicPassphrase == null) {
        Logging.instance.log(
            "Exception in fullRescan: mnemonic passphrase null, possible migration issue; if using internal builds, delete wallet and restore from seed, if using a release build, please file bug report",
            level: LogLevel.Error);
      }

      await _recoverWalletFromBIP32SeedPhrase(
        mnemonic: _mnemonic!,
        mnemonicPassphrase: _mnemonicPassphrase!,
        maxUnusedAddressGap: maxUnusedAddressGap,
        maxNumberOfIndexesToCheck: maxNumberOfIndexesToCheck,
        isRescan: true,
      );

      longMutex = false;
      await refresh();
      Logging.instance.log("Full rescan complete!", level: LogLevel.Info);
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.synced,
          walletId,
          coin,
        ),
      );
    } catch (e, s) {
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.unableToSync,
          walletId,
          coin,
        ),
      );

      // restore from backup
      // await _rescanRestore();

      longMutex = false;
      Logging.instance.log("Exception rethrown from fullRescan(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Future<void> _deleteDerivations() async {
    // P2PKH derivations
    await _secureStore.delete(key: "${walletId}_receiveDerivationsP2PKH");
    await _secureStore.delete(key: "${walletId}_changeDerivationsP2PKH");

    // P2SH derivations
    await _secureStore.delete(key: "${walletId}_receiveDerivationsP2SH");
    await _secureStore.delete(key: "${walletId}_changeDerivationsP2SH");

    // P2WPKH derivations
    await _secureStore.delete(key: "${walletId}_receiveDerivationsP2WPKH");
    await _secureStore.delete(key: "${walletId}_changeDerivationsP2WPKH");
  }

  bool isActive = false;

  @override
  void Function(bool)? get onIsActiveWalletChanged =>
      (isActive) => this.isActive = isActive;

  @override
  Future<Amount> estimateFeeFor(Amount amount, int feeRate) async {
    final available = balance.spendable;

    if (available == amount) {
      return amount - (await sweepAllEstimate(feeRate));
    } else if (amount <= Amount.zero || amount > available) {
      return roughFeeEstimate(1, 2, feeRate);
    }

    Amount runningBalance = Amount(
      rawValue: BigInt.zero,
      fractionDigits: coin.decimals,
    );
    int inputCount = 0;
    for (final output in (await utxos)) {
      if (!output.isBlocked) {
        runningBalance += Amount(
          rawValue: BigInt.from(output.value),
          fractionDigits: coin.decimals,
        );
        inputCount++;
        if (runningBalance > amount) {
          break;
        }
      }
    }

    final oneOutPutFee = roughFeeEstimate(inputCount, 1, feeRate);
    final twoOutPutFee = roughFeeEstimate(inputCount, 2, feeRate);

    if (runningBalance - amount > oneOutPutFee) {
      if (runningBalance - amount > oneOutPutFee + DUST_LIMIT) {
        final change = runningBalance - amount - twoOutPutFee;
        if (change > DUST_LIMIT &&
            runningBalance - amount - change == twoOutPutFee) {
          return runningBalance - amount - change;
        } else {
          return runningBalance - amount;
        }
      } else {
        return runningBalance - amount;
      }
    } else if (runningBalance - amount == oneOutPutFee) {
      return oneOutPutFee;
    } else {
      return twoOutPutFee;
    }
  }

  Amount roughFeeEstimate(int inputCount, int outputCount, int feeRatePerKB) {
    return Amount(
      rawValue: BigInt.from(
          ((42 + (272 * inputCount) + (128 * outputCount)) / 4).ceil() *
              (feeRatePerKB / 1000).ceil()),
      fractionDigits: coin.decimals,
    );
  }

  Future<Amount> sweepAllEstimate(int feeRate) async {
    int available = 0;
    int inputCount = 0;
    for (final output in (await utxos)) {
      if (!output.isBlocked &&
          output.isConfirmed(storedChainHeight, MINIMUM_CONFIRMATIONS)) {
        available += output.value;
        inputCount++;
      }
    }

    // transaction will only have 1 output minus the fee
    final estimatedFee = roughFeeEstimate(inputCount, 1, feeRate);

    return Amount(
          rawValue: BigInt.from(available),
          fractionDigits: coin.decimals,
        ) -
        estimatedFee;
  }

  @override
  Future<bool> generateNewAddress() async {
    try {
      final currentReceiving = await _currentReceivingAddress;

      final newReceivingIndex = currentReceiving.derivationIndex + 1;

      // Use new index to derive a new receiving address
      final newReceivingAddress = await _generateAddressForChain(
          0, newReceivingIndex, DerivePathTypeExt.primaryFor(coin));

      // Add that new receiving address
      await db.putAddress(newReceivingAddress);

      return true;
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from generateNewAddress(): $e\n$s",
          level: LogLevel.Error);
      return false;
    }
  }

  @override
  Future<String> get xpub async {
    final node = await Bip32Utils.getBip32Root(
      (await mnemonic).join(" "),
      await mnemonicPassphrase ?? "",
      _network,
    );

    return node.neutered().toBase58();
  }
}

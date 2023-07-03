import 'dart:convert';

import 'package:stackduo/db/hive/db.dart';
import 'package:stackduo/electrumx_rpc/electrumx.dart';
import 'package:stackduo/utilities/enums/coin_enum.dart';
import 'package:stackduo/utilities/logger.dart';
import 'package:string_validator/string_validator.dart';

class CachedElectrumX {
  final ElectrumX electrumXClient;

  static const minCacheConfirms = 30;

  const CachedElectrumX({
    required this.electrumXClient,
  });

  factory CachedElectrumX.from({
    required ElectrumX electrumXClient,
  }) =>
      CachedElectrumX(
        electrumXClient: electrumXClient,
      );

  Future<Map<String, dynamic>> getAnonymitySet({
    required String groupId,
    String blockhash = "",
    required Coin coin,
  }) async {
    try {
      final box = await DB.instance.getAnonymitySetCacheBox(coin: coin);
      final cachedSet = box.get(groupId) as Map?;

      Map<String, dynamic> set;

      // null check to see if there is a cached set
      if (cachedSet == null) {
        set = {
          "setId": groupId,
          "blockHash": blockhash,
          "setHash": "",
          "coins": <dynamic>[],
        };
      } else {
        set = Map<String, dynamic>.from(cachedSet);
      }

      final newSet = await electrumXClient.getAnonymitySet(
        groupId: groupId,
        blockhash: set["blockHash"] as String,
      );

      // update set with new data
      if (newSet["setHash"] != "" && set["setHash"] != newSet["setHash"]) {
        set["setHash"] = !isHexadecimal(newSet["setHash"] as String)
            ? base64ToHex(newSet["setHash"] as String)
            : newSet["setHash"];
        set["blockHash"] = !isHexadecimal(newSet["blockHash"] as String)
            ? base64ToReverseHex(newSet["blockHash"] as String)
            : newSet["blockHash"];
        for (int i = (newSet["coins"] as List).length - 1; i >= 0; i--) {
          dynamic newCoin = newSet["coins"][i];
          List<dynamic> translatedCoin = [];
          translatedCoin.add(!isHexadecimal(newCoin[0] as String)
              ? base64ToHex(newCoin[0] as String)
              : newCoin[0]);
          translatedCoin.add(!isHexadecimal(newCoin[1] as String)
              ? base64ToReverseHex(newCoin[1] as String)
              : newCoin[1]);
          try {
            translatedCoin.add(!isHexadecimal(newCoin[2] as String)
                ? base64ToHex(newCoin[2] as String)
                : newCoin[2]);
          } catch (e, s) {
            translatedCoin.add(newCoin[2]);
          }
          translatedCoin.add(!isHexadecimal(newCoin[3] as String)
              ? base64ToReverseHex(newCoin[3] as String)
              : newCoin[3]);
          set["coins"].insert(0, translatedCoin);
        }
        // save set to db
        await box.put(groupId, set);
        Logging.instance.log(
          "Updated current anonymity set for ${coin.name} with group ID $groupId",
          level: LogLevel.Info,
        );
      }

      return set;
    } catch (e, s) {
      Logging.instance.log(
          "Failed to process CachedElectrumX.getAnonymitySet(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    } finally {
      await DB.instance.closeAnonymitySetCacheBox(coin: coin);
    }
  }

  String base64ToHex(String source) =>
      base64Decode(LineSplitter.split(source).join())
          .map((e) => e.toRadixString(16).padLeft(2, '0'))
          .join();

  String base64ToReverseHex(String source) =>
      base64Decode(LineSplitter.split(source).join())
          .reversed
          .map((e) => e.toRadixString(16).padLeft(2, '0'))
          .join();

  /// Call electrumx getTransaction on a per coin basis, storing the result in local db if not already there.
  ///
  /// ElectrumX api only called if the tx does not exist in local db
  Future<Map<String, dynamic>> getTransaction({
    required String txHash,
    required Coin coin,
    bool verbose = true,
  }) async {
    try {
      final box = await DB.instance.getTxCacheBox(coin: coin);

      final cachedTx = box.get(txHash) as Map?;
      if (cachedTx == null) {
        final Map<String, dynamic> result = await electrumXClient
            .getTransaction(txHash: txHash, verbose: verbose);

        result.remove("hex");
        result.remove("lelantusData");

        if (result["confirmations"] != null &&
            result["confirmations"] as int > minCacheConfirms) {
          await box.put(txHash, result);
        }

        Logging.instance.log("using fetched result", level: LogLevel.Info);
        return result;
      } else {
        Logging.instance.log("using cached result", level: LogLevel.Info);
        return Map<String, dynamic>.from(cachedTx);
      }
    } catch (e, s) {
      Logging.instance.log(
          "Failed to process CachedElectrumX.getTransaction(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    } finally {
      await DB.instance.closeTxCacheBox(coin: coin);
    }
  }

  Future<List<String>> getUsedCoinSerials({
    required Coin coin,
    int startNumber = 0,
  }) async {
    try {
      final box = await DB.instance.getUsedSerialsCacheBox(coin: coin);

      final _list = box.get("serials") as List?;

      List<String> cachedSerials =
          _list == null ? [] : List<String>.from(_list);

      final startNumber = cachedSerials.length;

      final serials =
          await electrumXClient.getUsedCoinSerials(startNumber: startNumber);
      List<String> newSerials = [];

      for (final element in (serials["serials"] as List)) {
        if (!isHexadecimal(element as String)) {
          newSerials.add(base64ToHex(element));
        } else {
          newSerials.add(element);
        }
      }
      cachedSerials.addAll(newSerials);

      await box.put(
        "serials",
        cachedSerials,
      );

      return cachedSerials;
    } catch (e, s) {
      Logging.instance.log(
          "Failed to process CachedElectrumX.getTransaction(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    } finally {
      await DB.instance.closeUsedSerialsCacheBox(coin: coin);
    }
  }

  /// Clear all cached transactions for the specified coin
  Future<void> clearSharedTransactionCache({required Coin coin}) async {
    await DB.instance.closeAnonymitySetCacheBox(coin: coin);
  }
}

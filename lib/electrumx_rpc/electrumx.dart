import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:decimal/decimal.dart';
import 'package:stackduo/electrumx_rpc/rpc.dart';
import 'package:stackduo/exceptions/electrumx/no_such_transaction.dart';
import 'package:stackduo/utilities/logger.dart';
import 'package:stackduo/utilities/prefs.dart';
import 'package:uuid/uuid.dart';

class WifiOnlyException implements Exception {}

class ElectrumXNode {
  ElectrumXNode({
    required this.address,
    required this.port,
    required this.name,
    required this.id,
    required this.useSSL,
  });
  final String address;
  final int port;
  final String name;
  final String id;
  final bool useSSL;

  factory ElectrumXNode.from(ElectrumXNode node) {
    return ElectrumXNode(
      address: node.address,
      port: node.port,
      name: node.name,
      id: node.id,
      useSSL: node.useSSL,
    );
  }

  @override
  String toString() {
    return "ElectrumXNode: {address: $address, port: $port, name: $name, useSSL: $useSSL}";
  }
}

class ElectrumX {
  String get host => _host;
  late String _host;

  int get port => _port;
  late int _port;

  bool get useSSL => _useSSL;
  late bool _useSSL;

  JsonRPC? get rpcClient => _rpcClient;
  JsonRPC? _rpcClient;

  late Prefs _prefs;

  List<ElectrumXNode>? failovers;
  int currentFailoverIndex = -1;

  ElectrumX(
      {required String host,
      required int port,
      required bool useSSL,
      required Prefs prefs,
      required List<ElectrumXNode> failovers,
      JsonRPC? client}) {
    _prefs = prefs;
    _host = host;
    _port = port;
    _useSSL = useSSL;
    _rpcClient = client;
  }

  factory ElectrumX.from({
    required ElectrumXNode node,
    required Prefs prefs,
    required List<ElectrumXNode> failovers,
  }) =>
      ElectrumX(
        host: node.address,
        port: node.port,
        useSSL: node.useSSL,
        prefs: prefs,
        failovers: failovers,
      );

  Future<bool> _allow() async {
    if (_prefs.wifiOnly) {
      return (await Connectivity().checkConnectivity()) ==
          ConnectivityResult.wifi;
    }
    return true;
  }

  /// Send raw rpc command
  Future<dynamic> request({
    required String command,
    List<dynamic> args = const [],
    Duration connectionTimeout = const Duration(seconds: 60),
    String? requestID,
    int retries = 2,
  }) async {
    if (!(await _allow())) {
      throw WifiOnlyException();
    }

    if (currentFailoverIndex == -1) {
      _rpcClient ??= JsonRPC(
        host: host,
        port: port,
        useSSL: useSSL,
        connectionTimeout: connectionTimeout,
      );
    } else {
      _rpcClient = JsonRPC(
        host: failovers![currentFailoverIndex].address,
        port: failovers![currentFailoverIndex].port,
        useSSL: failovers![currentFailoverIndex].useSSL,
        connectionTimeout: connectionTimeout,
      );
    }

    try {
      final requestId = requestID ?? const Uuid().v1();
      final jsonArgs = json.encode(args);
      final jsonRequestString =
          '{"jsonrpc": "2.0", "id": "$requestId","method": "$command","params": $jsonArgs}';

      // Logging.instance.log("ElectrumX jsonRequestString: $jsonRequestString");

      final response = await _rpcClient!.request(jsonRequestString);

      if (response.exception != null) {
        throw response.exception!;
      }

      if (response.data["error"] != null) {
        if (response.data["error"]
            .toString()
            .contains("No such mempool or blockchain transaction")) {
          throw NoSuchTransactionException(
            "No such mempool or blockchain transaction",
            args.first.toString(),
          );
        }

        throw Exception(
          "JSONRPC response\n"
          "     command: $command\n"
          "     args: $args\n"
          "     error: $response.data",
        );
      }

      currentFailoverIndex = -1;
      return response.data;
    } on WifiOnlyException {
      rethrow;
    } on SocketException {
      // likely timed out so then retry
      if (retries > 0) {
        return request(
          command: command,
          args: args,
          connectionTimeout: connectionTimeout,
          requestID: requestID,
          retries: retries - 1,
        );
      } else {
        rethrow;
      }
    } catch (e) {
      if (failovers != null && currentFailoverIndex < failovers!.length - 1) {
        currentFailoverIndex++;
        return request(
          command: command,
          args: args,
          connectionTimeout: connectionTimeout,
          requestID: requestID,
        );
      } else {
        currentFailoverIndex = -1;
        rethrow;
      }
    }
  }

  /// send a batch request with [command] where [args] is a
  /// map of <request id string : arguments list>
  ///
  /// returns a list of json response objects if no errors were found
  Future<List<Map<String, dynamic>>> batchRequest({
    required String command,
    required Map<String, List<dynamic>> args,
    Duration connectionTimeout = const Duration(seconds: 60),
    int retries = 2,
  }) async {
    if (!(await _allow())) {
      throw WifiOnlyException();
    }

    if (currentFailoverIndex == -1) {
      _rpcClient ??= JsonRPC(
        host: host,
        port: port,
        useSSL: useSSL,
        connectionTimeout: connectionTimeout,
      );
    } else {
      _rpcClient = JsonRPC(
        host: failovers![currentFailoverIndex].address,
        port: failovers![currentFailoverIndex].port,
        useSSL: failovers![currentFailoverIndex].useSSL,
        connectionTimeout: connectionTimeout,
      );
    }

    try {
      final List<String> requestStrings = [];

      for (final entry in args.entries) {
        final jsonArgs = json.encode(entry.value);
        requestStrings.add(
            '{"jsonrpc": "2.0", "id": "${entry.key}","method": "$command","params": $jsonArgs}');
      }

      // combine request strings into json array
      String request = "[";
      for (int i = 0; i < requestStrings.length - 1; i++) {
        request += "${requestStrings[i]},";
      }
      request += "${requestStrings.last}]";

      // Logging.instance.log("batch request: $request");

      // send batch request
      final jsonRpcResponse = (await _rpcClient!.request(request));

      if (jsonRpcResponse.exception != null) {
        throw jsonRpcResponse.exception!;
      }

      final response = jsonRpcResponse.data as List;

      // check for errors, format and throw if there are any
      final List<String> errors = [];
      for (int i = 0; i < response.length; i++) {
        final result = response[i];
        if (result["error"] != null || result["result"] == null) {
          errors.add(result.toString());
        }
      }
      if (errors.isNotEmpty) {
        String error = "[\n";
        for (int i = 0; i < errors.length; i++) {
          error += "${errors[i]}\n";
        }
        error += "]";
        throw Exception("JSONRPC response error: $error");
      }

      currentFailoverIndex = -1;
      return List<Map<String, dynamic>>.from(response, growable: false);
    } on WifiOnlyException {
      rethrow;
    } on SocketException {
      // likely timed out so then retry
      if (retries > 0) {
        return batchRequest(
          command: command,
          args: args,
          connectionTimeout: connectionTimeout,
          retries: retries - 1,
        );
      } else {
        rethrow;
      }
    } catch (e) {
      if (failovers != null && currentFailoverIndex < failovers!.length - 1) {
        currentFailoverIndex++;
        return batchRequest(
          command: command,
          args: args,
          connectionTimeout: connectionTimeout,
        );
      } else {
        currentFailoverIndex = -1;
        rethrow;
      }
    }
  }

  /// Ping the server to ensure it is responding
  ///
  /// Returns true if ping succeeded
  Future<bool> ping({String? requestID, int retryCount = 1}) async {
    try {
      final response = await request(
        requestID: requestID,
        command: 'server.ping',
        connectionTimeout: const Duration(seconds: 2),
        retries: retryCount,
      ).timeout(const Duration(seconds: 2)) as Map<String, dynamic>;
      return response.keys.contains("result") && response["result"] == null;
    } catch (e) {
      rethrow;
    }
  }

  /// Get most recent block header.
  ///
  /// Returns a map with keys 'height' and 'hex' corresponding to the block height
  /// and the binary header as a hexadecimal string.
  /// Ex:
  /// {
  //   "height": 520481,
  //   "hex": "00000020890208a0ae3a3892aa047c5468725846577cfcd9b512b50000000000000000005dc2b02f2d297a9064ee103036c14d678f9afc7e3d9409cf53fd58b82e938e8ecbeca05a2d2103188ce804c4"
  // }
  Future<Map<String, dynamic>> getBlockHeadTip({String? requestID}) async {
    try {
      final response = await request(
        requestID: requestID,
        command: 'blockchain.headers.subscribe',
      );
      if (response["result"] == null) {
        Logging.instance.log(
          "getBlockHeadTip returned null response",
          level: LogLevel.Error,
        );
        throw 'getBlockHeadTip returned null response';
      }
      return Map<String, dynamic>.from(response["result"] as Map);
    } catch (e) {
      rethrow;
    }
  }

  /// Get server info
  ///
  /// Returns a map with server information
  /// Ex:
  // {
  // "genesis_hash": "000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943",
  // "hosts": {"14.3.140.101": {"tcp_port": 51001, "ssl_port": 51002}},
  // "protocol_max": "1.0",
  // "protocol_min": "1.0",
  // "pruning": null,
  // "server_version": "ElectrumX 1.0.17",
  // "hash_function": "sha256"
  // }
  Future<Map<String, dynamic>> getServerFeatures({String? requestID}) async {
    try {
      final response = await request(
        requestID: requestID,
        command: 'server.features',
      );
      return Map<String, dynamic>.from(response["result"] as Map);
    } catch (e) {
      rethrow;
    }
  }

  /// Broadcast a transaction to the network.
  ///
  /// The transaction hash as a hexadecimal string.
  Future<String> broadcastTransaction({
    required String rawTx,
    String? requestID,
  }) async {
    try {
      final response = await request(
        requestID: requestID,
        command: 'blockchain.transaction.broadcast',
        args: [
          rawTx,
        ],
      );
      return response["result"] as String;
    } catch (e) {
      rethrow;
    }
  }

  /// Return the confirmed and unconfirmed balances for the scripthash of a given scripthash
  ///
  /// Returns a map with keys confirmed and unconfirmed. The value of each is
  /// the appropriate balance in minimum coin units (satoshis).
  /// Ex:
  /// {
  ///   "confirmed": 103873966,
  ///   "unconfirmed": 23684400
  /// }
  Future<Map<String, dynamic>> getBalance({
    required String scripthash,
    String? requestID,
  }) async {
    try {
      final response = await request(
        requestID: requestID,
        command: 'blockchain.scripthash.get_balance',
        args: [
          scripthash,
        ],
      );
      return Map<String, dynamic>.from(response["result"] as Map);
    } catch (e) {
      rethrow;
    }
  }

  /// Return the confirmed and unconfirmed history for the given scripthash.
  ///
  /// Returns a list of maps that contain the tx_hash and height of the tx.
  /// Ex:
  /// [
  //   {
  //     "height": 200004,
  //     "tx_hash": "acc3758bd2a26f869fcc67d48ff30b96464d476bca82c1cd6656e7d506816412"
  //   },
  //   {
  //     "height": 215008,
  //     "tx_hash": "f3e1bf48975b8d6060a9de8884296abb80be618dc00ae3cb2f6cee3085e09403"
  //   }
  // ]
  Future<List<Map<String, dynamic>>> getHistory({
    required String scripthash,
    String? requestID,
  }) async {
    try {
      final response = await request(
        requestID: requestID,
        command: 'blockchain.scripthash.get_history',
        connectionTimeout: const Duration(minutes: 5),
        args: [
          scripthash,
        ],
      );
      return List<Map<String, dynamic>>.from(response["result"] as List);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> getBatchHistory(
      {required Map<String, List<dynamic>> args}) async {
    try {
      final response = await batchRequest(
        command: 'blockchain.scripthash.get_history',
        args: args,
      );
      final Map<String, List<Map<String, dynamic>>> result = {};
      for (int i = 0; i < response.length; i++) {
        result[response[i]["id"] as String] =
            List<Map<String, dynamic>>.from(response[i]["result"] as List);
      }
      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// Return an ordered list of UTXOs sent to a script hash of the given scripthash.
  ///
  /// Returns a list of maps.
  /// Ex:
  /// [
  //   {
  //     "tx_pos": 0,
  //     "value": 45318048,
  //     "tx_hash": "9f2c45a12db0144909b5db269415f7319179105982ac70ed80d76ea79d923ebf",
  //     "height": 437146
  //   },
  //   {
  //     "tx_pos": 0,
  //     "value": 919195,
  //     "tx_hash": "3d2290c93436a3e964cfc2f0950174d8847b1fbe3946432c4784e168da0f019f",
  //     "height": 441696
  //   }
  // ]
  Future<List<Map<String, dynamic>>> getUTXOs({
    required String scripthash,
    String? requestID,
  }) async {
    try {
      final response = await request(
        requestID: requestID,
        command: 'blockchain.scripthash.listunspent',
        args: [
          scripthash,
        ],
      );
      return List<Map<String, dynamic>>.from(response["result"] as List);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> getBatchUTXOs(
      {required Map<String, List<dynamic>> args}) async {
    try {
      final response = await batchRequest(
        command: 'blockchain.scripthash.listunspent',
        args: args,
      );
      final Map<String, List<Map<String, dynamic>>> result = {};
      for (int i = 0; i < response.length; i++) {
        result[response[i]["id"] as String] =
            List<Map<String, dynamic>>.from(response[i]["result"] as List);
      }
      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// Returns a raw transaction given the tx_hash.
  ///
  /// Returns a list of maps.
  /// Ex when verbose=false:
  /// "01000000015bb9142c960a838329694d3fe9ba08c2a6421c5158d8f7044cb7c48006c1b48"
  /// "4000000006a4730440220229ea5359a63c2b83a713fcc20d8c41b20d48fe639a639d2a824"
  /// "6a137f29d0fc02201de12de9c056912a4e581a62d12fb5f43ee6c08ed0238c32a1ee76921"
  /// "3ca8b8b412103bcf9a004f1f7a9a8d8acce7b51c983233d107329ff7c4fb53e44c855dbe1"
  /// "f6a4feffffff02c6b68200000000001976a9141041fb024bd7a1338ef1959026bbba86006"
  /// "4fe5f88ac50a8cf00000000001976a91445dac110239a7a3814535c15858b939211f85298"
  /// "88ac61ee0700"
  ///
  ///
  /// Ex when verbose=true:
  /// {
  ///   "blockhash": "0000000000000000015a4f37ece911e5e3549f988e855548ce7494a0a08b2ad6",
  ///   "blocktime": 1520074861,
  ///   "confirmations": 679,
  ///   "hash": "36a3692a41a8ac60b73f7f41ee23f5c917413e5b2fad9e44b34865bd0d601a3d",
  ///   "hex": "01000000015bb9142c960a838329694d3fe9ba08c2a6421c5158d8f7044cb7c48006c1b484000000006a4730440220229ea5359a63c2b83a713fcc20d8c41b20d48fe639a639d2a8246a137f29d0fc02201de12de9c056912a4e581a62d12fb5f43ee6c08ed0238c32a1ee769213ca8b8b412103bcf9a004f1f7a9a8d8acce7b51c983233d107329ff7c4fb53e44c855dbe1f6a4feffffff02c6b68200000000001976a9141041fb024bd7a1338ef1959026bbba860064fe5f88ac50a8cf00000000001976a91445dac110239a7a3814535c15858b939211f8529888ac61ee0700",
  ///   "locktime": 519777,
  ///   "size": 225,
  ///   "time": 1520074861,
  ///   "txid": "36a3692a41a8ac60b73f7f41ee23f5c917413e5b2fad9e44b34865bd0d601a3d",
  ///   "version": 1,
  ///   "vin": [ {
  ///     "scriptSig": {
  ///       "asm": "30440220229ea5359a63c2b83a713fcc20d8c41b20d48fe639a639d2a8246a137f29d0fc02201de12de9c056912a4e581a62d12fb5f43ee6c08ed0238c32a1ee769213ca8b8b[ALL|FORKID] 03bcf9a004f1f7a9a8d8acce7b51c983233d107329ff7c4fb53e44c855dbe1f6a4",
  ///       "hex": "4730440220229ea5359a63c2b83a713fcc20d8c41b20d48fe639a639d2a8246a137f29d0fc02201de12de9c056912a4e581a62d12fb5f43ee6c08ed0238c32a1ee769213ca8b8b412103bcf9a004f1f7a9a8d8acce7b51c983233d107329ff7c4fb53e44c855dbe1f6a4"
  ///     },
  ///     "sequence": 4294967294,
  ///     "txid": "84b4c10680c4b74c04f7d858511c42a6c208bae93f4d692983830a962c14b95b",
  ///     "vout": 0}],
  ///   "vout": [ { "n": 0,
  ///              "scriptPubKey": { "addresses": [ "12UxrUZ6tyTLoR1rT1N4nuCgS9DDURTJgP"],
  ///                                "asm": "OP_DUP OP_HASH160 1041fb024bd7a1338ef1959026bbba860064fe5f OP_EQUALVERIFY OP_CHECKSIG",
  ///                                "hex": "76a9141041fb024bd7a1338ef1959026bbba860064fe5f88ac",
  ///                                "reqSigs": 1,
  ///                                "type": "pubkeyhash"},
  ///              "value": 0.0856647},
  ///            { "n": 1,
  ///              "scriptPubKey": { "addresses": [ "17NMgYPrguizvpJmB1Sz62ZHeeFydBYbZJ"],
  ///                                "asm": "OP_DUP OP_HASH160 45dac110239a7a3814535c15858b939211f85298 OP_EQUALVERIFY OP_CHECKSIG",
  ///                                "hex": "76a91445dac110239a7a3814535c15858b939211f8529888ac",
  ///                                "reqSigs": 1,
  ///                                "type": "pubkeyhash"},
  ///              "value": 0.1360904}]}
  Future<Map<String, dynamic>> getTransaction({
    required String txHash,
    bool verbose = true,
    String? requestID,
  }) async {
    try {
      final response = await request(
        requestID: requestID,
        command: 'blockchain.transaction.get',
        args: [
          txHash,
          verbose,
        ],
      );
      if (!verbose) {
        return {"rawtx": response["result"] as String};
      }

      return Map<String, dynamic>.from(response["result"] as Map);
    } catch (e) {
      rethrow;
    }
  }

  /// Returns the whole anonymity set for denomination in the groupId.
  ///
  /// ex:
  ///  {
  ///     "blockHash": "37effb57352693f4efcb1710bf68e3a0d79ff6b8f1605529de3e0706d9ca21da",
  ///     "setHash": "aae1a64f19f5ccce1c242dfe331d8db2883a9508d998efa3def8a64844170fe4",
  ///     "coins": [
  ///               [dynamic list of length 4],
  ///               [dynamic list of length 4],
  ///               ....
  ///               [dynamic list of length 4],
  ///               [dynamic list of length 4],
  ///         ]
  ///   }
  Future<Map<String, dynamic>> getAnonymitySet({
    String groupId = "1",
    String blockhash = "",
    String? requestID,
  }) async {
    try {
      Logging.instance.log("attempting to fetch lelantus.getanonymityset...",
          level: LogLevel.Info);
      final response = await request(
        requestID: requestID,
        command: 'lelantus.getanonymityset',
        args: [
          groupId,
          blockhash,
        ],
      );
      Logging.instance.log("Fetching lelantus.getanonymityset finished",
          level: LogLevel.Info);
      return Map<String, dynamic>.from(response["result"] as Map);
    } catch (e) {
      rethrow;
    }
  }

  //TODO add example to docs
  ///
  ///
  /// Returns the block height and groupId of pubcoin.
  Future<dynamic> getMintData({dynamic mints, String? requestID}) async {
    try {
      final response = await request(
        requestID: requestID,
        command: 'lelantus.getmintmetadata',
        args: [
          mints,
        ],
      );
      return response["result"];
    } catch (e) {
      rethrow;
    }
  }

  //TODO add example to docs
  /// Returns the whole set of the used coin serials.
  Future<Map<String, dynamic>> getUsedCoinSerials({
    String? requestID,
    required int startNumber,
  }) async {
    try {
      final response = await request(
          requestID: requestID,
          command: 'lelantus.getusedcoinserials',
          args: [
            "$startNumber",
          ]);
      return Map<String, dynamic>.from(response["result"] as Map);
    } catch (e) {
      Logging.instance.log(e, level: LogLevel.Error);
      rethrow;
    }
  }

  /// Returns the latest set id
  ///
  /// ex: 1
  Future<int> getLatestCoinId({String? requestID}) async {
    try {
      final response = await request(
        requestID: requestID,
        command: 'lelantus.getlatestcoinid',
      );
      return response["result"] as int;
    } catch (e) {
      Logging.instance.log(e, level: LogLevel.Error);
      rethrow;
    }
  }

  // /// Returns about 13 megabytes of json data as of march 2, 2022
  // Future<Map<String, dynamic>> getCoinsForRecovery(
  //     {dynamic setId, String requestID}) async {
  //   try {
  //     final response = await request(
  //       requestID: requestID,
  //       command: 'lelantus.getcoinsforrecovery',
  //       args: [
  //         setId ?? 1,
  //       ],
  //     );
  //     return response["result"];
  //   } catch (e) {
  //     Logging.instance.log(e);
  //     throw e;
  //   }
  // }

  /// Get the current fee rate.
  ///
  /// Returns a map with the kay "rate" that corresponds to the free rate in satoshis
  /// Ex:
  /// {
  //   "rate": 1000,
  // }
  Future<Map<String, dynamic>> getFeeRate({String? requestID}) async {
    try {
      final response = await request(
        requestID: requestID,
        command: 'blockchain.getfeerate',
      );
      return Map<String, dynamic>.from(response["result"] as Map);
    } catch (e) {
      rethrow;
    }
  }

  /// Return the estimated transaction fee per kilobyte for a transaction to be confirmed within a certain number of [blocks].
  ///
  /// Returns a Decimal fee rate
  /// Ex:
  /// 0.00001000
  Future<Decimal> estimateFee({String? requestID, required int blocks}) async {
    try {
      final response = await request(
        requestID: requestID,
        command: 'blockchain.estimatefee',
        args: [
          blocks,
        ],
      );
      return Decimal.parse(response["result"].toString());
    } catch (e) {
      rethrow;
    }
  }

  /// Return the minimum fee a low-priority transaction must pay in order to be accepted to the daemon’s memory pool.
  ///
  /// Returns a Decimal fee rate
  /// Ex:
  /// 0.00001000
  Future<Decimal> relayFee({String? requestID}) async {
    try {
      final response = await request(
        requestID: requestID,
        command: 'blockchain.relayfee',
      );
      return Decimal.parse(response["result"].toString());
    } catch (e) {
      rethrow;
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:stackduo/utilities/logger.dart';

class ElectrumXSubscription with ChangeNotifier {
  dynamic _response;
  dynamic get response => _response;
  set response(dynamic newData) {
    _response = newData;
    notifyListeners();
  }
}

class SocketTask {
  SocketTask({this.completer, this.subscription});

  final Completer<dynamic>? completer;
  final ElectrumXSubscription? subscription;

  bool get isSubscription => subscription != null;
}

class SubscribableElectrumXClient {
  int _currentRequestID = 0;
  bool _isConnected = false;
  List<int> _responseData = [];
  final Map<String, SocketTask> _tasks = {};
  Timer? _aliveTimer;
  Socket? _socket;
  late final bool _useSSL;
  late final Duration _connectionTimeout;
  late final Duration _keepAlive;

  bool get isConnected => _isConnected;
  bool get useSSL => _useSSL;

  void Function(bool)? onConnectionStatusChanged;

  SubscribableElectrumXClient({
    bool useSSL = true,
    this.onConnectionStatusChanged,
    Duration connectionTimeout = const Duration(seconds: 5),
    Duration keepAlive = const Duration(seconds: 10),
  }) {
    _useSSL = useSSL;
    _connectionTimeout = connectionTimeout;
    _keepAlive = keepAlive;
  }

  Future<void> connect({required String host, required int port}) async {
    try {
      await _socket?.close();
    } catch (_) {}

    if (_useSSL) {
      _socket = await SecureSocket.connect(
        host,
        port,
        timeout: _connectionTimeout,
        onBadCertificate: (_) => true,
      );
    } else {
      _socket = await Socket.connect(
        host,
        port,
        timeout: _connectionTimeout,
      );
    }
    _updateConnectionStatus(true);

    _socket!.listen(
      _dataHandler,
      onError: _errorHandler,
      onDone: _doneHandler,
      cancelOnError: true,
    );

    _aliveTimer?.cancel();
    _aliveTimer = Timer.periodic(
      _keepAlive,
      (_) async => _updateConnectionStatus(await ping()),
    );
  }

  Future<void> disconnect() async {
    _aliveTimer?.cancel();
    await _socket?.close();
    onConnectionStatusChanged = null;
  }

  String _buildJsonRequestString({
    required String method,
    required String id,
    required List<dynamic> params,
  }) {
    final paramString = jsonEncode(params);
    return '{"jsonrpc": "2.0", "id": "$id","method": "$method","params": $paramString}\r\n';
  }

  void _updateConnectionStatus(bool connectionStatus) {
    if (_isConnected != connectionStatus && onConnectionStatusChanged != null) {
      onConnectionStatusChanged!(connectionStatus);
    }
    _isConnected = connectionStatus;
  }

  void _dataHandler(List<int> data) {
    _responseData.addAll(data);

    // 0x0A is newline
    // https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-basics.html
    if (data.last == 0x0A) {
      try {
        final response = jsonDecode(String.fromCharCodes(_responseData))
            as Map<String, dynamic>;
        _responseHandler(response);
      } catch (e, s) {
        Logging.instance
            .log("JsonRPC jsonDecode: $e\n$s", level: LogLevel.Error);
        rethrow;
      } finally {
        _responseData = [];
      }
    }
  }

  void _responseHandler(Map<String, dynamic> response) {
    // subscriptions will have a method in the response
    if (response['method'] is String) {
      _subscriptionHandler(response: response);
      return;
    }

    final id = response['id'] as String;
    final result = response['result'];

    _complete(id, result);
  }

  void _subscriptionHandler({
    required Map<String, dynamic> response,
  }) {
    final method = response['method'];
    switch (method) {
      case "blockchain.scripthash.subscribe":
        final params = response["params"] as List<dynamic>;
        final scripthash = params.first as String;
        final taskId = "blockchain.scripthash.subscribe:$scripthash";

        _tasks[taskId]?.subscription?.response = params.last;
        break;
      case "blockchain.headers.subscribe":
        final params = response["params"];
        const taskId = "blockchain.headers.subscribe";

        _tasks[taskId]?.subscription?.response = params.first;
        break;
      default:
        break;
    }
  }

  void _errorHandler(Object error, StackTrace trace) {
    _updateConnectionStatus(false);
    Logging.instance.log(
        "SubscribableElectrumXClient called _errorHandler with: $error\n$trace",
        level: LogLevel.Info);
  }

  void _doneHandler() {
    _updateConnectionStatus(false);
    Logging.instance.log("SubscribableElectrumXClient called _doneHandler",
        level: LogLevel.Info);
  }

  void _complete(String id, dynamic data) {
    if (_tasks[id] == null) {
      return;
    }

    if (!(_tasks[id]?.completer?.isCompleted ?? false)) {
      _tasks[id]?.completer?.complete(data);
    }

    if (!(_tasks[id]?.isSubscription ?? false)) {
      _tasks.remove(id);
    } else {
      _tasks[id]?.subscription?.response = data;
    }
  }

  void _addTask({
    required String id,
    required Completer<dynamic> completer,
  }) {
    _tasks[id] = SocketTask(completer: completer, subscription: null);
  }

  void _addSubscriptionTask({
    required String id,
    required ElectrumXSubscription subscription,
  }) {
    _tasks[id] = SocketTask(completer: null, subscription: subscription);
  }

  Future<dynamic> _call({
    required String method,
    List<dynamic> params = const [],
  }) async {
    final completer = Completer<dynamic>();
    _currentRequestID++;
    final id = _currentRequestID.toString();
    _addTask(id: id, completer: completer);

    _socket?.write(
      _buildJsonRequestString(
        method: method,
        id: id,
        params: params,
      ),
    );

    return completer.future;
  }

  Future<dynamic> _callWithTimeout({
    required String method,
    List<dynamic> params = const [],
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final completer = Completer<dynamic>();
    _currentRequestID++;
    final id = _currentRequestID.toString();
    _addTask(id: id, completer: completer);

    _socket?.write(
      _buildJsonRequestString(
        method: method,
        id: id,
        params: params,
      ),
    );

    Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.completeError(
          Exception("Request \"id: $id, method: $method\" timed out!"),
        );
      }
    });

    return completer.future;
  }

  ElectrumXSubscription _subscribe({
    required String taskId,
    required String method,
    List<dynamic> params = const [],
  }) {
    // try {
    final subscription = ElectrumXSubscription();
    _addSubscriptionTask(id: taskId, subscription: subscription);
    _currentRequestID++;
    _socket?.write(
      _buildJsonRequestString(
        method: method,
        id: taskId,
        params: params,
      ),
    );

    return subscription;
    // } catch (e, s) {
    //   Logging.instance.log("SubscribableElectrumXClient _subscribe: $e\n$s", level: LogLevel.Error);
    //   return null;
    // }
  }

  /// Ping the server to ensure it is responding
  ///
  /// Returns true if ping succeeded
  Future<bool> ping() async {
    try {
      final response = (await _callWithTimeout(method: "server.ping")) as Map;
      return response.keys.contains("result") && response["result"] == null;
    } catch (_) {
      return false;
    }
  }

  /// Subscribe to a scripthash to receive notifications on status changes
  ElectrumXSubscription subscribeToScripthash({required String scripthash}) {
    return _subscribe(
      taskId: 'blockchain.scripthash.subscribe:$scripthash',
      method: 'blockchain.scripthash.subscribe',
      params: [scripthash],
    );
  }

  /// Subscribe to block headers to receive notifications on new blocks found
  ///
  /// Returns the existing subscription if found
  ElectrumXSubscription subscribeToBlockHeaders() {
    return _tasks["blockchain.headers.subscribe"]?.subscription ??
        _subscribe(
          taskId: "blockchain.headers.subscribe",
          method: "blockchain.headers.subscribe",
          params: [],
        );
  }
}

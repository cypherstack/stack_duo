import 'dart:convert';

import 'package:isar/isar.dart';

part 'input.g.dart';

@embedded
class Input {
  Input({
    this.txid = "error",
    this.vout = -1,
    this.scriptSig,
    this.scriptSigAsm,
    this.witness,
    this.isCoinbase,
    this.sequence,
    this.innerRedeemScriptAsm,
  });

  late final String txid;

  late final int vout;

  late final String? scriptSig;

  late final String? scriptSigAsm;

  late final String? witness;

  late final bool? isCoinbase;

  late final int? sequence;

  late final String? innerRedeemScriptAsm;

  String toJsonString() {
    final Map<String, dynamic> result = {
      "txid": txid,
      "vout": vout,
      "scriptSig": scriptSig,
      "scriptSigAsm": scriptSigAsm,
      "witness": witness,
      "isCoinbase": isCoinbase,
      "sequence": sequence,
      "innerRedeemScriptAsm": innerRedeemScriptAsm,
    };
    return jsonEncode(result);
  }

  static Input fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString);
    return Input(
      txid: json["txid"] as String,
      vout: json["vout"] as int,
      scriptSig: json["scriptSig"] as String?,
      scriptSigAsm: json["scriptSigAsm"] as String?,
      witness: json["witness"] as String?,
      isCoinbase: json["isCoinbase"] as bool?,
      sequence: json["sequence"] as int?,
      innerRedeemScriptAsm: json["innerRedeemScriptAsm"] as String?,
    );
  }
}

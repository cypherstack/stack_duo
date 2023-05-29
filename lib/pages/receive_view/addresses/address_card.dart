import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:isar/isar.dart';
import 'package:stackduo/db/isar/main_db.dart';
import 'package:stackduo/models/isar/models/isar_models.dart';
import 'package:stackduo/pages/receive_view/addresses/address_tag.dart';
import 'package:stackduo/themes/coin_icon_provider.dart';
import 'package:stackduo/utilities/clipboard_interface.dart';
import 'package:stackduo/utilities/enums/coin_enum.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/utilities/util.dart';
import 'package:stackduo/widgets/conditional_parent.dart';
import 'package:stackduo/widgets/rounded_white_container.dart';

class AddressCard extends ConsumerStatefulWidget {
  const AddressCard({
    Key? key,
    required this.addressId,
    required this.walletId,
    required this.coin,
    this.onPressed,
    this.clipboard = const ClipboardWrapper(),
  }) : super(key: key);

  final int addressId;
  final String walletId;
  final Coin coin;
  final ClipboardInterface clipboard;
  final VoidCallback? onPressed;

  @override
  ConsumerState<AddressCard> createState() => _AddressCardState();
}

class _AddressCardState extends ConsumerState<AddressCard> {
  final isDesktop = Util.isDesktop;

  late Stream<AddressLabel?> stream;
  late final Address address;

  AddressLabel? label;

  @override
  void initState() {
    address = MainDB.instance.isar.addresses
        .where()
        .idEqualTo(widget.addressId)
        .findFirstSync()!;

    label = MainDB.instance.getAddressLabelSync(widget.walletId, address.value);
    Id? id = label?.id;
    if (id == null) {
      label = AddressLabel(
        walletId: widget.walletId,
        addressString: address.value,
        value: "",
        tags: address.subType == AddressSubType.receiving
            ? ["receiving"]
            : address.subType == AddressSubType.change
                ? ["change"]
                : null,
      );
      id = MainDB.instance.putAddressLabelSync(label!);
    }
    stream = MainDB.instance.watchAddressLabel(id: id);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RoundedWhiteContainer(
      onPressed: widget.onPressed,
      child: StreamBuilder<AddressLabel?>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            label = snapshot.data!;
          }

          return ConditionalParent(
            condition: isDesktop,
            builder: (child) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.file(
                  File(
                    ref.watch(
                      coinIconProvider(widget.coin),
                    ),
                  ),
                  width: 32,
                  height: 32,
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: child,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label!.value.isNotEmpty)
                  Text(
                    label!.value,
                    style: STextStyles.itemSubtitle(context),
                    textAlign: TextAlign.left,
                  ),
                if (label!.value.isNotEmpty)
                  SizedBox(
                    height: isDesktop ? 2 : 8,
                  ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        address.value,
                        style: STextStyles.itemSubtitle12(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                if (label!.tags != null && label!.tags!.isNotEmpty)
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: label!.tags!
                        .map(
                          (e) => AddressTag(
                            tag: e,
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

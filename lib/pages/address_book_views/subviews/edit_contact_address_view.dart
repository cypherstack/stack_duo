import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackduo/models/contact.dart';
import 'package:stackduo/models/contact_address_entry.dart';
import 'package:stackduo/pages/address_book_views/subviews/new_contact_address_entry_form.dart';
import 'package:stackduo/providers/global/address_book_service_provider.dart';
import 'package:stackduo/providers/ui/address_book_providers/address_entry_data_provider.dart';
import 'package:stackduo/providers/ui/address_book_providers/valid_contact_state_provider.dart';
import 'package:stackduo/themes/stack_colors.dart';
import 'package:stackduo/utilities/assets.dart';
import 'package:stackduo/utilities/barcode_scanner_interface.dart';
import 'package:stackduo/utilities/clipboard_interface.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/utilities/util.dart';
import 'package:stackduo/widgets/background.dart';
import 'package:stackduo/widgets/conditional_parent.dart';
import 'package:stackduo/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackduo/widgets/desktop/primary_button.dart';
import 'package:stackduo/widgets/desktop/secondary_button.dart';

class EditContactAddressView extends ConsumerStatefulWidget {
  const EditContactAddressView({
    Key? key,
    required this.contactId,
    required this.addressEntry,
    this.barcodeScanner = const BarcodeScannerWrapper(),
    this.clipboard = const ClipboardWrapper(),
  }) : super(key: key);

  static const String routeName = "/editContactAddress";

  final String contactId;
  final ContactAddressEntry addressEntry;

  final BarcodeScannerInterface barcodeScanner;
  final ClipboardInterface clipboard;

  @override
  ConsumerState<EditContactAddressView> createState() =>
      _EditContactAddressViewState();
}

class _EditContactAddressViewState
    extends ConsumerState<EditContactAddressView> {
  late final String contactId;
  late final ContactAddressEntry addressEntry;

  late final BarcodeScannerInterface barcodeScanner;
  late final ClipboardInterface clipboard;

  Future<void> save(ContactEntry contact) async {
    if (FocusScope.of(context).hasFocus) {
      FocusScope.of(context).unfocus();
      await Future<void>.delayed(
        const Duration(milliseconds: 75),
      );
    }
    List<ContactAddressEntry> entries = contact.addresses.toList();

    final entry = entries.firstWhere(
      (e) =>
          e.label == addressEntry.label &&
          e.address == addressEntry.address &&
          e.coin == addressEntry.coin,
    );

    final index = entries.indexOf(entry);
    entries.remove(entry);

    ContactAddressEntry editedEntry =
        ref.read(addressEntryDataProvider(0)).buildAddressEntry();

    entries.insert(index, editedEntry);

    ContactEntry editedContact = contact.copyWith(addresses: entries);

    if (await ref.read(addressBookServiceProvider).editContact(editedContact)) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      // TODO show success notification
    } else {
      // TODO show error notification
    }
  }

  @override
  void initState() {
    contactId = widget.contactId;
    addressEntry = widget.addressEntry;
    barcodeScanner = widget.barcodeScanner;
    clipboard = widget.clipboard;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final contact = ref.watch(addressBookServiceProvider
        .select((value) => value.getContactById(contactId)));

    final bool isDesktop = Util.isDesktop;

    return ConditionalParent(
      condition: !isDesktop,
      builder: (child) => Background(
        child: Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          appBar: AppBar(
            leading: AppBarBackButton(
              onPressed: () async {
                if (FocusScope.of(context).hasFocus) {
                  FocusScope.of(context).unfocus();
                  await Future<void>.delayed(const Duration(milliseconds: 75));
                }
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            title: Text(
              "Edit address",
              style: STextStyles.navBarTitle(context),
            ),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: const EdgeInsets.only(
                  left: 12,
                  top: 12,
                  right: 12,
                ),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 24,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: child,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .textFieldActiveBG,
                ),
                child: Center(
                  child: contact.emojiChar == null
                      ? SvgPicture.asset(
                          Assets.svg.user,
                          height: 24,
                          width: 24,
                        )
                      : Text(
                          contact.emojiChar!,
                          style: STextStyles.pageTitleH1(context),
                        ),
                ),
              ),
              const SizedBox(
                width: 16,
              ),
              if (isDesktop)
                Text(
                  contact.name,
                  style: STextStyles.pageTitleH2(context),
                ),
              if (!isDesktop)
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      contact.name,
                      style: STextStyles.pageTitleH2(context),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(
            height: 16,
          ),
          NewContactAddressEntryForm(
            id: 0,
            barcodeScanner: barcodeScanner,
            clipboard: clipboard,
          ),
          const SizedBox(
            height: 24,
          ),
          ConditionalParent(
            condition: isDesktop,
            builder: (child) => MouseRegion(
              cursor: SystemMouseCursors.click,
              child: child,
            ),
            child: GestureDetector(
              onTap: () async {
                // delete address
                final _addresses = contact.addresses;
                final entry = _addresses.firstWhere(
                  (e) =>
                      e.label == addressEntry.label &&
                      e.address == addressEntry.address &&
                      e.coin == addressEntry.coin,
                );

                _addresses.remove(entry);
                ContactEntry editedContact =
                    contact.copyWith(addresses: _addresses);
                if (await ref
                    .read(addressBookServiceProvider)
                    .editContact(editedContact)) {
                  Navigator.of(context).pop();
                  // TODO show success notification
                } else {
                  // TODO show error notification
                }
              },
              child: Text(
                "Delete address",
                style: STextStyles.link(context),
              ),
            ),
          ),
          const Spacer(),
          const SizedBox(
            height: 16,
          ),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: "Cancel",
                  buttonHeight: isDesktop ? ButtonHeight.l : null,
                  onPressed: () async {
                    if (!isDesktop && FocusScope.of(context).hasFocus) {
                      FocusScope.of(context).unfocus();
                      await Future<void>.delayed(
                          const Duration(milliseconds: 75));
                    }
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
              const SizedBox(
                width: 16,
              ),
              Expanded(
                child: PrimaryButton(
                  label: "Save",
                  enabled: ref.watch(validContactStateProvider([0])),
                  onPressed: () => save(contact),
                  buttonHeight: isDesktop ? ButtonHeight.l : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackduo/models/isar/models/contact_entry.dart';
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

class AddNewContactAddressView extends ConsumerStatefulWidget {
  const AddNewContactAddressView({
    Key? key,
    required this.contactId,
    this.barcodeScanner = const BarcodeScannerWrapper(),
    this.clipboard = const ClipboardWrapper(),
  }) : super(key: key);

  static const String routeName = "/addNewContactAddress";

  final String contactId;

  final BarcodeScannerInterface barcodeScanner;
  final ClipboardInterface clipboard;

  @override
  ConsumerState<AddNewContactAddressView> createState() =>
      _AddNewContactAddressViewState();
}

class _AddNewContactAddressViewState
    extends ConsumerState<AddNewContactAddressView> {
  late final String contactId;

  late final BarcodeScannerInterface barcodeScanner;
  late final ClipboardInterface clipboard;

  @override
  void initState() {
    contactId = widget.contactId;
    barcodeScanner = widget.barcodeScanner;
    clipboard = widget.clipboard;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final contact = ref.watch(addressBookServiceProvider
        .select((value) => value.getContactById(contactId)));

    final isDesktop = Util.isDesktop;

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
              "Add new address",
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
            height: 16,
          ),
          const Spacer(),
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
                  buttonHeight: isDesktop ? ButtonHeight.l : null,
                  onPressed: () async {
                    if (FocusScope.of(context).hasFocus) {
                      FocusScope.of(context).unfocus();
                      await Future<void>.delayed(
                        const Duration(milliseconds: 75),
                      );
                    }
                    List<ContactAddressEntry> entries = contact.addresses;

                    entries.add(ref
                        .read(addressEntryDataProvider(0))
                        .buildAddressEntry());

                    ContactEntry editedContact =
                        contact.copyWith(addresses: entries);

                    if (await ref
                        .read(addressBookServiceProvider)
                        .editContact(editedContact)) {
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                      // TODO show success notification
                    } else {
                      // TODO show error notification
                    }
                  },
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

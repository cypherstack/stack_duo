import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/isar/models/log.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/providers/global/debug_service_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/enums/log_level_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/rounded_container.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

class DebugInfoDialog extends ConsumerStatefulWidget {
  const DebugInfoDialog({Key? key}) : super(key: key);

  @override
  ConsumerState<DebugInfoDialog> createState() => _DebugInfoDialog();
}

class _DebugInfoDialog extends ConsumerState<DebugInfoDialog> {
  late final TextEditingController searchDebugController;
  late final FocusNode searchDebugFocusNode;

  final scrollController = ScrollController();

  String _searchTerm = "";

  List<Log> filtered(List<Log> unfiltered, String filter) {
    if (filter == "") {
      return unfiltered;
    }
    return unfiltered
        .where(
            (e) => (e.toString().toLowerCase().contains(filter.toLowerCase())))
        .toList();
  }

  BorderRadius? _borderRadius(int index, int listLength) {
    if (index == 0 && listLength == 1) {
      return BorderRadius.circular(
        Constants.size.circularBorderRadius,
      );
    } else if (index == 0) {
      return BorderRadius.vertical(
        bottom: Radius.circular(
          Constants.size.circularBorderRadius,
        ),
      );
    } else if (index == listLength - 1) {
      return BorderRadius.vertical(
        top: Radius.circular(
          Constants.size.circularBorderRadius,
        ),
      );
    }
    return null;
  }

  @override
  void initState() {
    searchDebugController = TextEditingController();
    searchDebugFocusNode = FocusNode();

    ref.read(debugServiceProvider).updateRecentLogs();
    super.initState();
  }

  @override
  void dispose() {
    searchDebugFocusNode.dispose();
    searchDebugController.dispose();

    scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopDialog(
      maxHeight: 850,
      maxWidth: 600,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  "Debug info",
                  style: STextStyles.desktopH3(context),
                  textAlign: TextAlign.center,
                ),
              ),
              const DesktopDialogCloseButton(),
            ],
          ),
          Expanded(
            // flex: 24,
            child: NestedScrollView(
              floatHeaderSlivers: true,
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverOverlapAbsorber(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context),
                    sliver: SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 32),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  Constants.size.circularBorderRadius,
                                ),
                                child: TextField(
                                  autocorrect: Util.isDesktop ? false : true,
                                  enableSuggestions:
                                      Util.isDesktop ? false : true,
                                  controller: searchDebugController,
                                  focusNode: searchDebugFocusNode,
                                  onChanged: (newString) {
                                    setState(() => _searchTerm = newString);
                                  },
                                  style: STextStyles.field(context),
                                  decoration: standardInputDecoration(
                                    "Search",
                                    searchDebugFocusNode,
                                    context,
                                  ).copyWith(
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 16,
                                      ),
                                      child: SvgPicture.asset(
                                        Assets.svg.search,
                                        width: 16,
                                        height: 16,
                                      ),
                                    ),
                                    suffixIcon: searchDebugController
                                            .text.isNotEmpty
                                        ? Padding(
                                            padding:
                                                const EdgeInsets.only(right: 0),
                                            child: UnconstrainedBox(
                                              child: Row(
                                                children: [
                                                  TextFieldIconButton(
                                                    child: const XIcon(),
                                                    onTap: () async {
                                                      setState(() {
                                                        searchDebugController
                                                            .text = "";
                                                        _searchTerm = "";
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: Builder(
                builder: (context) {
                  final logs = filtered(
                          ref.watch(debugServiceProvider
                              .select((value) => value.recentLogs)),
                          _searchTerm)
                      .reversed
                      .toList(growable: false);
                  return CustomScrollView(
                    reverse: true,
                    // shrinkWrap: true,
                    controller: scrollController,
                    slivers: [
                      SliverOverlapInjector(
                        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                          context,
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final log = logs[index];

                            return Container(
                              key: Key(
                                  "log_${log.id}_${log.timestampInMillisUTC}"),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .popupBG,
                                borderRadius: _borderRadius(index, logs.length),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32),
                                  child: RoundedContainer(
                                    padding: const EdgeInsets.all(0),
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .popupBG,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              " [${log.logLevel.name}]",
                                              style: STextStyles.baseXS(context)
                                                  .copyWith(
                                                fontSize: 8,
                                                color: (log.logLevel ==
                                                        LogLevel.Info
                                                    ? Theme.of(context)
                                                        .extension<
                                                            StackColors>()!
                                                        .topNavIconGreen
                                                    : (log.logLevel ==
                                                            LogLevel.Warning
                                                        ? Theme.of(context)
                                                            .extension<
                                                                StackColors>()!
                                                            .topNavIconYellow
                                                        : (log.logLevel ==
                                                                LogLevel.Error
                                                            ? Colors.orange
                                                            : Theme.of(context)
                                                                .extension<
                                                                    StackColors>()!
                                                                .topNavIconRed))),
                                              ),
                                            ),
                                            Text(
                                              "[${DateTime.fromMillisecondsSinceEpoch(log.timestampInMillisUTC, isUtc: true)}]: ",
                                              style: STextStyles.baseXS(context)
                                                  .copyWith(
                                                fontSize: 12,
                                                color: Theme.of(context)
                                                    .extension<StackColors>()!
                                                    .textDark3,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(
                                              width: 20,
                                            ),
                                            Flexible(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  SelectableText(
                                                    log.message,
                                                    style: STextStyles.baseXS(
                                                            context)
                                                        .copyWith(
                                                            fontSize: 11.5),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: logs.length,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          // const Spacer(),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: "Clear logs",
                    onPressed: () async {
                      await ref.read(debugServiceProvider).deleteAllMessages();
                      await ref.read(debugServiceProvider).updateRecentLogs();

                      if (mounted) {
                        Navigator.pop(context);
                        unawaited(showFloatingFlushBar(
                            type: FlushBarType.info,
                            context: context,
                            message: 'Logs cleared!'));
                      }
                    },
                  ),
                ),
                const SizedBox(
                  width: 16,
                ),
                Expanded(
                  child: PrimaryButton(
                    label: "Save logs to file",
                    onPressed: () {},
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

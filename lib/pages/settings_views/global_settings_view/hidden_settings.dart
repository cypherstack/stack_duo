import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackduo/notifications/show_flush_bar.dart';
import 'package:stackduo/providers/global/debug_service_provider.dart';
import 'package:stackduo/providers/providers.dart';
import 'package:stackduo/services/exchange/majestic_bank/majestic_bank_api.dart';
import 'package:stackduo/utilities/constants.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';
import 'package:stackduo/widgets/background.dart';
import 'package:stackduo/widgets/rounded_white_container.dart';

class HiddenSettings extends StatelessWidget {
  const HiddenSettings({Key? key}) : super(key: key);

  static const String routeName = "/hiddenSettings";

  @override
  Widget build(BuildContext context) {
    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: Container(),
          title: Text(
            "Not so secret anymore",
            style: STextStyles.navBarTitle(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Consumer(builder: (_, ref, __) {
                          return GestureDetector(
                            onTap: () async {
                              final notifs =
                                  ref.read(notificationsProvider).notifications;

                              for (final n in notifs) {
                                await ref
                                    .read(notificationsProvider)
                                    .delete(n, false);
                              }
                              await ref
                                  .read(notificationsProvider)
                                  .delete(notifs[0], true);

                              if (context.mounted) {
                                unawaited(
                                  showFloatingFlushBar(
                                    type: FlushBarType.success,
                                    message: "Notification history deleted",
                                    context: context,
                                  ),
                                );
                              }
                            },
                            child: RoundedWhiteContainer(
                              child: Text(
                                "Delete notifications",
                                style: STextStyles.button(context).copyWith(
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .accentColorDark),
                              ),
                            ),
                          );
                        }),
                        // const SizedBox(
                        //   height: 12,
                        // ),
                        // Consumer(builder: (_, ref, __) {
                        //   return GestureDetector(
                        //     onTap: () async {
                        //       final trades =
                        //           ref.read(tradesServiceProvider).trades;
                        //
                        //       for (final trade in trades) {
                        //         ref.read(tradesServiceProvider).delete(
                        //             trade: trade, shouldNotifyListeners: false);
                        //       }
                        //       ref.read(tradesServiceProvider).delete(
                        //           trade: trades[0], shouldNotifyListeners: true);
                        //
                        //       // ref.read(notificationsProvider).DELETE_EVERYTHING();
                        //     },
                        //     child: RoundedWhiteContainer(
                        //       child: Text(
                        //         "Delete trade history",
                        //         style: STextStyles.button(context).copyWith(
                        //           color: Theme.of(context).extension<StackColors>()!.accentColorDark
                        //         ),
                        //       ),
                        //     ),
                        //   );
                        // }),
                        const SizedBox(
                          height: 12,
                        ),
                        Consumer(builder: (_, ref, __) {
                          return GestureDetector(
                            onTap: () async {
                              await ref
                                  .read(debugServiceProvider)
                                  .deleteAllLogs();

                              if (context.mounted) {
                                unawaited(
                                  showFloatingFlushBar(
                                    type: FlushBarType.success,
                                    message: "Debug Logs deleted",
                                    context: context,
                                  ),
                                );
                              }
                            },
                            child: RoundedWhiteContainer(
                              child: Text(
                                "Delete Debug Logs",
                                style: STextStyles.button(context).copyWith(
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .accentColorDark),
                              ),
                            ),
                          );
                        }),
                        // const SizedBox(
                        //   height: 12,
                        // ),
                        // Consumer(builder: (_, ref, __) {
                        //   return GestureDetector(
                        //     onTap: () async {
                        //       final x =
                        //           await MajesticBankAPI.instance.getRates();
                        //       print(x);
                        //     },
                        //     child: RoundedWhiteContainer(
                        //       child: Text(
                        //         "Click me",
                        //         style: STextStyles.button(context).copyWith(
                        //             color: Theme.of(context)
                        //                 .extension<StackColors>()!
                        //                 .accentColorDark),
                        //       ),
                        //     ),
                        //   );
                        // }),
                        const SizedBox(
                          height: 12,
                        ),
                        Consumer(builder: (_, ref, __) {
                          return GestureDetector(
                            onTap: () async {
                              final x = await MajesticBankAPI.instance
                                  .getLimit(fromCurrency: 'btc');
                              print(x);
                            },
                            child: RoundedWhiteContainer(
                              child: Text(
                                "Click me",
                                style: STextStyles.button(context).copyWith(
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .accentColorDark),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(
                          height: 12,
                        ),
                        Consumer(
                          builder: (_, ref, __) {
                            if (ref.watch(prefsChangeNotifierProvider
                                    .select((value) => value.familiarity)) <
                                6) {
                              return GestureDetector(
                                onTap: () async {
                                  final familiarity = ref
                                      .read(prefsChangeNotifierProvider)
                                      .familiarity;
                                  if (familiarity < 6) {
                                    ref
                                        .read(prefsChangeNotifierProvider)
                                        .familiarity = 6;

                                    Constants.exchangeForExperiencedUsers(6);
                                  }
                                },
                                child: RoundedWhiteContainer(
                                  child: Text(
                                    "Enable exchange",
                                    style: STextStyles.button(context).copyWith(
                                        color: Theme.of(context)
                                            .extension<StackColors>()!
                                            .accentColorDark),
                                  ),
                                ),
                              );
                            } else {
                              return Container();
                            }
                          },
                        ),
                        // const SizedBox(
                        //   height: 12,
                        // ),
                        // GestureDetector(
                        //   onTap: () async {
                        //     showDialog<void>(
                        //       context: context,
                        //       builder: (_) {
                        //         return StackDialogBase(
                        //           child: SizedBox(
                        //             width: 300,
                        //             child: Lottie.asset(
                        //               Assets.lottie.plain(Coin.bitcoincash),
                        //             ),
                        //           ),
                        //         );
                        //       },
                        //     );
                        //   },
                        //   child: RoundedWhiteContainer(
                        //     child: Text(
                        //       "Lottie test",
                        //       style: STextStyles.button(context).copyWith(
                        //           color: Theme.of(context)
                        //               .extension<StackColors>()!
                        //               .accentColorDark),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

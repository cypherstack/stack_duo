import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages_desktop_specific/home/address_book_view/desktop_address_book.dart';
import 'package:stackwallet/pages_desktop_specific/home/desktop_menu.dart';
import 'package:stackwallet/pages_desktop_specific/home/desktop_settings_view.dart';
import 'package:stackwallet/pages_desktop_specific/home/my_stack_view/my_stack_view.dart';
import 'package:stackwallet/pages_desktop_specific/home/notifications/desktop_notifications_view.dart';
import 'package:stackwallet/pages_desktop_specific/home/support_and_about_view/desktop_about_view.dart';
import 'package:stackwallet/pages_desktop_specific/home/support_and_about_view/desktop_support_view.dart';
import 'package:stackwallet/providers/desktop/current_desktop_menu_item.dart';
import 'package:stackwallet/providers/global/notifications_provider.dart';
import 'package:stackwallet/providers/ui/unread_notifications_provider.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';

class DesktopHomeView extends ConsumerStatefulWidget {
  const DesktopHomeView({Key? key}) : super(key: key);

  static const String routeName = "/desktopHome";

  @override
  ConsumerState<DesktopHomeView> createState() => _DesktopHomeViewState();
}

class _DesktopHomeViewState extends ConsumerState<DesktopHomeView> {
  final Map<DesktopMenuItemId, Widget> contentViews = {
    DesktopMenuItemId.myStack: const Navigator(
      key: Key("desktopStackHomeKey"),
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: MyStackView.routeName,
    ),
    // Container(
    //   // todo: exchange
    //   color: Colors.green,
    // ),
    DesktopMenuItemId.notifications: const Navigator(
      key: Key("desktopNotificationsHomeKey"),
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: DesktopNotificationsView.routeName,
    ),
    DesktopMenuItemId.addressBook: const Navigator(
      key: Key("desktopAddressBookHomeKey"),
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: DesktopAddressBook.routeName,
    ),
    DesktopMenuItemId.settings: const Navigator(
      key: Key("desktopSettingHomeKey"),
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: DesktopSettingsView.routeName,
    ),
    DesktopMenuItemId.support: const Navigator(
      key: Key("desktopSupportHomeKey"),
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: DesktopSupportView.routeName,
    ),
    DesktopMenuItemId.about: const Navigator(
      key: Key("desktopAboutHomeKey"),
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: DesktopAboutView.routeName,
    ),
  };

  void onMenuSelectionWillChange(DesktopMenuItemId newKey) {
    // check for unread notifications and refresh provider before
    // showing notifications view
    if (newKey == DesktopMenuItemId.notifications) {
      ref.refresh(unreadNotificationsStateProvider);
    }
    // mark notifications as read if leaving notifications view
    if (ref.read(currentDesktopMenuItemProvider.state).state ==
            DesktopMenuItemId.notifications &&
        newKey != DesktopMenuItemId.notifications) {
      final Set<int> unreadNotificationIds =
          ref.read(unreadNotificationsStateProvider.state).state;

      if (unreadNotificationIds.isNotEmpty) {
        List<Future<void>> futures = [];
        for (int i = 0; i < unreadNotificationIds.length - 1; i++) {
          futures.add(ref
              .read(notificationsProvider)
              .markAsRead(unreadNotificationIds.elementAt(i), false));
        }

        // wait for multiple to update if any
        Future.wait(futures).then((_) {
          // only notify listeners once
          ref
              .read(notificationsProvider)
              .markAsRead(unreadNotificationIds.last, true);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).extension<StackColors>()!.background,
      child: Row(
        children: [
          DesktopMenu(
            // onSelectionChanged: onMenuSelectionChanged,
            onSelectionWillChange: onMenuSelectionWillChange,
          ),
          Container(
            width: 1,
            color: Theme.of(context).extension<StackColors>()!.background,
          ),
          Expanded(
            child: contentViews[
                ref.watch(currentDesktopMenuItemProvider.state).state]!,
          ),
        ],
      ),
    );
  }
}

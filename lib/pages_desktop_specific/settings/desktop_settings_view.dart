import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackduo/pages_desktop_specific/settings/settings_menu.dart';
import 'package:stackduo/pages_desktop_specific/settings/settings_menu/advanced_settings/advanced_settings.dart';
import 'package:stackduo/pages_desktop_specific/settings/settings_menu/appearance_settings/appearance_settings.dart';
import 'package:stackduo/pages_desktop_specific/settings/settings_menu/backup_and_restore/backup_and_restore_settings.dart';
import 'package:stackduo/pages_desktop_specific/settings/settings_menu/currency_settings/currency_settings.dart';
import 'package:stackduo/pages_desktop_specific/settings/settings_menu/language_settings/language_settings.dart';
import 'package:stackduo/pages_desktop_specific/settings/settings_menu/nodes_settings.dart';
import 'package:stackduo/pages_desktop_specific/settings/settings_menu/security_settings.dart';
import 'package:stackduo/pages_desktop_specific/settings/settings_menu/syncing_preferences_settings.dart';
import 'package:stackduo/route_generator.dart';
import 'package:stackduo/themes/stack_colors.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/widgets/desktop/desktop_app_bar.dart';
import 'package:stackduo/widgets/desktop/desktop_scaffold.dart';

class DesktopSettingsView extends ConsumerStatefulWidget {
  const DesktopSettingsView({Key? key}) : super(key: key);

  static const String routeName = "/desktopSettings";

  @override
  ConsumerState<DesktopSettingsView> createState() =>
      _DesktopSettingsViewState();
}

class _DesktopSettingsViewState extends ConsumerState<DesktopSettingsView> {
  final List<Widget> contentViews = [
    const Navigator(
      key: Key("settingsBackupRestoreDesktopKey"),
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: BackupRestoreSettings.routeName,
    ), //b+r
    const Navigator(
      key: Key("settingsSecurityDesktopKey"),
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: SecuritySettings.routeName,
    ), //security
    const Navigator(
      key: Key("settingsCurrencyDesktopKey"),
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: CurrencySettings.routeName,
    ), //currency
    const Navigator(
      key: Key("settingsLanguageDesktopKey"),
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: LanguageOptionSettings.routeName,
    ), //language
    const Navigator(
      key: Key("settingsNodesDesktopKey"),
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: NodesSettings.routeName,
    ), //nodes
    const Navigator(
      key: Key("settingsSyncingPreferencesDesktopKey"),
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: SyncingPreferencesSettings.routeName,
    ), //syncing prefs
    const Navigator(
      key: Key("settingsAppearanceDesktopKey"),
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: AppearanceOptionSettings.routeName,
    ), //appearance
    const Navigator(
      key: Key("settingsAdvancedDesktopKey"),
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: AdvancedSettings.routeName,
    ), //advanced
  ];

  @override
  Widget build(BuildContext context) {
    return DesktopScaffold(
      background: Theme.of(context).extension<StackColors>()!.background,
      appBar: const DesktopAppBar(
        isCompactHeight: true,
        leading: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
            ),
            DesktopSettingsTitle(),
          ],
        ),
      ),
      body: Row(
        children: [
          const Padding(
            padding: EdgeInsets.all(15.0),
            child: SettingsMenu(),
          ),
          Expanded(
            child: contentViews[
                ref.watch(selectedSettingsMenuItemStateProvider.state).state],
          ),
        ],
      ),
    );
  }
}

class DesktopSettingsTitle extends StatelessWidget {
  const DesktopSettingsTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      "Settings",
      style: STextStyles.desktopH3(context),
    );
  }
}

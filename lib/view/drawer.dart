import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/link.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
            child: Text(
              AppLocalizations.of(context)!.appName,
              style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
            ),
          ),
          Link(
            uri: Uri.parse("https://notes.yh1224.com/stackchan-connect/"),
            target: LinkTarget.blank,
            builder: (BuildContext ctx, FollowLink? openLink) {
              return ListTile(
                title: Text(AppLocalizations.of(context)!.aboutThisApp),
                onTap: openLink,
              );
            },
          ),
          Link(
            uri: Uri.parse("https://notes.yh1224.com/privacy/"),
            target: LinkTarget.blank,
            builder: (BuildContext ctx, FollowLink? openLink) {
              return ListTile(
                title: Text(AppLocalizations.of(context)!.privacyPolicy),
                onTap: openLink,
              );
            },
          ),
        ],
      ),
    );
  }
}

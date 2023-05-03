import 'package:flutter/material.dart';
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
              "ｽﾀｯｸﾁｬﾝ ｺﾝﾈｸﾄ",
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
                title: const Text("アプリについて／使い方"),
                onTap: openLink,
              );
            },
          ),
          Link(
            uri: Uri.parse("https://notes.yh1224.com/privacy/"),
            target: LinkTarget.blank,
            builder: (BuildContext ctx, FollowLink? openLink) {
              return ListTile(
                title: const Text("プライバシーポリシー"),
                onTap: openLink,
              );
            },
          ),
        ],
      ),
    );
  }
}

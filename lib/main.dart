import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/link.dart';

import 'settings.dart';
import 'speech.dart';

void main() {
  runApp(const MyApp());
}

class MyAppState extends ChangeNotifier {}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ｽﾀｯｸﾁｬﾝ ｺﾝﾈｸﾄ',
        home: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ｽﾀｯｸﾁｬﾝ ｺﾝﾈｸﾄ'),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
              child: Text(
                "ｽﾀｯｸﾁｬﾝ ｺﾝﾈｸﾄ",
                style: TextStyle(
                  fontSize: 24,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
            Link(
              uri: Uri.parse('https://notes.yh1224.com/stackchan-connect/'),
              target: LinkTarget.blank,
              builder: (BuildContext ctx, FollowLink? openLink) {
                return ListTile(
                  title: const Text("アプリについて／使い方"),
                  onTap: openLink,
                );
              },
            ),
            Link(
              uri: Uri.parse('https://notes.yh1224.com/privacy/'),
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
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              title: const Text("おしゃべり", style: TextStyle(fontSize: 32)),
              subtitle: const Text("ｽﾀｯｸﾁｬﾝ とお話します。", style: TextStyle(fontSize: 20)),
              leading: const Icon(Icons.speaker_notes, size: 32),
              onTap: () => {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                  return const SpeechPage();
                }))
              },
            ),
            ListTile(
              title: const Text("設定", style: TextStyle(fontSize: 32)),
              subtitle: const Text("ｽﾀｯｸﾁｬﾝ を接続・設定します。", style: TextStyle(fontSize: 20)),
              leading: const Icon(Icons.settings, size: 32),
              onTap: () => {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                  return const SettingsPage();
                }))
              },
            ),
          ],
        ),
      ),
    );
  }
}

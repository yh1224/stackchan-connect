import 'package:flutter/foundation.dart';
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
      child: MaterialApp(
        debugShowCheckedModeBanner: kDebugMode,
        title: "ｽﾀｯｸﾁｬﾝ ｺﾝﾈｸﾄ",
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.teal,
        ),
        home: const MyHomePage(),
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
        title: const Text("ｽﾀｯｸﾁｬﾝ ｺﾝﾈｸﾄ"),
      ),
      drawer: Drawer(
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
      ),
      body: GestureDetector(
        child: Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Card(
                    child: ListTile(
                      title: Text("おしゃべり", style: Theme.of(context).textTheme.titleLarge),
                      subtitle: Text("ｽﾀｯｸﾁｬﾝ とお話します。", style: Theme.of(context).textTheme.titleMedium),
                      leading: const Icon(Icons.speaker_notes, size: 48),
                      onTap: () => {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                          return const SpeechPage();
                        }))
                      },
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: Text("設定", style: Theme.of(context).textTheme.titleLarge),
                      subtitle: Text("ｽﾀｯｸﾁｬﾝ を接続・設定します。", style: Theme.of(context).textTheme.titleMedium),
                      leading: const Icon(Icons.settings, size: 48),
                      onTap: () => {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                          return const SettingsPage();
                        }))
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

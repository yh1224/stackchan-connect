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
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueAccent),
              child: Text(
                "ｽﾀｯｸﾁｬﾝ ｺﾝﾈｸﾄ",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ),
            // ListTile(
            //   title: const Text("設定"),
            //   onTap: () {
            //     Navigator.of(context).push(MaterialPageRoute(builder: (context) {
            //       return const SettingsPage();
            //     }));
            //   },
            // ),
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
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Center(
                child: TextButton(
                  onPressed: () => {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                      return const SpeechPage("ｽﾀｯｸﾁｬﾝ にしゃべってもらいたいことを入力してね", "/speech", "say");
                    }))
                  },
                  child: const Text("しゃべって", style: TextStyle(fontSize: 40)),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                      return const SpeechPage("ｽﾀｯｸﾁｬﾝ に聞きたいことを入力してね", "/chat", "text");
                    }))
                  },
                  child: const Text("おはなし", style: TextStyle(fontSize: 40)),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                      return const SettingsPage();
                    }))
                  },
                  child: const Text("設定", style: TextStyle(fontSize: 40)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

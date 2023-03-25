import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

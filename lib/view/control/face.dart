import 'package:flutter/material.dart';

import '../../infrastructure/stackchan.dart';

class FacePage extends StatefulWidget {
  const FacePage(this.stackchanIpAddress, {super.key});

  final String stackchanIpAddress;

  @override
  State<FacePage> createState() => _FacePageState();
}

class _FacePageState extends State<FacePage> {
  /// 初期化完了
  bool initialized = false;

  /// 設定更新中
  bool updating = false;

  /// ステータスメッセージ
  String statusMessage = "";

  @override
  void initState() {
    super.initState();
    checkStackchan();
  }

  // check existence of apikey setting page
  void checkStackchan() async {
    final stackchanIpAddress = widget.stackchanIpAddress;
    if (stackchanIpAddress.isEmpty) {
      setState(() {
        statusMessage = "IP アドレスを設定してください。";
      });
      return;
    }

    setState(() {
      updating = true;
      statusMessage = "";
    });
    try {
      if (await Stackchan(stackchanIpAddress).hasFaceApi()) {
        setState(() {
          initialized = true;
        });
      } else {
        setState(() {
          statusMessage = "設定できません。";
        });
      }
    } finally {
      setState(() {
        updating = false;
      });
    }
  }

  void updateFace(int value) async {
    setState(() {
      updating = true;
      statusMessage = "";
    });
    try {
      await Stackchan(widget.stackchanIpAddress).face("$value");
    } catch (e) {
      setState(() {
        statusMessage = "Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        updating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ｽﾀｯｸﾁｬﾝ ｺﾝﾈｸﾄ"),
      ),
      body: GestureDetector(
        child: Column(
          children: [
            Expanded(
              child: Visibility(
                visible: initialized,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Card(
                          child: ListTile(
                            title: Text("😐 おすまし", style: Theme.of(context).textTheme.titleLarge),
                            // subtitle: Text("Neutral Face", style: Theme.of(context).textTheme.titleMedium),
                            onTap: () {
                              updateFace(0);
                            },
                          ),
                        ),
                        Card(
                          child: ListTile(
                            title: Text("😘 たのしい", style: Theme.of(context).textTheme.titleLarge),
                            // subtitle: Text("Happy Face", style: Theme.of(context).textTheme.titleMedium),
                            onTap: () {
                              updateFace(1);
                            },
                          ),
                        ),
                        Card(
                          child: ListTile(
                            title: Text("😪 ねむい", style: Theme.of(context).textTheme.titleLarge),
                            // subtitle: Text("Sleepy Face", style: Theme.of(context).textTheme.titleMedium),
                            onTap: () {
                              updateFace(2);
                            },
                          ),
                        ),
                        Card(
                          child: ListTile(
                            title: Text("😥 あやしい", style: Theme.of(context).textTheme.titleLarge),
                            // subtitle: Text("Doubt Face", style: Theme.of(context).textTheme.titleMedium),
                            onTap: () {
                              updateFace(3);
                            },
                          ),
                        ),
                        Card(
                          child: ListTile(
                            title: Text("😢 かなしい", style: Theme.of(context).textTheme.titleLarge),
                            // subtitle: Text("Sad Face", style: Theme.of(context).textTheme.titleMedium),
                            onTap: () {
                              updateFace(4);
                            },
                          ),
                        ),
                        Card(
                          child: ListTile(
                            title: Text("😠 おこ", style: Theme.of(context).textTheme.titleLarge),
                            // subtitle: Text("Angry Face", style: Theme.of(context).textTheme.titleMedium),
                            onTap: () {
                              updateFace(5);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8.0),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Visibility(
                    visible: statusMessage.isNotEmpty,
                    child: Text(
                      statusMessage,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Visibility(
                    visible: updating,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: LinearProgressIndicator(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

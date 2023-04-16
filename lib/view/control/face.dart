import 'package:flutter/material.dart';

import '../../infrastructure/stackchan.dart';

class FacePage extends StatefulWidget {
  final String stackchanIpAddress;

  const FacePage(this.stackchanIpAddress, {super.key});

  @override
  State<FacePage> createState() => _FacePageState();
}

class _FacePageState extends State<FacePage> {
  /// 初期化完了
  bool _initialized = false;

  /// 設定更新中
  bool _updating = false;

  /// ステータスメッセージ
  String _statusMessage = "";

  @override
  void initState() {
    super.initState();
    _checkStackchan();
  }

  // check existence of apikey setting page
  void _checkStackchan() async {
    setState(() {
      _updating = true;
      _statusMessage = "";
    });
    try {
      if (await Stackchan(widget.stackchanIpAddress).hasFaceApi()) {
        setState(() {
          _initialized = true;
        });
      } else {
        setState(() {
          _statusMessage = "設定できません。";
        });
      }
    } finally {
      setState(() {
        _updating = false;
      });
    }
  }

  void _updateFace(int value) async {
    setState(() {
      _updating = true;
      _statusMessage = "";
    });
    try {
      await Stackchan(widget.stackchanIpAddress).face("$value");
    } catch (e) {
      setState(() {
        _statusMessage = "Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        _updating = false;
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
                visible: _initialized,
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
                              _updateFace(0);
                            },
                          ),
                        ),
                        Card(
                          child: ListTile(
                            title: Text("😘 たのしい", style: Theme.of(context).textTheme.titleLarge),
                            // subtitle: Text("Happy Face", style: Theme.of(context).textTheme.titleMedium),
                            onTap: () {
                              _updateFace(1);
                            },
                          ),
                        ),
                        Card(
                          child: ListTile(
                            title: Text("😪 ねむい", style: Theme.of(context).textTheme.titleLarge),
                            // subtitle: Text("Sleepy Face", style: Theme.of(context).textTheme.titleMedium),
                            onTap: () {
                              _updateFace(2);
                            },
                          ),
                        ),
                        Card(
                          child: ListTile(
                            title: Text("😥 あやしい", style: Theme.of(context).textTheme.titleLarge),
                            // subtitle: Text("Doubt Face", style: Theme.of(context).textTheme.titleMedium),
                            onTap: () {
                              _updateFace(3);
                            },
                          ),
                        ),
                        Card(
                          child: ListTile(
                            title: Text("😢 かなしい", style: Theme.of(context).textTheme.titleLarge),
                            // subtitle: Text("Sad Face", style: Theme.of(context).textTheme.titleMedium),
                            onTap: () {
                              _updateFace(4);
                            },
                          ),
                        ),
                        Card(
                          child: ListTile(
                            title: Text("😠 おこ", style: Theme.of(context).textTheme.titleLarge),
                            // subtitle: Text("Angry Face", style: Theme.of(context).textTheme.titleMedium),
                            onTap: () {
                              _updateFace(5);
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
                    visible: _statusMessage.isNotEmpty,
                    child: Text(
                      _statusMessage,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Visibility(
                    visible: _updating,
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

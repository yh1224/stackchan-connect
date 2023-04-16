import 'package:esp_smartconfig/esp_smartconfig.dart';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class SmartConfigPage extends StatefulWidget {
  const SmartConfigPage({super.key});

  @override
  State<SmartConfigPage> createState() => _SmartConfigPageState();
}

class _SmartConfigPageState extends State<SmartConfigPage> {
  /// ステータスメッセージ
  String _statusMessage = "";

  /// SmartConfig Provisioner
  Provisioner? _provisioner;

  /// Provision 実行中
  bool _provisioning = false;

  /// 接続中の SSID
  String? _wifiSsid;

  /// 接続中の BSSID
  String? _wifiBssid;

  /// Wi-Fi パスワード入力
  final _wifiPassphraseTextArea = TextEditingController();
  bool _isWifiPassphraseObscure = true;

  /// IP アドレス取得結果
  String? _resultIpAddress;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    final networkInfo = NetworkInfo();
    final locationStatus = await Permission.location.status;
    if (locationStatus.isDenied) {
      await Permission.locationWhenInUse.request();
    }
    if (!await Permission.location.isGranted) {
      return;
    }
    var ssid = await networkInfo.getWifiName();
    if (ssid != null && ssid.startsWith("\"") && ssid.endsWith("\"")) {
      ssid = ssid.substring(1, ssid.length - 1);
    }
    final bssid = await networkInfo.getWifiBSSID();
    setState(() {
      _wifiSsid = ssid;
      _wifiBssid = bssid;
    });
  }

  @override
  void deactivate() {
    _provisioner?.stop();
    super.deactivate();
  }

  void _startProvision() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _statusMessage = "設定をおこなっています...\n電源を入れてしばらくお待ち下さい。";
      _provisioning = true;
    });
    try {
      _provisioner = Provisioner.espTouch();
      _provisioner!.listen((response) {
        debugPrint("Device ${response.bssidText} connected to WiFi!");
        setState(() {
          _provisioner?.stop();
          _provisioning = false;
        });
        if (response.ipAddressText != null) {
          setState(() {
            _statusMessage = "${response.ipAddressText} が接続されました。";
            _resultIpAddress = response.ipAddressText;
          });
        }
      }, onError: (e) {
        setState(() {
          _statusMessage = "エラー\n${e.toString()}";
        });
      }, onDone: () {
        debugPrint("Done");
      });
      await _provisioner!.start(ProvisioningRequest.fromStrings(
        ssid: _wifiSsid!,
        bssid: _wifiBssid!,
        password: _wifiPassphraseTextArea.text.trim(),
      ));
    } catch (e) {
      setState(() {
        _statusMessage = "処理が開始できませんでした。\n${e.toString()}";
        _provisioning = false;
      });
    }
  }

  void _stopProvision() {
    _provisioner?.stop();
    setState(() {
      _statusMessage = "";
      _provisioning = false;
    });
  }

  void _close() {
    Navigator.of(context).pop(_resultIpAddress);
  }

  bool _isWifiConnected() {
    return _wifiSsid != null && _wifiBssid != null;
  }

  bool _canProvision() {
    return _isWifiConnected() && _wifiPassphraseTextArea.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SmartConfig"),
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "SmartConfig による自動設定に対応した ｽﾀｯｸﾁｬﾝ を Wi-Fi ネットワークに接続します。このスマートフォンが 2.4GHz 帯の Wi-Fi アクセスポイントに接続されている必要があります。",
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 20.0),
                      Visibility(
                        visible: _isWifiConnected(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                  child: Row(
                                    children: [
                                      Text(
                                        "SSID: ",
                                        textAlign: TextAlign.left,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        "$_wifiSsid",
                                        textAlign: TextAlign.left,
                                        style: Theme.of(context).textTheme.bodyLarge,
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                  child: Row(
                                    children: [
                                      Text(
                                        "BSSID: ",
                                        textAlign: TextAlign.left,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        "$_wifiBssid",
                                        textAlign: TextAlign.left,
                                        style: Theme.of(context).textTheme.bodyLarge,
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                  child: TextFormField(
                                    obscureText: _isWifiPassphraseObscure,
                                    readOnly: _provisioning,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                      labelText: "パスフレーズ",
                                      suffixIcon: IconButton(
                                        icon: Icon(_isWifiPassphraseObscure ? Icons.visibility_off : Icons.visibility),
                                        onPressed: () {
                                          setState(() {
                                            _isWifiPassphraseObscure = !_isWifiPassphraseObscure;
                                          });
                                        },
                                      ),
                                    ),
                                    controller: _wifiPassphraseTextArea,
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      const Text(
                        "Wi-Fi アクセスポイントのパスフレーズを入力して、「設定開始」を押してください。",
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Visibility(
              visible: _provisioning,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
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
                    visible: _resultIpAddress == null,
                    child: SizedBox(
                      width: double.infinity,
                      child: ValueListenableBuilder(
                        valueListenable: _wifiPassphraseTextArea,
                        builder: (context, value, child) {
                          return ElevatedButton(
                            onPressed: _canProvision() ? (_provisioning ? _stopProvision : _startProvision) : null,
                            child: Text(
                              _provisioning ? "キャンセル" : "設定開始",
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Visibility(
                    visible: _resultIpAddress != null,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _close,
                        child: Text(
                          "OK",
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

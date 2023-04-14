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
  String statusMessage = "";

  /// SmartConfig Provisioner
  Provisioner? provisioner;

  /// Provision 実行中
  bool provisioning = false;

  /// Provision 完了
  bool provisionComplete = false;

  /// 接続中の SSID
  String? wifiSsid;

  /// 接続中の BSSID
  String? wifiBssid;

  /// Wi-Fi パスワード入力
  final wifiPassphraseTextArea = TextEditingController();
  bool isWifiPassphraseObscure = true;

  /// IP アドレス取得結果
  String? resultIpAddress;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
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
      wifiSsid = ssid;
      wifiBssid = bssid;
    });
  }

  @override
  void deactivate() {
    provisioner?.stop();
    super.deactivate();
  }

  void startProvision() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      statusMessage = "設定をおこなっています...\n電源を入れてしばらくお待ち下さい。";
      provisioning = true;
    });
    try {
      provisioner = Provisioner.espTouch();
      provisioner!.listen((response) {
        debugPrint("Device ${response.bssidText} connected to WiFi!");
        setState(() {
          provisioner?.stop();
          provisioning = false;
        });
        if (response.ipAddressText != null) {
          setState(() {
            statusMessage = "${response.ipAddressText} が接続されました。";
            resultIpAddress = response.ipAddressText;
          });
        }
      }, onError: (e) {
        setState(() {
          statusMessage = "エラー\n${e.toString()}";
        });
      }, onDone: () {
        debugPrint("Done");
      });
      await provisioner!.start(ProvisioningRequest.fromStrings(
        ssid: wifiSsid!,
        bssid: wifiBssid!,
        password: wifiPassphraseTextArea.text,
      ));
    } catch (e) {
      setState(() {
        statusMessage = "処理が開始できませんでした。\n${e.toString()}";
        provisioning = false;
      });
    }
  }

  void stopProvision() {
    provisioner?.stop();
    setState(() {
      statusMessage = "";
      provisioning = false;
    });
  }

  void close() {
    Navigator.of(context).pop(resultIpAddress);
  }

  bool isWifiConnected() {
    return wifiSsid != null && wifiBssid != null;
  }

  bool canProvision() {
    return isWifiConnected() && wifiPassphraseTextArea.text.isNotEmpty;
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
                        visible: isWifiConnected(),
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
                                        "$wifiSsid",
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
                                        "$wifiBssid",
                                        textAlign: TextAlign.left,
                                        style: Theme.of(context).textTheme.bodyLarge,
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                  child: TextFormField(
                                    obscureText: isWifiPassphraseObscure,
                                    readOnly: provisioning,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                      labelText: "パスフレーズ",
                                      suffixIcon: IconButton(
                                        icon: Icon(isWifiPassphraseObscure ? Icons.visibility_off : Icons.visibility),
                                        onPressed: () {
                                          setState(() {
                                            isWifiPassphraseObscure = !isWifiPassphraseObscure;
                                          });
                                        },
                                      ),
                                    ),
                                    controller: wifiPassphraseTextArea,
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
              visible: provisioning,
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
                    visible: statusMessage.isNotEmpty,
                    child: Text(
                      statusMessage,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Visibility(
                    visible: resultIpAddress == null,
                    child: SizedBox(
                      width: double.infinity,
                      child: ValueListenableBuilder(
                        valueListenable: wifiPassphraseTextArea,
                        builder: (context, value, child) {
                          return ElevatedButton(
                            onPressed: canProvision() ? (provisioning ? stopProvision : startProvision) : null,
                            child: Text(
                              provisioning ? "キャンセル" : "設定開始",
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Visibility(
                    visible: resultIpAddress != null,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: close,
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

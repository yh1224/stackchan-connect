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
  Provisioner? provisioner;
  final wifiPassphraseTextArea = TextEditingController();

  bool isProvisioning = false;
  bool isDone = false;
  String? wifiSsid;
  String? wifiBssid;
  bool isObscure = true;
  String message = '';
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
      message = '設定をおこなっています...\n電源を入れてしばらくお待ち下さい。';
      isProvisioning = true;
    });
    try {
      provisioner = Provisioner.espTouch();
      provisioner!.listen((response) {
        debugPrint("Device ${response.bssidText} connected to WiFi!");
        setState(() {
          provisioner?.stop();
          isProvisioning = false;
        });
        if (response.ipAddressText != null) {
          setState(() {
            message = "${response.ipAddressText} が接続されました。";
            resultIpAddress = response.ipAddressText;
          });
        }
      }, onError: (e) {
        setState(() {
          message = "エラー\n${e.toString()}";
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
        message = "処理が開始できませんでした。\n${e.toString()}";
        isProvisioning = false;
      });
    }
  }

  void stopProvision() {
    provisioner?.stop();
    setState(() {
      message = '';
      isProvisioning = false;
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
        title: const Text('SmartConfig'),
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
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      Visibility(
                        visible: isWifiConnected(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "SSID: $wifiSsid",
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                Text(
                                  "BSSID: $wifiBssid",
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                TextFormField(
                                  obscureText: isObscure,
                                  readOnly: isProvisioning,
                                  decoration: InputDecoration(
                                    labelText: "パスフレーズ",
                                    suffixIcon: IconButton(
                                      icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility),
                                      onPressed: () {
                                        setState(() {
                                          isObscure = !isObscure;
                                        });
                                      },
                                    ),
                                  ),
                                  controller: wifiPassphraseTextArea,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Visibility(
              visible: isProvisioning,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: const [
                      CircularProgressIndicator(
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Visibility(
              visible: resultIpAddress == null,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                width: double.infinity,
                child: ValueListenableBuilder(
                  valueListenable: wifiPassphraseTextArea,
                  builder: (context, value, child) {
                    return ElevatedButton(
                      onPressed: canProvision() ? (isProvisioning ? stopProvision : startProvision) : null,
                      child: Text(
                        isProvisioning ? 'キャンセル' : '設定開始',
                        style: const TextStyle(fontSize: 20),
                      ),
                    );
                  },
                ),
              ),
            ),
            Visibility(
              visible: resultIpAddress != null,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: close,
                  child: const Text("OK", style: TextStyle(fontSize: 20)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

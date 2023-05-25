import 'package:esp_smartconfig/esp_smartconfig.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class SmartConfigPage extends ConsumerStatefulWidget {
  const SmartConfigPage({super.key});

  @override
  ConsumerState<SmartConfigPage> createState() => _SmartConfigPageState();
}

class _SmartConfigPageState extends ConsumerState<SmartConfigPage> {
  /// SmartConfig Provisioner
  Provisioner? _provisioner;

  /// ステータスメッセージ
  final _statusMessageProvider = StateProvider((ref) => "");

  /// Provision 実行中
  final _provisioningProvider = StateProvider((ref) => false);

  /// 接続中の SSID
  final _wifiSsidProvider = StateProvider<String?>((ref) => null);

  /// 接続中の BSSID
  final _wifiBssidProvider = StateProvider<String?>((ref) => null);

  /// Wi-Fi パスワード入力
  final _wifiPassphraseTextArea = TextEditingController();
  final _isWifiPassphraseObscureProvider = StateProvider((ref) => true);

  /// IP アドレス取得結果
  final _resultIpAddressProvider = StateProvider<String?>((ref) => null);

  @override
  void initState() {
    super.initState();
    Future(() async {
      await _init();
    });
  }

  Future<void> _init() async {
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
    ref.read(_wifiSsidProvider.notifier).state = ssid;
    ref.read(_wifiBssidProvider.notifier).state = bssid;
  }

  @override
  void deactivate() {
    _provisioner?.stop();
    super.deactivate();
  }

  Future<void> _startProvision() async {
    FocusManager.instance.primaryFocus?.unfocus();
    ref.read(_statusMessageProvider.notifier).state = "設定をおこなっています...\n電源を入れてしばらくお待ち下さい。";
    ref.read(_provisioningProvider.notifier).state = true;
    try {
      _provisioner = Provisioner.espTouch();
      _provisioner!.listen((response) {
        debugPrint("Device ${response.bssidText} connected to WiFi!");
        _provisioner?.stop();
        ref.read(_provisioningProvider.notifier).state = false;
        if (response.ipAddressText != null) {
          ref.read(_statusMessageProvider.notifier).state = "${response.ipAddressText} が接続されました。";
          ref.read(_resultIpAddressProvider.notifier).state = response.ipAddressText;
        }
      }, onError: (e) {
        ref.read(_statusMessageProvider.notifier).state = "エラー\n${e.toString()}";
      }, onDone: () {
        debugPrint("Done");
      });
      await _provisioner!.start(ProvisioningRequest.fromStrings(
        ssid: ref.read(_wifiSsidProvider)!,
        bssid: ref.read(_wifiBssidProvider)!,
        password: _wifiPassphraseTextArea.text.trim(),
      ));
    } catch (e) {
      ref.read(_statusMessageProvider.notifier).state = "処理が開始できませんでした。\n${e.toString()}";
      ref.read(_provisioningProvider.notifier).state = false;
    }
  }

  void _stopProvision() {
    _provisioner?.stop();
    ref.read(_statusMessageProvider.notifier).state = "";
    ref.read(_provisioningProvider.notifier).state = false;
  }

  void _close() {
    Navigator.of(context).pop(ref.read(_resultIpAddressProvider));
  }

  @override
  Widget build(BuildContext context) {
    final statusMessage = ref.watch(_statusMessageProvider);
    final provisioning = ref.watch(_provisioningProvider);
    final wifiSsid = ref.watch(_wifiSsidProvider);
    final wifiBssid = ref.watch(_wifiBssidProvider);
    final isWifiPassphraseObscure = ref.watch(_isWifiPassphraseObscureProvider);
    final resultIpAddress = ref.watch(_resultIpAddressProvider);
    final isWifiConnected = wifiSsid != null && wifiBssid != null;

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
                        visible: isWifiConnected,
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
                                          ref.read(_isWifiPassphraseObscureProvider.notifier).update((state) => !state);
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
                        valueListenable: _wifiPassphraseTextArea,
                        builder: (context, value, child) {
                          return ElevatedButton(
                            onPressed: (isWifiConnected && _wifiPassphraseTextArea.text.trim().isNotEmpty)
                                ? (provisioning ? _stopProvision : _startProvision)
                                : null,
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

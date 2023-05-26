import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stackchan_connect/view/home.dart';

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
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.teal),
          scaffoldBackgroundColor: Colors.teal[50],
          cardTheme: const CardTheme(
            surfaceTintColor: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Theme.of(context).colorScheme.onPrimary,
            hintStyle: TextStyle(
              color: Colors.green[700],
            ),
          ),
        ),
        home: const AppHomePage(),
      ),
    );
  }
}

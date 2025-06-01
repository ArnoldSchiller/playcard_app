// lib/main.dart
/*
Importiert config.dart für material.dart, constants.dart, app_theme.dart.

Verwendet lightTheme und darkTheme direkt.

main.dart  delegiert Provider an app_startup.dart.

Benennt initializeApp zu init für Konsistenz (optional).
*/

import 'package:playcard_app/config/config.dart';
import 'package:playcard_app/screens/radio_status_screen.dart';
import 'package:playcard_app/utils/app_startup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStartup.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppStartup.build(
      child: MaterialApp(
        title: kAppName,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        home: const RadioStatusScreen(),
      ),
    );
  }
}

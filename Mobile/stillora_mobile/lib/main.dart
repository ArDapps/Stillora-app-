import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/design/stillora_colors.dart';
import 'core/pro/pro_store.dart';
import 'core/storage/app_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  // Loopara banners load on demand inside AdSlotWidget — no SDK init needed.
  final preferences = await SharedPreferences.getInstance();
  final appPreferences = AppPreferences(preferences);
  // Seed the design tokens before the first frame so the app never flashes the
  // wrong palette on launch. StilloraPaletteScope keeps them in sync afterwards.
  StilloraColors.activate(
    StilloraPalette.forBrightness(switch (appPreferences.themeMode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system =>
        WidgetsBinding.instance.platformDispatcher.platformBrightness,
    }),
  );
  runApp(
    ProviderScope(
      overrides: [
        appPreferencesProvider.overrideWithValue(appPreferences),
        // Lifetime-Pro entitlement + cached price, read synchronously by the
        // sidebar and every ad slot from the first frame.
        proStoreProvider.overrideWithValue(PreferencesProStore(appPreferences)),
      ],
      child: const StilloraApp(),
    ),
  );
}

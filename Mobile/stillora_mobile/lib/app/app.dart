import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

class StilloraApp extends ConsumerWidget {
  const StilloraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Stillora',
      debugShowCheckedModeBanner: false,
      theme: buildStilloraTheme(Brightness.light),
      darkTheme: buildStilloraTheme(Brightness.dark),
      routerConfig: router,
    );
  }
}

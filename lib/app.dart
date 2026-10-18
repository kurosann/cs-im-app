import 'dart:async';

import 'package:flutter/material.dart';

import 'data/chat_repository_factory.dart';
import 'data/translation_service.dart';
import 'data/translation_service_factory.dart';
import 'screens/home_shell.dart';
import 'state/app_scope.dart';
import 'state/app_store.dart';
import 'theme/app_theme.dart';

class CsImApp extends StatefulWidget {
  const CsImApp({
    super.key,
    this.translationService,
    this.enablePersistence = true,
  });

  final TranslationService? translationService;
  final bool enablePersistence;

  @override
  State<CsImApp> createState() => _CsImAppState();
}

class _CsImAppState extends State<CsImApp> {
  late final AppStore _store = AppStore(
    createChatRepository(),
    widget.translationService ?? createTranslationService(),
    persistenceEnabled: widget.enablePersistence,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_store.init());
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      store: _store,
      child: AnimatedBuilder(
        animation: _store,
        builder: (BuildContext context, Widget? child) {
          final Brightness platformBrightness =
              WidgetsBinding.instance.platformDispatcher.platformBrightness;
          final ThemeMode mode = _store.themeMode;
          final bool dark =
              mode == ThemeMode.dark ||
              (mode == ThemeMode.system &&
                  platformBrightness == Brightness.dark);
          AppColors.useDark(dark);
          return MaterialApp(
            title: 'CS-IM 移动值守',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(Brightness.light),
            darkTheme: buildAppTheme(Brightness.dark),
            themeMode: mode,
            home: const HomeShell(),
          );
        },
      ),
    );
  }
}

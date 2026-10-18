import 'dart:async';

import 'package:flutter/material.dart';

import 'data/chat_repository_factory.dart';
import 'data/translation_service.dart';
import 'data/translation_service_factory.dart';
import 'screens/home_shell.dart';
import 'screens/login_page.dart';
import 'state/app_scope.dart';
import 'state/app_store.dart';
import 'theme/app_theme.dart';

class CsImApp extends StatefulWidget {
  const CsImApp({
    super.key,
    this.translationService,
    this.enablePersistence = true,
    this.requireLogin,
  });

  final TranslationService? translationService;
  final bool enablePersistence;
  final bool? requireLogin;

  @override
  State<CsImApp> createState() => _CsImAppState();
}

class _CsImAppState extends State<CsImApp> {
  late final AppStore _store = AppStore(
    createChatRepository(),
    widget.translationService ?? createTranslationService(),
    persistenceEnabled: widget.enablePersistence,
  );
  bool _authenticated = false;

  @override
  void initState() {
    super.initState();
    _authenticated = !(widget.requireLogin ?? widget.enablePersistence);
    if (_authenticated) {
      unawaited(_store.init());
    }
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  Future<void> _login({
    required String account,
    required String password,
  }) async {
    // The mock repository has no remote handshake yet. Keep this boundary
    // ready for the account/password auth endpoint.
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) {
      return;
    }
    setState(() => _authenticated = true);
    if (_store.loading) {
      unawaited(_store.init());
    }
  }

  void _logout() {
    if (!mounted) {
      return;
    }
    setState(() => _authenticated = false);
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
            home: _authenticated
                ? HomeShell(onLogout: _logout)
                : LoginPage(onLogin: _login),
          );
        },
      ),
    );
  }
}

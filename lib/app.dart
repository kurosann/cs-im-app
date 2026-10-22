import 'dart:async';

import 'package:flutter/material.dart';

import 'config/app_config.dart';
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
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _authenticated = !(widget.requireLogin ?? widget.enablePersistence);
    if (_authenticated) {
      unawaited(_store.init());
      _startRefresh();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _store.dispose();
    super.dispose();
  }

  void _startRefresh() {
    if (AppConfig.useMockData) {
      return;
    }
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      unawaited(_store.refresh());
    });
  }

  Future<void> _login({
    required String account,
    required String password,
  }) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 280));
    }
    await _store.login(account: account, password: password);
    try {
      await _store.init();
    } catch (_) {
      try {
        await _store.logout();
      } catch (_) {
        // Preserve the workspace loading error shown on the login form.
      }
      rethrow;
    }
    if (!mounted) {
      return;
    }
    setState(() => _authenticated = true);
    _startRefresh();
  }

  Future<void> _logout() async {
    _refreshTimer?.cancel();
    if (!mounted) {
      return;
    }
    setState(() => _authenticated = false);
    try {
      await _store.logout();
    } catch (_) {
      // Local session data is cleared even if the server cannot be reached.
    }
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

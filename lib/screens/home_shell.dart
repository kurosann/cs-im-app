import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../state/app_scope.dart';
import '../state/app_store.dart';
import '../theme/app_theme.dart';
import 'duty_page.dart';
import 'me_page.dart';
import 'status_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.onLogout});

  final VoidCallback? onLogout;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final AppStore store = AppScope.of(context);
    final Brightness brightness = Theme.of(context).brightness;
    if (store.loading) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(color: AppColors.surface),
                  child: IndexedStack(
                    index: _index,
                    children: [
                      const DutyPage(),
                      const StatusPage(),
                      MePage(onLogout: widget.onLogout),
                    ],
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 16,
                  child: _BottomNav(
                    key: ValueKey<Brightness>(brightness),
                    index: _index,
                    onChanged: (int value) => setState(() => _index = value),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({super.key, required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 52,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.frost,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.frostBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.frostShadow,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildItem(0, Icons.inbox_outlined, '值守'),
              _buildItem(1, Icons.show_chart_rounded, '状态'),
              _buildItem(2, Icons.person_outline_rounded, '我的'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(int itemIndex, IconData icon, String label) {
    final bool active = index == itemIndex;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(itemIndex),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: active ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: active ? AppColors.onAccent : AppColors.inkSoft,
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: appFontFamily,
                    fontFamilyFallback: appFontFallback,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                    color: active ? AppColors.onAccent : AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

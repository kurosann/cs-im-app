import 'package:flutter/material.dart';

import '../state/app_scope.dart';
import '../state/app_store.dart';
import '../theme/app_theme.dart';
import '../utils/format_bytes.dart';
import '../widgets/app_card.dart';
import 'storage_agreement_page.dart';

class StorageSpacePage extends StatelessWidget {
  const StorageSpacePage({super.key});

  static const int _capBytes = 512 * 1024 * 1024;

  @override
  Widget build(BuildContext context) {
    final AppStore store = AppScope.of(context);
    final int total = store.cacheBytes;
    final Map<String, int> usage = store.cacheUsage;
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(6, 8, 16, 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(bottom: BorderSide(color: AppColors.line)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        splashRadius: 20,
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: AppColors.ink,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          '存储空间',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    children: [
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  '本地缓存',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  formatBytes(total),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.inkSoft,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: total / _capBytes,
                                minHeight: 8,
                                backgroundColor: AppColors.lavender,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '上限 512 MB · 清理后不影响服务器上的消息与客户数据',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '缓存仅保存在本机，不会上传用于广告或第三方营销。',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 16),
                            for (final MapEntry<String, int> entry
                                in usage.entries) ...[
                              Row(
                                children: [
                                  Text(
                                    entry.key,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.inkSoft,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    formatBytes(entry.value),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              if (entry.key != usage.keys.last)
                                const SizedBox(height: 8),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (BuildContext context) =>
                                  const StorageAgreementPage(),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  size: 20,
                                  color: AppColors.inkSoft,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    '存储协议',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: AppColors.muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: total == 0
                            ? null
                            : () => _confirmClear(context, store),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.red50,
                          disabledForegroundColor: AppColors.red600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: Text(total == 0 ? '本地缓存已清空' : '清理本地缓存'),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '清理本地缓存不会删除服务器上的消息、会话与客户资料。',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, AppStore store) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('清理本地缓存'),
        content: const Text('将删除本机缓存的图片、视频、语音和临时文件，不影响服务器上的消息与客户数据。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('清理'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await store.clearCache();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('本地缓存已清理')));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final auth = ref.watch(authProvider);
    final locale = ref.watch(localeProvider);
    final langName = kLanguageNames[locale.languageCode] ?? '🌐';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── App bar ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios,
                        color: AppColors.textPrimary),
                    onPressed: () => context.go('/home'),
                  ),
                  Text(l.settings,
                      style: Theme.of(context).textTheme.headlineMedium),
                ]),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Profile card ───────────────────────────────
                      _SectionHeader(l.profile),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.surfaceLight),
                        ),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              (auth.user?.displayName ?? 'H').isEmpty
                                  ? 'H'
                                  : auth.user!.displayName
                                      .substring(0, 1)
                                      .toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 22,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(auth.user?.displayName ?? '—',
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(auth.user?.email ?? '—',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 24),

                      // ── Language ───────────────────────────────────
                      _SectionHeader(l.language),
                      _SettingsTile(
                        icon: Icons.language,
                        iconColor: AppColors.info,
                        title: l.selectLanguage,
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(langName,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right,
                              color: AppColors.textHint, size: 20),
                        ]),
                        onTap: () => _showLanguagePicker(context, ref),
                      ),
                      const SizedBox(height: 24),

                      // ── Hiking ────────────────────────────────────
                      _SectionHeader(l.hikerPreferences),
                      _SettingsTile(
                        icon: Icons.tune,
                        iconColor: AppColors.primaryLight,
                        title: l.hikerPreferences,
                        subtitle: l.savePreferences,
                        trailing: const Icon(Icons.chevron_right,
                            color: AppColors.textHint, size: 20),
                        onTap: () => context.go('/preferences'),
                      ),
                      const SizedBox(height: 24),

                      // ── About ──────────────────────────────────────
                      _SectionHeader('About'),
                      _SettingsTile(
                        icon: Icons.info_outline,
                        iconColor: AppColors.accent,
                        title: 'HikeSilla',
                        subtitle: 'Parco Nazionale della Sila · v1.0.0',
                      ),
                      _SettingsTile(
                        icon: Icons.security,
                        iconColor: AppColors.success,
                        title: 'Authentication',
                        subtitle: 'Firebase Auth · JWT secured',
                      ),
                      const SizedBox(height: 24),

                      // ── Logout ─────────────────────────────────────
                      _SectionHeader(l.logout),
                      _SettingsTile(
                        icon: Icons.logout,
                        iconColor: AppColors.danger,
                        title: l.logout,
                        titleColor: AppColors.danger,
                        onTap: () => _confirmLogout(context, ref, l),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(localeProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundSecondary,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _LanguageSheet(current: current, ref: ref),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref, AppLocalizations l) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.logout,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text('Are you sure you want to sign out?',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancel,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            child: Text(l.logout,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Language sheet (reused from picker) ───────────────────────────────────
class _LanguageSheet extends StatelessWidget {
  final Locale current;
  final WidgetRef ref;
  const _LanguageSheet({required this.current, required this.ref});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(l.selectLanguage,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...kSupportedLocales.map((locale) {
              final isSelected = locale.languageCode == current.languageCode;
              final name = kLanguageNames[locale.languageCode] ?? '';
              return GestureDetector(
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale(locale);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryLight
                          : AppColors.surfaceLight,
                    ),
                  ),
                  child: Row(children: [
                    Text(name,
                        style: TextStyle(
                            color: isSelected
                                ? AppColors.primaryLight
                                : AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal)),
                    const Spacer(),
                    if (isSelected)
                      const Icon(Icons.check_circle,
                          color: AppColors.primaryLight, size: 20),
                  ]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8)),
      );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color titleColor;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.titleColor = AppColors.textPrimary,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: titleColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ]),
      ),
    );
  }
}

// expose for use in language_picker.dart
String get profile => 'Profile';

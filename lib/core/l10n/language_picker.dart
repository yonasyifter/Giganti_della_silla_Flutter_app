import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_localizations.dart';
import 'locale_provider.dart';
import '../../core/constants/app_colors.dart';

/// A compact flag+name button that opens a bottom sheet to pick language.
class LanguagePickerButton extends ConsumerWidget {
  const LanguagePickerButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final name = kLanguageNames[locale.languageCode] ?? '🌐';

    return GestureDetector(
      onTap: () => _showPicker(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(name.split(' ').first,
              style: const TextStyle(fontSize: 16)), // flag emoji
          const SizedBox(width: 6),
          const Icon(Icons.keyboard_arrow_down,
              color: AppColors.textSecondary, size: 16),
        ]),
      ),
    );
  }

  void _showPicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(localeProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundSecondary,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _LanguageSheet(current: current, ref: ref),
    );
  }
}

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
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(2),
                ),
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
              final isSelected =
                  locale.languageCode == current.languageCode;
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  int _locationIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/map')) return 1;
    if (location.startsWith('/weather')) return 2;
    if (location.startsWith('/chatbot')) return 3;
    if (location.startsWith('/preferences')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = _locationIndex(context);
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded,
                    label: l.navHome, isActive: index == 0,
                    onTap: () => context.go('/home')),
                _NavItem(icon: Icons.map_outlined, activeIcon: Icons.map_rounded,
                    label: l.navMap, isActive: index == 1,
                    onTap: () => context.go('/map')),
                _NavItem(icon: Icons.cloud_outlined, activeIcon: Icons.cloud_rounded,
                    label: l.navWeather, isActive: index == 2,
                    onTap: () => context.go('/weather')),
                _NavItem(icon: Icons.smart_toy_outlined, activeIcon: Icons.smart_toy_rounded,
                    label: l.navAI, isActive: index == 3,
                    onTap: () => context.go('/chatbot')),
                _NavItem(icon: Icons.tune_outlined, activeIcon: Icons.tune_rounded,
                    label: l.navPrefs, isActive: index == 4,
                    onTap: () => context.go('/preferences')),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/sos'),
        backgroundColor: AppColors.danger,
        elevation: 8,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sos_rounded, color: Colors.white, size: 22),
            Text('SOS', style: TextStyle(
                color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.activeIcon,
      required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(isActive ? activeIcon : icon,
              color: isActive ? AppColors.primaryLight : AppColors.textHint,
              size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(
              color: isActive ? AppColors.primaryLight : AppColors.textHint,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
        ]),
      ),
    );
  }
}

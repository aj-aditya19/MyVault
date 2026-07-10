import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:app/core/utils/responsive.dart';

class NavItemData {
  final IconData icon;
  final String label;
  final bool locked;

  const NavItemData({
    required this.icon,
    required this.label,
    this.locked = false,
  });
}

class Navigatebar extends StatelessWidget {
  final int currentIndex;
  final List<NavItemData> items;
  final ValueChanged<int> onTap;

  const Navigatebar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  Widget _iconFor(NavItemData item, ColorScheme scheme) {
    final icon = Icon(item.icon);
    if (!item.locked) return icon;
    return Badge(
      label: const Icon(Icons.lock_rounded, size: 9, color: Colors.white),
      backgroundColor: scheme.error,
      child: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (Responsive.useSideNav(context)) {
      final extended = Responsive.isDesktop(context);
      return NavigationRail(
        backgroundColor: scheme.surface.withValues(alpha: 0.6),
        extended: extended,
        minExtendedWidth: 180,
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        labelType: extended ? null : NavigationRailLabelType.all,
        destinations: items
            .map(
              (item) => NavigationRailDestination(
                icon: _iconFor(item, scheme),
                label: Text(item.label),
              ),
            )
            .toList(),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.66),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.30),
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              selectedIndex: currentIndex,
              onDestinationSelected: onTap,
              destinations: items
                  .map(
                    (item) => NavigationDestination(
                      icon: _iconFor(item, scheme),
                      label: item.label,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:ui';

class Navigatebar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const Navigatebar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<Navigatebar> createState() => _NavigatebarState();
}

class _NavigatebarState extends State<Navigatebar> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
              selectedIndex: widget.currentIndex,
              onDestinationSelected: widget.onTap,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.task_alt_rounded),
                  label: "Tasks",
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_rounded),
                  label: "Money",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

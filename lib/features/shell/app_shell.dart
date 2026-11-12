import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';

/// Alt menü (mobil) veya yan menü (geniş ekran) ile ana iskelet.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onSelect(int index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      (Icons.map_outlined, Icons.map_rounded, l10n.navMap),
      (Icons.explore_outlined, Icons.explore_rounded, l10n.navEvents),
      (Icons.add_circle_outline_rounded, Icons.add_circle_rounded, l10n.navAdd),
      (Icons.person_outline_rounded, Icons.person_rounded, l10n.navProfile),
    ];

    if (context.isWide) {
      final extended = context.screenWidth >= Breakpoints.large;
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: extended,
              minExtendedWidth: 220,
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onSelect,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: AppLogo(showName: extended),
              ),
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              destinations: [
                for (final (icon, selected, label) in items)
                  NavigationRailDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(selected),
                    label: Text(label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onSelect,
        destinations: [
          for (final (icon, selected, label) in items)
            NavigationDestination(
              icon: Icon(icon),
              selectedIcon: Icon(selected),
              label: label,
            ),
        ],
      ),
    );
  }
}

/// Telefon görünümünde ekranların üstündeki marka satırı.
/// Geniş ekranda logo zaten yan menüde olduğu için gizlenir.
class MobileBrandBar extends StatelessWidget {
  const MobileBrandBar({super.key});

  @override
  Widget build(BuildContext context) {
    if (context.isWide) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.only(bottom: 18),
      child: AppLogo(size: 36),
    );
  }
}

/// Haritadaki arama çubuğunun yanında duran gölgeli logo işareti.
class AppLogoBadge extends StatelessWidget {
  const AppLogoBadge({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) => Material(
        elevation: 6,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(size * 0.3),
        clipBehavior: Clip.antiAlias,
        child: AppLogo(showName: false, size: size),
      );
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.showName = true, this.size = 40});

  final bool showName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final mark = SvgPicture.asset(
      'assets/brand/mahallem_icon.svg',
      width: size,
      height: size,
      semanticsLabel: context.l10n.appTitle,
    );
    if (!showName) return mark;
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: size * 0.25),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Mahalle'),
              TextSpan(
                text: 'm',
                style: TextStyle(color: AppColors.sunset),
              ),
            ],
          ),
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: size * 0.55,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

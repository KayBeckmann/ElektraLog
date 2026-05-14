import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../../core/router.dart';
import '../../core/providers/app_mode_provider.dart';

/// Desktop breakpoint: 768px (md)
const double _kDesktopBreakpoint = 768.0;

/// Width of the left navigation drawer on desktop
const double _kDrawerWidth = 320.0;

/// Nav item data model
class _NavItem {
  const _NavItem({
    required this.route,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final String route;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

const _navItems = [
  _NavItem(
    route: AppRoutes.dashboard,
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    label: 'Dashboard',
  ),
  _NavItem(
    route: AppRoutes.kunden,
    icon: Icons.business_center_outlined,
    selectedIcon: Icons.business_center,
    label: 'Kunden',
  ),
  _NavItem(
    route: AppRoutes.struktur,
    icon: Icons.account_tree_outlined,
    selectedIcon: Icons.account_tree,
    label: 'Struktur',
  ),
  _NavItem(
    route: AppRoutes.historie,
    icon: Icons.history_outlined,
    selectedIcon: Icons.history,
    label: 'Historie',
  ),
  _NavItem(
    route: AppRoutes.signatur,
    icon: Icons.draw_outlined,
    selectedIcon: Icons.draw,
    label: 'Signatur',
  ),
];

/// Main app shell — provides adaptive navigation:
/// - Mobile (<768px): Fixed bottom navigation bar with 5 tabs
/// - Desktop (≥768px): 320px fixed left drawer with profile header + nav links
class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _kDesktopBreakpoint) {
          return _DesktopShell(child: child);
        }
        return _MobileShell(child: child);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Desktop Shell
// ─────────────────────────────────────────────────────────────────────────────

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          _DesktopDrawer(),
          const VerticalDivider(
            width: 1,
            color: AppColors.outlineVariant,
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _DesktopDrawer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;

    return SizedBox(
      width: _kDrawerWidth,
      child: Material(
        color: AppColors.surfaceContainerLow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── App Bar Area ──────────────────────────────────────────
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.outlineVariant),
                ),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                'ElektraLog',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Profile Header ────────────────────────────────
                    _ProfileHeader(),
                    const SizedBox(height: 24),
                    const Divider(color: AppColors.outlineVariant),
                    const SizedBox(height: 8),

                    // ── Navigation Links ──────────────────────────────
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: _navItems.map((item) {
                          final isSelected = location == item.route ||
                              (item.route == AppRoutes.dashboard &&
                                  location == '/');
                          return _DrawerNavItem(
                            item: item,
                            isSelected: isSelected,
                            onTap: () => context.go(item.route),
                          );
                        }).toList(),
                      ),
                    ),

                    // ── Auth / Logout ─────────────────────────────────
                    const Divider(color: AppColors.outlineVariant),
                    const SizedBox(height: 8),
                    Consumer(builder: (context, ref, _) {
                      final modusAsync = ref.watch(appModusProvider);
                      return modusAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (modus) => modus == AppModus.company
                            ? _DrawerActionItem(
                                icon: Icons.logout_outlined,
                                label: 'Abmelden',
                                onTap: () async {
                                  await ref
                                      .read(appModusProvider.notifier)
                                      .logout();
                                  if (context.mounted) context.go('/');
                                },
                              )
                            : _DrawerActionItem(
                                icon: Icons.cloud_outlined,
                                label: 'Mit Konto verbinden',
                                onTap: () => context.go(AppRoutes.auth),
                              ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final modusAsync = ref.watch(appModusProvider);
    final isCompany = modusAsync.valueOrNull == AppModus.company;
    final name = userAsync.valueOrNull?['name'] ?? 'Prüfer';
    final subtitle = isCompany ? 'Company-Modus' : 'Solo-Modus';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompany
                ? AppColors.secondaryContainer
                : AppColors.surfaceContainerHigh,
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Icon(
            isCompany ? Icons.business : Icons.person,
            size: 28,
            color: isCompany
                ? AppColors.onSecondaryContainer
                : AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),

        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              if (isCompany) ...[
                const SizedBox(height: 2),
                Text(
                  userAsync.valueOrNull?['firmaId']?.substring(0, 8) ??
                      '',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    color: AppColors.outline,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DrawerNavItem extends StatelessWidget {
  const _DrawerNavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected
            ? AppColors.secondaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  size: 22,
                  color: isSelected
                      ? AppColors.onSecondaryContainer
                      : AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isSelected
                            ? AppColors.onSecondaryContainer
                            : AppColors.onSurfaceVariant,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
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

class _DrawerActionItem extends StatelessWidget {
  const _DrawerActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile Shell
// ─────────────────────────────────────────────────────────────────────────────

class _MobileShell extends StatelessWidget {
  const _MobileShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _selectedIndex(location);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: _MobileBottomNav(
        selectedIndex: selectedIndex,
        onItemSelected: (index) => context.go(_navItems[index].route),
      ),
    );
  }

  int _selectedIndex(String location) {
    for (var i = 0; i < _navItems.length; i++) {
      if (location == _navItems[i].route) return i;
    }
    return 0;
  }
}

class _MobileBottomNav extends StatelessWidget {
  const _MobileBottomNav({
    required this.selectedIndex,
    required this.onItemSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onItemSelected,
      destinations: _navItems
          .map(
            (item) => NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            ),
          )
          .toList(),
    );
  }
}

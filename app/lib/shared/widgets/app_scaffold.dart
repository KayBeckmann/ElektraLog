import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../../core/router.dart';
import '../../core/providers/app_mode_provider.dart';
import '../../core/providers/isar_provider.dart';
import '../../core/sync/sync_service.dart';
// isAdminProvider kommt aus app_mode_provider

/// Desktop breakpoint: 768px (md)
const double _kDesktopBreakpoint = 768.0;

/// Width of the left navigation drawer on desktop
const double _kDrawerWidth = 320.0;

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

const _baseNavItems = [
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
    route: AppRoutes.einstellungen,
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    label: 'Einstellungen',
  ),
];

const _teamNavItem = _NavItem(
  route: AppRoutes.team,
  icon: Icons.manage_accounts_outlined,
  selectedIcon: Icons.manage_accounts,
  label: 'Benutzerverwaltung',
);

List<_NavItem> _buildNavItems({required bool isCompany, required bool isAdmin}) {
  if (!isCompany || !isAdmin) return _baseNavItems;
  // Im Company-Modus als Admin: Team vor Einstellungen einfügen
  return [
    _baseNavItems[0],
    _baseNavItems[1],
    _baseNavItems[2],
    _teamNavItem,
    _baseNavItems[3],
  ];
}

/// Main app shell — provides adaptive navigation:
/// - Mobile (<768px): Fixed bottom navigation bar with 4 tabs
/// - Desktop (≥768px): 320px fixed left drawer with profile header + nav links
class AppScaffold extends ConsumerWidget {
  const AppScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Auto-Pull alle 60s im Company-Modus — startet nach Login, stoppt nach Logout
    ref.watch(autoSyncProvider);

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

class _DesktopDrawer extends ConsumerStatefulWidget {
  @override
  ConsumerState<_DesktopDrawer> createState() => _DesktopDrawerState();
}

class _DesktopDrawerState extends ConsumerState<_DesktopDrawer> {
  bool _isSyncing = false;

  Future<void> _sync() async {
    setState(() => _isSyncing = true);
    try {
      final db = await ref.read(dbProvider.future);
      await SyncService.pullAll(db);
      await SyncService.pushAll(db);
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final isCompany =
        ref.watch(appModusProvider).valueOrNull == AppModus.company;
    final isAdmin = ref.watch(isAdminProvider).valueOrNull ?? false;
    final navItems = _buildNavItems(isCompany: isCompany, isAdmin: isAdmin);

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
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/logo_64.png',
                    width: 36,
                    height: 36,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'ElektraLog',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
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
                        children: navItems.map((item) {
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

                    // ── Sync ─────────────────────────────────────────
                    if (isCompany) ...[
                      const Divider(color: AppColors.outlineVariant),
                      _SyncButton(
                        isSyncing: _isSyncing,
                        onTap: _isSyncing ? null : _sync,
                      ),
                    ],
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
                  userAsync.valueOrNull?['firmaId']?.substring(0, 8) ?? '',
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

class _SyncButton extends StatelessWidget {
  const _SyncButton({required this.isSyncing, required this.onTap});

  final bool isSyncing;
  final VoidCallback? onTap;

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
              SizedBox(
                width: 22,
                height: 22,
                child: isSyncing
                    ? const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      )
                    : const Icon(
                        Icons.sync,
                        size: 22,
                        color: AppColors.onSurfaceVariant,
                      ),
              ),
              const SizedBox(width: 16),
              Text(
                isSyncing ? 'Synchronisiert …' : 'Synchronisieren',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isSyncing
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
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

class _MobileShell extends ConsumerWidget {
  const _MobileShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final isCompany =
        ref.watch(appModusProvider).valueOrNull == AppModus.company;
    final isAdmin = ref.watch(isAdminProvider).valueOrNull ?? false;
    final navItems = _buildNavItems(isCompany: isCompany, isAdmin: isAdmin);
    final selectedIndex = _selectedIndex(location, navItems);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => context.go(navItems[index].route),
        destinations: navItems
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }

  int _selectedIndex(String location, List<_NavItem> navItems) {
    for (var i = 0; i < navItems.length; i++) {
      if (location == navItems[i].route) return i;
      if (navItems[i].route == AppRoutes.kunden &&
          location.startsWith('/kunden')) return i;
    }
    return 0;
  }
}

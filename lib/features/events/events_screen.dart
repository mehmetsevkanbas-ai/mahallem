import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/common.dart';
import '../../providers/providers.dart';
import 'event_widgets.dart';
import '../shell/app_shell.dart';

/// Yaklaşan etkinlikler ve kurslar: arama, filtre ve kişisel öneriler.
class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final eventsAsync = ref.watch(filteredEventsProvider);
    final filter = ref.watch(filterProvider);
    final recommended = ref.watch(recommendedEventsProvider);
    final hPad = context.screenWidth >= 600 ? 28.0 : 16.0;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(approvedEventsProvider.future),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const MobileBrandBar(),
                          Text(l10n.navEvents, style: theme.textTheme.headlineMedium),
                          const SizedBox(height: 2),
                          Text(
                            l10n.appTagline,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const DataFreshnessLabel(),
                          const SizedBox(height: 18),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 640),
                            child: const EventSearchField(),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: FilterBar(
                      showAllInline: true,
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                    ),
                  ),
                  if (!filter.isActive && recommended.isNotEmpty) ...[
                    _SectionHeader(
                      title: l10n.forYou,
                      subtitle: l10n.forYouSubtitle,
                      icon: Icons.auto_awesome_rounded,
                      hPad: hPad,
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 334,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: hPad),
                          itemCount: recommended.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 14),
                          itemBuilder: (context, i) => SizedBox(
                            width: 290,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 290, child: EventCard(event: recommended[i].event)),
                                const SizedBox(height: 8),
                                ReasonLine(reasons: recommended[i].reasons),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  _SectionHeader(
                    title: filter.isActive
                        ? l10n.resultsCount(eventsAsync.value?.length ?? 0)
                        : l10n.allEvents,
                    hPad: hPad,
                    trailing: filter.isActive
                        ? TextButton.icon(
                            onPressed: ref.read(filterProvider.notifier).reset,
                            icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                            label: Text(l10n.clearFilters),
                          )
                        : null,
                  ),
                  ...eventsAsync.when(
                    loading: () => [
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ],
                    error: (e, _) => [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: ErrorView(
                          error: e,
                          onRetry: () => ref.invalidate(approvedEventsProvider),
                        ),
                      ),
                    ],
                    data: (events) => [
                      if (events.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyState(
                            icon: Icons.search_off_rounded,
                            message: l10n.noResults,
                            action: FilledButton.tonal(
                              onPressed: ref.read(filterProvider.notifier).reset,
                              child: Text(l10n.clearFilters),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 32),
                          sliver: SliverGrid.builder(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 420,
                              mainAxisExtent: 290,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                            ),
                            itemCount: events.length,
                            itemBuilder: (context, i) => EventCard(event: events[i]),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.hPad,
    this.subtitle,
    this.icon,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final double hPad;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(hPad, 28, hPad, 14),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleLarge),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

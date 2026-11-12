import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/env.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/launchers.dart';
import '../../core/widgets/common.dart';
import '../../data/models/culture_event.dart';
import '../../providers/providers.dart';
import '../events/event_widgets.dart';
import 'map_layers.dart';
import '../shell/app_shell.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  bool _mapReady = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  CultureEvent? _findEvent(String? id) {
    if (id == null) return null;
    final all = ref.read(approvedEventsProvider).value ?? const [];
    return all.where((e) => e.id == id).firstOrNull;
  }

  void _select(String? id) =>
      ref.read(selectedEventIdProvider.notifier).select(id);

  void _moveTo(CultureEvent e) {
    if (!_mapReady) return;
    _mapController.move(e.point, math.max(_mapController.camera.zoom, 15));
  }

  static String _pointKey(CultureEvent e) =>
      '${e.lat.toStringAsFixed(5)},${e.lng.toStringAsFixed(5)}';

  /// Aynı noktadaki kayıtların listesi.
  void _openStack(List<CultureEvent> group) {
    final sorted = [...group]..sort((a, b) => a.sortKey.compareTo(b.sortKey));
    final venue = sorted.map((e) => e.venueName).whereType<String>().firstOrNull;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (context) {
        final theme = Theme.of(context);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, controller) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Text(venue ?? context.l10n.location, style: theme.textTheme.titleLarge),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  [
                    context.l10n.eventsHere(sorted.length),
                    ?sorted.first.address,
                  ].join(' · '),
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.all(10),
                  itemCount: sorted.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, i) => EventListTile(
                    event: sorted[i],
                    onTap: () {
                      Navigator.pop(context);
                      this.context.push('/event/${sorted[i].id}');
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _recenter() {
    _select(null);
    if (_mapReady) _mapController.move(Env.cityCenter, Env.cityZoom);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(selectedEventIdProvider, (_, id) {
      final e = _findEvent(id);
      if (e != null) _moveTo(e);
    });

    final eventsAsync = ref.watch(filteredEventsProvider);
    final events = eventsAsync.value ?? const <CultureEvent>[];
    final selectedId = ref.watch(selectedEventIdProvider);
    ref.watch(approvedEventsProvider);
    final selected = _findEvent(selectedId);

    // Aynı noktadaki kayıtlar (ör. bir kurs merkezindeki tüm kurslar) tek
    // işarette toplanır; aksi halde üst üste biner ve yalnızca biri seçilebilir.
    final stacks = <String, List<CultureEvent>>{};
    for (final e in [
      ...events.where((e) => e.id != selectedId),
      ?selected,
    ]) {
      stacks.putIfAbsent(_pointKey(e), () => []).add(e);
    }
    // Seçili kaydı içeren işaret en üstte çizilsin.
    final markerGroups = stacks.values.toList()
      ..sort((a, b) => (a.any((e) => e.id == selectedId) ? 1 : 0)
          .compareTo(b.any((e) => e.id == selectedId) ? 1 : 0));

    final map = FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: selected?.point ?? Env.cityCenter,
        initialZoom: selected != null ? 15 : Env.cityZoom,
        minZoom: 9,
        maxZoom: 19,
        onMapReady: () => _mapReady = true,
        onTap: (_, _) => _select(null),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        baseTileLayer(context),
        MarkerLayer(
          markers: [
            for (final group in markerGroups)
              Marker(
                point: group.first.point,
                width: EventMarker.selectedSize + 8,
                height: EventMarker.selectedSize + 8,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => group.length == 1
                        ? _select(group.first.id)
                        : _openStack(group),
                    child: Center(
                      child: Tooltip(
                        message: group.length == 1
                            ? group.first.title
                            : '${group.first.venueName ?? ''} · ${group.length}',
                        child: group.length == 1
                            ? EventMarker(event: group.first, selected: group.first.id == selectedId)
                            : StackMarker(
                                events: group,
                                selected: group.any((e) => e.id == selectedId),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        mapAttribution(),
      ],
    );

    final loadingBar = eventsAsync.isLoading
        ? const LinearProgressIndicator(minHeight: 3)
        : const SizedBox.shrink();

    if (context.isWide) {
      return Row(
        children: [
          SizedBox(
            width: 420,
            child: _SidePanel(
              eventsAsync: eventsAsync,
              selectedId: selectedId,
              onSelect: (e) => e.id == selectedId
                  ? context.push('/event/${e.id}')
                  : _select(e.id),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Stack(
              children: [
                map,
                Positioned(top: 0, left: 0, right: 0, child: loadingBar),
                Positioned(
                  right: 16,
                  top: 16,
                  child: _RecenterButton(onPressed: _recenter),
                ),
                if (selected != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 28,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: EventPreviewCard(
                          event: selected,
                          onClose: () => _select(null),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        map,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 12, 12, 10),
                  child: Row(
                    children: [
                      // Mobilde yan menü olmadığı için marka burada görünür.
                      AppLogoBadge(size: 50),
                      SizedBox(width: 10),
                      Expanded(child: EventSearchField(elevated: true)),
                    ],
                  ),
                ),
                const FilterBar(
                  onMap: true,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                ),
                const SizedBox(height: 6),
                loadingBar,
              ],
            ),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _RecenterButton(onPressed: _recenter),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween(begin: const Offset(0, 0.3), end: Offset.zero)
                      .animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: selected != null
                    ? EventPreviewCard(
                        key: ValueKey(selected.id),
                        event: selected,
                        onClose: () => _select(null),
                      )
                    : _ResultsPill(
                        count: events.length,
                        error: eventsAsync.error,
                        onRetry: () => ref.invalidate(approvedEventsProvider),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecenterButton extends StatelessWidget {
  const _RecenterButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FloatingActionButton.small(
        heroTag: 'recenter',
        tooltip: context.l10n.recenterMap,
        onPressed: onPressed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: const Icon(Icons.my_location_rounded),
      );
}

class _ResultsPill extends StatelessWidget {
  const _ResultsPill({required this.count, this.error, this.onRetry});

  final int count;
  final Object? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Center(
      child: Material(
        elevation: 4,
        shadowColor: Colors.black26,
        color: error != null ? scheme.errorContainer : scheme.inverseSurface,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: error != null ? onRetry : () => context.go('/events'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  error != null ? Icons.refresh_rounded : Icons.view_list_rounded,
                  size: 18,
                  color: error != null ? scheme.onErrorContainer : scheme.onInverseSurface,
                ),
                const SizedBox(width: 8),
                Text(
                  error != null ? l10n.retry : l10n.resultsCount(count),
                  style: TextStyle(
                    color: error != null ? scheme.onErrorContainer : scheme.onInverseSurface,
                    fontWeight: FontWeight.w700,
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

/// Haritada seçilen etkinliğin özet kartı.
class EventPreviewCard extends StatelessWidget {
  const EventPreviewCard({super.key, required this.event, required this.onClose});

  final CultureEvent event;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Material(
      elevation: 10,
      shadowColor: Colors.black38,
      color: theme.cardTheme.color,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/event/${event.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 88,
                      height: 88,
                      child: EventImage(event: event, iconSize: 32),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CategoryBadge(category: event.category),
                        const SizedBox(height: 6),
                        Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(height: 1.2),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${formatEventWhen(context, event)} · ${event.venueName ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => context.push('/event/${event.id}'),
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                      icon: const Icon(Icons.info_outline_rounded, size: 18),
                      label: Text(l10n.seeDetails),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => openDirections(event),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                      icon: const Icon(Icons.directions_rounded, size: 18),
                      label: Text(l10n.getDirections, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  FavoriteButton(eventId: event.id),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidePanel extends ConsumerWidget {
  const _SidePanel({
    required this.eventsAsync,
    required this.selectedId,
    required this.onSelect,
  });

  final AsyncValue<List<CultureEvent>> eventsAsync;
  final String? selectedId;
  final ValueChanged<CultureEvent> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final events = eventsAsync.value ?? const <CultureEvent>[];

    return ColoredBox(
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
            child: Text(l10n.upcomingEvents, style: theme.textTheme.headlineSmall),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${l10n.appTagline} · ${l10n.resultsCount(events.length)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: DataFreshnessLabel(),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: EventSearchField(),
          ),
          const FilterBar(padding: EdgeInsets.symmetric(horizontal: 20)),
          const SizedBox(height: 8),
          const Divider(),
          Expanded(
            child: eventsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(
                error: e,
                onRetry: () => ref.invalidate(approvedEventsProvider),
              ),
              data: (events) => events.isEmpty
                  ? EmptyState(
                      icon: Icons.search_off_rounded,
                      message: l10n.noResults,
                      action: TextButton(
                        onPressed: ref.read(filterProvider.notifier).reset,
                        child: Text(l10n.clearFilters),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(10),
                      itemCount: events.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 4),
                      itemBuilder: (context, i) => EventListTile(
                        event: events[i],
                        selected: events[i].id == selectedId,
                        onTap: () => onSelect(events[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

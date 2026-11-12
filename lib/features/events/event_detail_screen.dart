import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/launchers.dart';
import '../../core/widgets/common.dart';
import '../../data/models/culture_event.dart';
import '../../providers/providers.dart';
import '../map/map_layers.dart';
import 'event_widgets.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventByIdProvider(eventId));
    return eventAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          error: e,
          onRetry: () => ref.invalidate(eventByIdProvider(eventId)),
        ),
      ),
      data: (event) => event == null
          ? Scaffold(
              appBar: AppBar(),
              body: EmptyState(
                icon: Icons.event_busy_rounded,
                message: context.l10n.eventNotFound,
              ),
            )
          : _EventDetailView(event: event),
    );
  }
}

class _EventDetailView extends ConsumerWidget {
  const _EventDetailView({required this.event});

  final CultureEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isAdmin = ref.watch(profileProvider).value?.isAdmin ?? false;
    final wide = context.isWide;

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            CategoryBadge(category: event.category),
            if (event.isCourse)
              InfoPill(
                label: l10n.kindCourse,
                color: const Color(0xFF1F2937),
                icon: Icons.school_rounded,
              ),
            if (event.status != EventStatus.approved) StatusPill(status: event.status),
          ],
        ),
        const SizedBox(height: 12),
        Text(event.title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 20),
        _InfoTile(
          icon: event.isCourse ? Icons.event_repeat_rounded : Icons.calendar_month_rounded,
          title: event.isCourse ? l10n.schedule : l10n.dateTime,
          value: [
            if (event.isCourse && (event.schedule?.isNotEmpty ?? false)) event.schedule!,
            formatEventWhenLong(context, event),
          ].join('\n'),
          color: event.category.color,
        ),
        _InfoTile(
          icon: Icons.place_rounded,
          title: event.venueName ?? l10n.location,
          value: event.address ?? '',
          color: event.category.color,
        ),
        _InfoTile(
          icon: Icons.payments_rounded,
          title: l10n.price,
          value: event.isFree ? l10n.free : (event.price ?? '-'),
          color: event.category.color,
        ),
        if (event.organizer != null)
          _InfoTile(
            icon: Icons.groups_rounded,
            title: l10n.organizer,
            value: event.organizer!,
            color: event.category.color,
          ),
        if (event.contact != null)
          _InfoTile(
            icon: Icons.call_rounded,
            title: l10n.contact,
            value: event.contact!,
            color: event.category.color,
            onTap: contactUri(event.contact!) == null
                ? null
                : () => launchUrl(contactUri(event.contact!)!),
          ),
        if (event.isImported)
          _InfoTile(
            icon: Icons.verified_rounded,
            title: '${l10n.source}: ${event.sourceName}',
            value: event.sourceUrl == null ? '' : l10n.openSource,
            color: event.category.color,
            onTap: event.sourceUrl == null
                ? null
                : () => launchUrl(
                      Uri.parse(event.sourceUrl!),
                      mode: LaunchMode.externalApplication,
                    ),
          ),
        if (event.description.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(l10n.about, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          SelectableText(
            event.description,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
          ),
        ],
        if (isAdmin && event.status == EventStatus.pending) ...[
          const SizedBox(height: 24),
          _AdminActions(event: event),
        ],
      ],
    );

    final mapSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: wide ? 320 : 220,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: event.point,
                initialZoom: 15.5,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom |
                      InteractiveFlag.drag |
                      InteractiveFlag.scrollWheelZoom,
                ),
              ),
              children: [
                baseTileLayer(context),
                MarkerLayer(markers: [
                  Marker(
                    point: event.point,
                    width: 60,
                    height: 60,
                    child: Center(child: EventMarker(event: event, selected: true)),
                  ),
                ]),
                mapAttribution(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => openDirections(event),
          icon: const Icon(Icons.directions_rounded),
          label: Text(l10n.getDirections),
        ),
        if (event.status == EventStatus.approved) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              ref.read(selectedEventIdProvider.notifier).select(event.id);
              context.go('/');
            },
            icon: const Icon(Icons.map_rounded),
            label: Text(l10n.viewOnMap),
          ),
        ],
      ],
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: wide ? 360 : 280,
            leading: Padding(
              padding: const EdgeInsets.all(6),
              child: IconButton.filledTonal(
                onPressed: () => context.canPop() ? context.pop() : context.go('/'),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            actions: [
              FavoriteButton(eventId: event.id, onImage: true),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'event-image-${event.id}',
                child: EventImage(event: event, iconSize: 72),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ConstrainedContent(
              maxWidth: 1100,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: details),
                          const SizedBox(width: 32),
                          Expanded(flex: 2, child: mapSection),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [details, const SizedBox(height: 24), mapSection],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  if (value.isNotEmpty)
                    Text(
                      value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: onTap != null
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminActions extends ConsumerWidget {
  const _AdminActions({required this.event});

  final CultureEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    Future<void> setStatus(EventStatus status) async {
      try {
        await ref.read(eventRepositoryProvider).setStatus(event.id, status);
        refreshEventLists(ref);
        if (context.mounted) {
          showSnack(
            context,
            status == EventStatus.approved ? l10n.eventApproved : l10n.eventRejected,
          );
        }
      } catch (e) {
        if (context.mounted) showSnack(context, l10n.errorGeneric('$e'));
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.adminPanel, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => setStatus(EventStatus.approved),
                    icon: const Icon(Icons.check_rounded),
                    label: Text(l10n.approve),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setStatus(EventStatus.rejected),
                    icon: const Icon(Icons.close_rounded),
                    label: Text(l10n.reject),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

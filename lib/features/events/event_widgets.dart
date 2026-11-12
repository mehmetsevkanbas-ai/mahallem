import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../data/models/culture_event.dart';
import '../../data/models/event_category.dart';
import '../../providers/providers.dart';

/// Izgara ve yatay listelerde kullanılan büyük etkinlik kartı.
class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event, this.showStatus = false});

  final CultureEvent event;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Card(
      child: InkWell(
        onTap: () => context.push('/event/${event.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 160,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(tag: 'event-image-${event.id}', child: EventImage(event: event)),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: CategoryBadge(category: event.category, onImage: true),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: FavoriteButton(eventId: event.id, onImage: true),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 12,
                    child: Wrap(
                      spacing: 6,
                      children: [
                        if (showStatus) StatusPill(status: event.status),
                        if (event.isCourse)
                          InfoPill(
                            label: l10n.kindCourse,
                            color: const Color(0xFF1F2937),
                            icon: Icons.school_rounded,
                          ),
                        if (event.isFree)
                          InfoPill(label: l10n.free, color: const Color(0xFF2E9D5B)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(height: 1.25),
                    ),
                    const Spacer(),
                    _MetaRow(
                      icon: Icons.schedule_rounded,
                      text: formatEventWhen(context, event),
                      color: event.category.color,
                    ),
                    const SizedBox(height: 4),
                    _MetaRow(
                      icon: Icons.place_outlined,
                      text: event.venueName ?? event.address ?? '',
                    ),
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

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color == null ? muted : theme.colorScheme.onSurface,
              fontWeight: color == null ? FontWeight.w500 : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// Yan panel ve profil listeleri için kompakt satır.
class EventListTile extends StatelessWidget {
  const EventListTile({
    super.key,
    required this.event,
    this.selected = false,
    this.onTap,
    this.trailing,
    this.showStatus = false,
  });

  final CultureEvent event;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: selected
          ? scheme.primaryContainer.withValues(alpha: 0.55)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap ?? () => context.push('/event/${event.id}'),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: EventImage(event: event, iconSize: 26),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _MetaRow(
                      icon: Icons.schedule_rounded,
                      text: formatEventWhen(context, event),
                      color: event.category.color,
                    ),
                    const SizedBox(height: 2),
                    _MetaRow(
                      icon: Icons.place_outlined,
                      text: event.venueName ?? event.address ?? '',
                    ),
                    if (showStatus) ...[
                      const SizedBox(height: 6),
                      StatusPill(status: event.status),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// Favori kalp butonu. Giriş yapılmamışsa uyarı gösterir.
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, required this.eventId, this.onImage = false});

  final String eventId;
  final bool onImage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isFavorite =
        ref.watch(favoritesProvider).value?.contains(eventId) ?? false;
    final icon = Icon(
      isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      color: isFavorite
          ? const Color(0xFFE53958)
          : (onImage ? Colors.white : null),
    );

    Future<void> onPressed() async {
      if (ref.read(currentUserProvider) == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(l10n.loginRequiredFavorite),
            action: SnackBarAction(
              label: l10n.signIn,
              onPressed: () => context.push('/auth'),
            ),
          ));
        return;
      }
      try {
        await ref.read(favoritesProvider.notifier).toggle(eventId);
      } catch (e) {
        if (context.mounted) showSnack(context, l10n.errorGeneric('$e'));
      }
    }

    return IconButton(
      tooltip: isFavorite ? l10n.removeFromFavorites : l10n.addToFavorites,
      onPressed: onPressed,
      style: onImage
          ? IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.28),
            )
          : null,
      icon: icon,
    );
  }
}

/// Bir önerinin gerekçeleri: "✨ İlgi alanın: Müzik · Hafta sonu"
class ReasonLine extends StatelessWidget {
  const ReasonLine({super.key, required this.reasons, this.max = 2});

  final List<Reason> reasons;
  final int max;

  static String label(BuildContext context, Reason r) {
    final l10n = context.l10n;
    return switch (r.type) {
      ReasonType.interest => l10n.reasonInterest(r.category!.label(l10n)),
      ReasonType.favorites => l10n.reasonFavorites,
      ReasonType.near => l10n.reasonNear(r.km!.toStringAsFixed(r.km! < 10 ? 1 : 0)),
      ReasonType.time => l10n.reasonTime,
      ReasonType.free => l10n.free,
      ReasonType.kids => l10n.reasonKids,
      ReasonType.soon => l10n.reasonSoon,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (reasons.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.auto_awesome_rounded, size: 15, color: theme.colorScheme.secondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            reasons.take(max).map((r) => label(context, r)).join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// "Son güncelleme: ..." etiketi (belediye verisinin alındığı zaman).
class DataFreshnessLabel extends ConsumerWidget {
  const DataFreshnessLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updatedAt = ref.watch(dataUpdatedAtProvider).value;
    if (updatedAt == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sync_rounded, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              context.l10n.lastUpdated(formatFullDateTime(context, updatedAt)),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Arama kutusu (filtre durumuyla senkron).
class EventSearchField extends ConsumerStatefulWidget {
  const EventSearchField({super.key, this.elevated = false});

  final bool elevated;

  @override
  ConsumerState<EventSearchField> createState() => _EventSearchFieldState();
}

class _EventSearchFieldState extends ConsumerState<EventSearchField> {
  late final _controller =
      TextEditingController(text: ref.read(filterProvider).query);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(filterProvider.select((f) => f.query), (_, next) {
      if (next != _controller.text) _controller.text = next;
    });
    final scheme = Theme.of(context).colorScheme;
    final field = TextField(
      controller: _controller,
      onChanged: ref.read(filterProvider.notifier).setQuery,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: context.l10n.searchHint,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => _controller.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _controller.clear();
                    ref.read(filterProvider.notifier).setQuery('');
                  },
                ),
        ),
        fillColor: widget.elevated ? scheme.surface : null,
        enabledBorder: widget.elevated
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              )
            : null,
      ),
    );
    if (!widget.elevated) return field;
    return Material(
      elevation: 6,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      color: scheme.surface,
      child: field,
    );
  }
}

/// Kategori, tür ve tarih filtreleri.
class FilterBar extends ConsumerWidget {
  const FilterBar({
    super.key,
    this.showAllInline = false,
    this.onMap = false,
    this.padding = EdgeInsets.zero,
  });

  /// true ise tür ve tarih filtreleri de satır olarak gösterilir;
  /// false ise "filtre" butonundan açılan alt sayfada yer alır.
  final bool showAllInline;

  /// Harita üzerinde gösteriliyorsa çipler opak zemin alır.
  final bool onMap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(filterProvider);
    final notifier = ref.read(filterProvider.notifier);
    final interests = ref.watch(userInterestsProvider);
    final showForYou = ref.watch(currentUserProvider) != null &&
        (interests.isNotEmpty || !ref.watch(userPrefsProvider).isEmpty);
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final chipBg = onMap ? scheme.surface : null;
    final secondaryActive =
        filter.kind != KindFilter.all || filter.date != DateFilter.any;

    final categoryRow = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          if (!showAllInline) ...[
            Badge(
              isLabelVisible: secondaryActive,
              smallSize: 10,
              child: ActionChip(
                avatar: const Icon(Icons.tune_rounded, size: 18),
                label: Text(_dateLabel(context, filter.date)),
                backgroundColor: chipBg,
                onPressed: () => _openSheet(context),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (showForYou) ...[
            FilterChip(
              avatar: Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: filter.forYou ? scheme.onSecondary : scheme.secondary,
              ),
              label: Text(l10n.forYou),
              selected: filter.forYou,
              selectedColor: scheme.secondary,
              backgroundColor: chipBg,
              labelStyle: TextStyle(
                color: filter.forYou ? scheme.onSecondary : null,
                fontWeight: FontWeight.w700,
              ),
              onSelected: notifier.setForYou,
            ),
            const SizedBox(width: 8),
          ],
          for (final c in EventCategory.values) ...[
            FilterChip(
              avatar: Icon(
                c.icon,
                size: 18,
                color: filter.categories.contains(c) ? Colors.white : c.color,
              ),
              label: Text(c.label(l10n)),
              selected: filter.categories.contains(c),
              selectedColor: c.color,
              backgroundColor: chipBg,
              labelStyle: TextStyle(
                color: filter.categories.contains(c) ? Colors.white : null,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) => notifier.toggleCategory(c),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );

    if (!showAllInline) return categoryRow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        categoryRow,
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: padding,
          child: Row(
            children: [
              _KindSelector(value: filter.kind, onChanged: notifier.setKind),
              const SizedBox(width: 12),
              for (final d in DateFilter.values) ...[
                ChoiceChip(
                  label: Text(_dateLabel(context, d)),
                  selected: filter.date == d,
                  onSelected: (_) => notifier.setDate(d),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final filter = ref.watch(filterProvider);
          final notifier = ref.read(filterProvider.notifier);
          final l10n = context.l10n;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.fieldKind, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  _KindSelector(value: filter.kind, onChanged: notifier.setKind),
                  const SizedBox(height: 20),
                  Text(l10n.dateTime, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final d in DateFilter.values)
                        ChoiceChip(
                          label: Text(_dateLabel(context, d)),
                          selected: filter.date == d,
                          onSelected: (_) => notifier.setDate(d),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      TextButton(
                        onPressed: notifier.reset,
                        child: Text(l10n.clearFilters),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.pop(context),
                        style: FilledButton.styleFrom(minimumSize: const Size(120, 48)),
                        child: Text(l10n.ok),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

String _dateLabel(BuildContext context, DateFilter d) {
  final l10n = context.l10n;
  return switch (d) {
    DateFilter.any => l10n.dateAny,
    DateFilter.today => l10n.dateToday,
    DateFilter.thisWeek => l10n.dateThisWeek,
    DateFilter.weekend => l10n.dateWeekend,
    DateFilter.thisMonth => l10n.dateThisMonth,
  };
}

class _KindSelector extends StatelessWidget {
  const _KindSelector({required this.value, required this.onChanged});

  final KindFilter value;
  final ValueChanged<KindFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SegmentedButton<KindFilter>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact),
      segments: [
        ButtonSegment(value: KindFilter.all, label: Text(l10n.filterAll)),
        ButtonSegment(
          value: KindFilter.events,
          label: Text(l10n.kindEvents),
          icon: const Icon(Icons.event_rounded, size: 18),
        ),
        ButtonSegment(
          value: KindFilter.courses,
          label: Text(l10n.kindCourses),
          icon: const Icon(Icons.school_rounded, size: 18),
        ),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

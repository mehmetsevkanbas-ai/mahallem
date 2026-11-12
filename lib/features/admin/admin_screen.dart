import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/common.dart';
import '../../data/models/culture_event.dart';
import '../../providers/providers.dart';
import '../events/event_widgets.dart';

/// Kullanıcıların eklediği etkinlikleri onaylama / reddetme ekranı.
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final pending = ref.watch(pendingEventsProvider);

    Future<void> setStatus(CultureEvent e, EventStatus status) async {
      try {
        await ref.read(eventRepositoryProvider).setStatus(e.id, status);
        refreshEventLists(ref);
        if (context.mounted) {
          showSnack(
            context,
            status == EventStatus.approved ? l10n.eventApproved : l10n.eventRejected,
          );
        }
      } catch (err) {
        if (context.mounted) showSnack(context, l10n.errorGeneric('$err'));
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminPendingTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(pendingEventsProvider.future),
        child: pending.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorView(
            error: e,
            onRetry: () => ref.invalidate(pendingEventsProvider),
          ),
          data: (events) => events.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 80),
                    EmptyState(
                      icon: Icons.task_alt_rounded,
                      message: l10n.adminNoPending,
                    ),
                  ],
                )
              : ConstrainedContent(
                  maxWidth: 820,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: events.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final e = events[i];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              EventListTile(event: e),
                              if (e.description.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    e.description,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton.icon(
                                        onPressed: () => setStatus(e, EventStatus.approved),
                                        icon: const Icon(Icons.check_rounded),
                                        label: Text(l10n.approve),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => setStatus(e, EventStatus.rejected),
                                        icon: const Icon(Icons.close_rounded),
                                        label: Text(l10n.reject),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}

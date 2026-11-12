import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/common.dart';
import '../../data/models/culture_event.dart';
import '../../data/models/event_category.dart';
import '../../data/models/user_preferences.dart';
import '../../providers/providers.dart';
import '../shell/app_shell.dart';

/// Kayıttan sonra (ve profilden) açılan kısa soru akışı.
/// Yanıtlar kişisel önerilerde kullanılır.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _steps = 6;
  int _step = 0;
  bool _busy = false;
  bool _initialized = false;

  Set<EventCategory> _interests = {};
  UserPreferences _prefs = const UserPreferences();

  void _initFrom(WidgetRef ref) {
    if (_initialized) return;
    final profile = ref.read(profileProvider).value;
    if (profile == null) return;
    _interests = {...profile.interests};
    _prefs = profile.prefs;
    _initialized = true;
  }

  Future<void> _finish() async {
    setState(() => _busy = true);
    try {
      await ref.read(profileProvider.notifier).saveOnboarding(_interests, _prefs);
      if (!mounted) return;
      context.canPop() ? context.pop() : context.go('/events');
    } catch (e) {
      if (mounted) showSnack(context, context.l10n.errorGeneric('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _next() => _step == _steps - 1 ? _finish() : setState(() => _step++);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final profile = ref.watch(profileProvider);
    _initFrom(ref);

    final (title, hint, body) = switch (_step) {
      0 => (l10n.interestsTitle, l10n.interestsSubtitle, _interestsStep()),
      1 => (l10n.qKinds, null, _kindsStep()),
      2 => (l10n.qTime, l10n.qTimeHint, _timeStep()),
      3 => (l10n.qBudget, null, _budgetStep()),
      4 => (l10n.qCompany, null, _companyStep()),
      _ => (l10n.qArea, l10n.qAreaHint, _areaStep()),
    };

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const AppLogo(size: 32),
        actions: [
          TextButton(
            onPressed: _busy ? null : _finish,
            child: Text(l10n.interestsSkip),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: profile.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ConstrainedContent(
                maxWidth: 720,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: (_step + 1) / _steps,
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(l10n.stepOf(_step + 1, _steps), style: theme.textTheme.labelLarge),
                        ],
                      ),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: ListView(
                          key: ValueKey(_step),
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                          children: [
                            if (_step == 0) ...[
                              Text(l10n.onboardingTitle,
                                  style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
                              const SizedBox(height: 4),
                            ],
                            Text(title, style: theme.textTheme.headlineSmall),
                            if (hint != null) ...[
                              const SizedBox(height: 6),
                              Text(hint,
                                  style: theme.textTheme.bodyLarge
                                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            ],
                            const SizedBox(height: 20),
                            body,
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                      child: Row(
                        children: [
                          if (_step > 0) ...[
                            OutlinedButton(
                              onPressed: _busy ? null : () => setState(() => _step--),
                              child: Text(l10n.back),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: FilledButton(
                              onPressed: _busy || (_step == 0 && _interests.isEmpty) ? null : _next,
                              child: _busy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2.5),
                                    )
                                  : Text(_step == _steps - 1 ? l10n.finish : l10n.next),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // --- Adımlar ---------------------------------------------------------------

  Widget _interestsStep() => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          mainAxisExtent: 110,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: EventCategory.values.length,
        itemBuilder: (context, i) {
          final c = EventCategory.values[i];
          return _InterestTile(
            category: c,
            selected: _interests.contains(c),
            onTap: () => setState(() {
              _interests.contains(c) ? _interests.remove(c) : _interests.add(c);
            }),
          );
        },
      );

  Widget _kindsStep() {
    final l10n = context.l10n;
    final kinds = _prefs.kinds;
    void set(Set<EventKind> v) => setState(() => _prefs = _prefs.copyWith(kinds: v));
    return Column(children: [
      _OptionCard(
        icon: Icons.event_rounded,
        title: l10n.kindEvents,
        subtitle: l10n.kindsEventsDesc,
        selected: kinds.length == 1 && kinds.contains(EventKind.event),
        onTap: () => set({EventKind.event}),
      ),
      _OptionCard(
        icon: Icons.school_rounded,
        title: l10n.kindCourses,
        subtitle: l10n.kindsCoursesDesc,
        selected: kinds.length == 1 && kinds.contains(EventKind.course),
        onTap: () => set({EventKind.course}),
      ),
      _OptionCard(
        icon: Icons.auto_awesome_rounded,
        title: l10n.kindsBoth,
        selected: kinds.isEmpty || kinds.length == 2,
        onTap: () => set({}),
      ),
    ]);
  }

  Widget _timeStep() {
    final l10n = context.l10n;
    final slots = _prefs.timeSlots;
    void toggle(TimeSlot t) => setState(() {
          final next = {...slots};
          next.contains(t) ? next.remove(t) : next.add(t);
          _prefs = _prefs.copyWith(timeSlots: next);
        });
    return Column(children: [
      for (final (slot, icon, label) in [
        (TimeSlot.weekdayDay, Icons.wb_sunny_rounded, l10n.timeWeekdayDay),
        (TimeSlot.weekdayEvening, Icons.nights_stay_rounded, l10n.timeWeekdayEvening),
        (TimeSlot.weekend, Icons.weekend_rounded, l10n.timeWeekend),
      ])
        _OptionCard(
          icon: icon,
          title: label,
          selected: slots.contains(slot),
          multi: true,
          onTap: () => toggle(slot),
        ),
    ]);
  }

  Widget _budgetStep() {
    final l10n = context.l10n;
    return Column(children: [
      _OptionCard(
        icon: Icons.volunteer_activism_rounded,
        title: l10n.budgetFreeOnly,
        selected: _prefs.freeOnly,
        onTap: () => setState(() => _prefs = _prefs.copyWith(freeOnly: true)),
      ),
      _OptionCard(
        icon: Icons.confirmation_number_rounded,
        title: l10n.budgetAny,
        selected: !_prefs.freeOnly,
        onTap: () => setState(() => _prefs = _prefs.copyWith(freeOnly: false)),
      ),
    ]);
  }

  Widget _companyStep() {
    final l10n = context.l10n;
    return Column(children: [
      _OptionCard(
        icon: Icons.people_alt_rounded,
        title: l10n.companyAdults,
        selected: !_prefs.withKids,
        onTap: () => setState(() => _prefs = _prefs.copyWith(withKids: false)),
      ),
      _OptionCard(
        icon: Icons.family_restroom_rounded,
        title: l10n.companyKids,
        selected: _prefs.withKids,
        onTap: () => setState(() => _prefs = _prefs.copyWith(withKids: true)),
      ),
    ]);
  }

  Widget _areaStep() {
    final l10n = context.l10n;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          avatar: const Icon(Icons.public_rounded, size: 18),
          label: Text(l10n.areaAny),
          selected: _prefs.areaId == null,
          onSelected: (_) => setState(() => _prefs = _prefs.copyWith(clearArea: true)),
        ),
        for (final a in homeAreas)
          ChoiceChip(
            avatar: const Icon(Icons.place_rounded, size: 18),
            label: Text(a.name),
            selected: _prefs.areaId == a.id,
            onSelected: (_) => setState(() => _prefs = _prefs.copyWith(areaId: a.id)),
          ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.multi = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final bool multi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer.withValues(alpha: 0.7) : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: scheme.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleMedium),
                        if (subtitle != null)
                          Text(subtitle!,
                              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Icon(
                    selected
                        ? (multi ? Icons.check_box_rounded : Icons.radio_button_checked_rounded)
                        : (multi ? Icons.check_box_outline_blank_rounded : Icons.radio_button_off_rounded),
                    color: selected ? scheme.primary : scheme.outline,
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

class _InterestTile extends StatelessWidget {
  const _InterestTile({required this.category, required this.selected, required this.onTap});

  final EventCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = category.color;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? color : theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? color : theme.colorScheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(category.icon, size: 28, color: selected ? Colors.white : color),
                  const Spacer(),
                  if (selected) const Icon(Icons.check_circle_rounded, color: Colors.white),
                ]),
                const Spacer(),
                Text(
                  category.label(context.l10n),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : null,
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

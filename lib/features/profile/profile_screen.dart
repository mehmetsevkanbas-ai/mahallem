import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/models/culture_event.dart';
import '../../data/models/user_preferences.dart';
import '../../data/models/user_profile.dart';
import '../../providers/providers.dart';
import '../events/event_widgets.dart';
import '../shell/app_shell.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(profileProvider);
    final isDemo = ref.watch(isDemoModeProvider);

    return Scaffold(
      body: SafeArea(
        child: ConstrainedContent(
          maxWidth: 820,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            children: [
              const MobileBrandBar(),
              if (isDemo) ...[const _DemoBanner(), const SizedBox(height: 16)],
              if (user == null)
                const _GuestCard()
              else
                profile.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => ErrorView(
                    error: e,
                    onRetry: () => ref.invalidate(profileProvider),
                  ),
                  data: (p) => p == null
                      ? const SizedBox.shrink()
                      : _UserSections(profile: p, email: user.email),
                ),
              const SizedBox(height: 24),
              const _SettingsCard(),
              const _AboutCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.science_rounded, color: scheme.onTertiaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.demoModeBanner,
              style: TextStyle(color: scheme.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestCard extends StatelessWidget {
  const _GuestCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.sea, Color(0xFF16B3A6), AppColors.sunset],
          stops: [0, 0.6, 1],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.favorite_rounded, color: Colors.white, size: 36),
          const SizedBox(height: 12),
          Text(
            l10n.guestTitle,
            style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.guestBody,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => context.push('/auth'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.sea,
              minimumSize: const Size(180, 50),
            ),
            child: Text('${l10n.signIn} / ${l10n.signUp}'),
          ),
        ],
      ),
    );
  }
}

class _UserSections extends ConsumerWidget {
  const _UserSections({required this.profile, required this.email});

  final UserProfile profile;
  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final name = profile.displayName.isEmpty ? email : profile.displayName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                name.characters.first.toUpperCase(),
                style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: theme.textTheme.titleLarge),
                  Text(
                    email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (profile.isAdmin) ...[
          const SizedBox(height: 16),
          const _AdminEntry(),
        ],
        const SizedBox(height: 24),
        _Section(
          title: l10n.myPreferences,
          trailing: TextButton.icon(
            onPressed: () => context.push('/onboarding'),
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: Text(l10n.editPreferences),
          ),
          child: _PreferencesSummary(profile: profile),
        ),
        _AsyncEventSection(
          title: l10n.favorites,
          provider: favoriteEventsProvider,
          emptyText: l10n.noFavorites,
          emptyIcon: Icons.favorite_border_rounded,
        ),
        _AsyncEventSection(
          title: l10n.myEvents,
          provider: myEventsProvider,
          emptyText: l10n.noMyEvents,
          emptyIcon: Icons.add_location_alt_outlined,
          showStatus: true,
          action: FilledButton.tonalIcon(
            onPressed: () => context.go('/add'),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.addEventTitle),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => ref.read(authRepositoryProvider).signOut(),
          icon: const Icon(Icons.logout_rounded),
          label: Text(l10n.signOut),
        ),
      ],
    );
  }
}

class _PreferencesSummary extends StatelessWidget {
  const _PreferencesSummary({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final prefs = profile.prefs;
    final scheme = Theme.of(context).colorScheme;

    Widget pill(IconData icon, String text) => Chip(
          avatar: Icon(icon, size: 16, color: scheme.primary),
          label: Text(text),
          visualDensity: VisualDensity.compact,
        );

    final kinds = prefs.kinds.length == 1
        ? (prefs.kinds.first == EventKind.course ? l10n.kindCourses : l10n.kindEvents)
        : l10n.kindsBoth;
    final slots = {
      TimeSlot.weekdayDay: l10n.timeWeekdayDay,
      TimeSlot.weekdayEvening: l10n.timeWeekdayEvening,
      TimeSlot.weekend: l10n.timeWeekend,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (profile.interests.isEmpty)
          Text(l10n.noInterests)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final c in profile.interests) CategoryBadge(category: c)],
          ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            pill(Icons.event_note_rounded, kinds),
            for (final t in prefs.timeSlots) pill(Icons.schedule_rounded, slots[t]!),
            pill(prefs.freeOnly ? Icons.volunteer_activism_rounded : Icons.confirmation_number_rounded,
                prefs.freeOnly ? l10n.budgetFreeOnly : l10n.budgetAny),
            if (prefs.withKids) pill(Icons.family_restroom_rounded, l10n.companyKids),
            pill(Icons.place_rounded, prefs.area?.name ?? l10n.areaAny),
          ],
        ),
      ],
    );
  }
}

class _AdminEntry extends ConsumerWidget {
  const _AdminEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingEventsProvider).value?.length ?? 0;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(Icons.admin_panel_settings_rounded, color: scheme.onSecondaryContainer),
        title: Text(
          context.l10n.adminPanel,
          style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSecondaryContainer),
        ),
        subtitle: Text(context.l10n.pendingCount(pending)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push('/admin'),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: Theme.of(context).textTheme.titleLarge),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      );
}

class _AsyncEventSection extends ConsumerWidget {
  const _AsyncEventSection({
    required this.title,
    required this.provider,
    required this.emptyText,
    required this.emptyIcon,
    this.showStatus = false,
    this.action,
  });

  final String title;
  final FutureProvider<List<CultureEvent>> provider;
  final String emptyText;
  final IconData emptyIcon;
  final bool showStatus;
  final Widget? action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);
    return _Section(
      title: title,
      child: async.when(
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(provider)),
        data: (events) => events.isEmpty
            ? Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: EmptyState(icon: emptyIcon, message: emptyText, action: action),
                ),
              )
            : Card(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    children: [
                      for (final e in events)
                        EventListTile(event: e, showStatus: showStatus),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _SettingsCard extends ConsumerWidget {
  const _SettingsCard();

  static const _languageNames = {
    'tr': 'Türkçe',
    'en': 'English',
    'ru': 'Русский',
    'de': 'Deutsch',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final currentLang = Localizations.localeOf(context).languageCode;
    final themeMode = ref.watch(themeModeProvider);

    return _Section(
      title: l10n.settings,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.language, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final code in supportedLanguageCodes)
                    ChoiceChip(
                      label: Text(_languageNames[code]!),
                      selected: currentLang == code,
                      onSelected: (_) =>
                          ref.read(localeProvider.notifier).set(Locale(code)),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(l10n.theme, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(l10n.themeSystem),
                    icon: const Icon(Icons.brightness_auto_rounded),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(l10n.themeLight),
                    icon: const Icon(Icons.light_mode_rounded),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(l10n.themeDark),
                    icon: const Icon(Icons.dark_mode_rounded),
                  ),
                ],
                selected: {themeMode},
                onSelectionChanged: (s) =>
                    ref.read(themeModeProvider.notifier).set(s.first),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Uygulama, proje ekibi ve veri kaynakları hakkında bilgi.
class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    Widget row(IconData icon, String title, String body) => Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(body, style: theme.textTheme.bodyMedium?.copyWith(color: muted)),
                  ],
                ),
              ),
            ],
          ),
        );

    return _Section(
      title: l10n.about,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppLogo(size: 44),
              const SizedBox(height: 12),
              Text(l10n.aboutApp, style: theme.textTheme.bodyMedium),
              row(Icons.groups_rounded, l10n.creditsTitle, l10n.creditsDeveloper),
              row(Icons.school_rounded, 'Hüseyin Girenes Fen Lisesi', l10n.creditsSchool),
              row(Icons.public_rounded, l10n.dataSourcesTitle, l10n.dataSourcesBody),
            ],
          ),
        ),
      ),
    );
  }
}

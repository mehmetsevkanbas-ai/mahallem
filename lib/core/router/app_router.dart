import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/add_event/add_event_screen.dart';
import '../../features/admin/admin_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/events/event_detail_screen.dart';
import '../../features/events/events_screen.dart';
import '../../features/map/map_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../providers/providers.dart';

const _protectedPaths = {'/add', '/onboarding', '/admin'};

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(currentUserProvider, (_, _) => refresh.value++);
  ref.listen(profileProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final user = ref.read(currentUserProvider);
      final location = state.matchedLocation;

      if (user == null) {
        if (_protectedPaths.contains(location)) {
          return '/auth?from=${Uri.encodeComponent(location)}';
        }
        return null;
      }

      if (location == '/auth') {
        return state.uri.queryParameters['from'] ?? '/';
      }

      final profile = ref.read(profileProvider).value;
      if (profile != null) {
        // Yeni kullanıcıyı bir kez ilgi alanı seçimine yönlendir.
        if (!profile.onboarded && location != '/onboarding') {
          return '/onboarding';
        }
        if (location == '/admin' && !profile.isAdmin) return '/';
      }
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (_, _) => const MapScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/events', builder: (_, _) => const EventsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/add', builder: (_, _) => const AddEventScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
          ]),
        ],
      ),
      GoRoute(
        path: '/event/:id',
        builder: (_, state) =>
            EventDetailScreen(eventId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/auth', builder: (_, _) => const AuthScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/admin', builder: (_, _) => const AdminScreen()),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

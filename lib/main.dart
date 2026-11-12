import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'data/repositories/local_repositories.dart';
import 'data/repositories/repositories.dart';
import 'data/repositories/supabase_repositories.dart';
import 'providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  final prefs = await SharedPreferences.getInstance();

  // Yazı tipi ilk çizimden önce yüklensin; aksi halde çip gibi bileşenler
  // geçici yazı tipine göre ölçülüp metni kırpabiliyor.
  await GoogleFonts.pendingFonts([
    for (final w in [FontWeight.w400, FontWeight.w500, FontWeight.w600, FontWeight.w700, FontWeight.w800])
      GoogleFonts.manrope(fontWeight: w),
  ]).timeout(const Duration(seconds: 3), onTimeout: () => const []);

  final AuthRepository authRepository;
  final EventRepository eventRepository;

  if (Env.useSupabase) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabasePublishableKey,
    );
    final client = Supabase.instance.client;
    authRepository = SupabaseAuthRepository(client);
    eventRepository = SupabaseEventRepository(client);
  } else {
    // Yerel mod: belediye sitelerinden alınmış son veri anlık görüntüsü.
    final store = await LocalStore.loadSnapshot();
    authRepository = LocalAuthRepository(store);
    eventRepository = LocalEventRepository(store, authRepository);
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(authRepository),
        eventRepositoryProvider.overrideWithValue(eventRepository),
      ],
      child: const MahallemApp(),
    ),
  );
}

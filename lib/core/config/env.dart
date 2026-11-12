import 'package:latlong2/latlong.dart';

/// Derleme zamanı ortam değişkenleri.
///
/// `flutter run --dart-define-from-file=env.json` ile verilir.
/// Değerler boşsa uygulama demo modunda (bellek içi veriyle) çalışır.
class Env {
  const Env._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get useSupabase =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  /// Harita karo adresi. Trafik artarsa MapTiler, Stadia vb. bir sağlayıcının
  /// anahtarlı adresi `MAP_TILE_URL` ile verilebilir.
  static const mapTileUrl = String.fromEnvironment(
    'MAP_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  /// Pilot şehir: Alanya merkezi.
  static const cityCenter = LatLng(36.5470, 32.0010);
  static const cityZoom = 13.5;
  static const cityName = 'Alanya';
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/env.dart';
import '../../data/models/culture_event.dart';

/// Altlık harita. Varsayılan: OpenStreetMap karoları (ücretsiz, API anahtarı gerekmez).
/// Koyu temada karolar renk filtresiyle koyulaştırılır.
TileLayer baseTileLayer(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return TileLayer(
    urlTemplate: Env.mapTileUrl,
    userAgentPackageName: 'com.mahallem.mahallem',
    maxZoom: 19,
    tileBuilder: isDark ? darkModeTileBuilder : null,
  );
}

Widget mapAttribution() => RichAttributionWidget(
      alignment: AttributionAlignment.bottomLeft,
      attributions: [
        TextSourceAttribution(
          'OpenStreetMap contributors',
          onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
        ),
      ],
    );

/// Kategori renginde harita işareti. Kurslar yuvarlatılmış kare ile ayrışır.
class EventMarker extends StatelessWidget {
  const EventMarker({super.key, required this.event, this.selected = false});

  final CultureEvent event;
  final bool selected;

  static const size = 44.0;
  static const selectedSize = 56.0;

  @override
  Widget build(BuildContext context) {
    final color = event.category.color;
    final s = selected ? selectedSize : size;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      width: s,
      height: s,
      decoration: BoxDecoration(
        color: color,
        shape: event.isCourse ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: event.isCourse ? BorderRadius.circular(s * 0.3) : null,
        border: Border.all(color: Colors.white, width: selected ? 4 : 3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: selected ? 0.55 : 0.35),
            blurRadius: selected ? 16 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(event.category.icon, color: Colors.white, size: s * 0.48),
    );
  }
}

/// Aynı noktadaki birden fazla kayıt için sayılı işaret.
/// Hepsi aynı kategorideyse o rengi, değilse uygulama rengini alır;
/// hepsi kurssa kurs işaretleri gibi köşeli çizilir.
class StackMarker extends StatelessWidget {
  const StackMarker({super.key, required this.events, this.selected = false});

  final List<CultureEvent> events;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final categories = events.map((e) => e.category).toSet();
    final color = categories.length == 1
        ? categories.first.color
        : Theme.of(context).colorScheme.primary;
    final allCourses = events.every((e) => e.isCourse);
    final s = selected ? EventMarker.selectedSize : EventMarker.size + 4;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Arkadaki "kart destesi" gölgesi, çoklu kaydı hissettirir.
        Transform.translate(
          offset: const Offset(3, -3),
          child: _shape(color.withValues(alpha: 0.45), s, allCourses, border: 2),
        ),
        _shape(
          color,
          s,
          allCourses,
          child: Text(
            '${events.length}',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: s * 0.36,
            ),
          ),
        ),
      ],
    );
  }

  Widget _shape(Color color, double s, bool square, {Widget? child, double border = 3}) =>
      Container(
        width: s,
        height: s,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: square ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: square ? BorderRadius.circular(s * 0.3) : null,
          border: Border.all(color: Colors.white, width: border),
          boxShadow: child == null
              ? null
              : [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: child,
      );
}

/// Konum seçici ve detay sayfası için basit işaret.
class PinMarker extends StatelessWidget {
  const PinMarker({super.key, required this.color, this.icon});

  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
              ],
            ),
            child: Icon(icon ?? Icons.place_rounded, color: Colors.white, size: 20),
          ),
          Container(width: 3, height: 12, color: color),
        ],
      );
}

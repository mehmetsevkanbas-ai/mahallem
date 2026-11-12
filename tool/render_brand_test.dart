// Marka SVG'lerini uygulama ikonları için 1024x1024 PNG'ye dönüştürür.
//
// Çalıştırma:
//   flutter test tool/render_brand_test.dart
//   dart run flutter_launcher_icons
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

// (kaynak svg, çıktı png, piksel boyutu)
const _files = [
  ('mahallem_icon', 'icon.png', 1024),
  ('mahallem_icon_square', 'icon_square.png', 1024),
  ('mahallem_foreground', 'foreground.png', 1024),
  ('mahallem_background', 'background.png', 1024),
  // Yerel açılış ekranı: logo (4x yoğunlukta 160dp) ve Android 12 simgesi.
  ('mahallem_icon', 'splash_logo.png', 640),
  ('mahallem_foreground', 'splash_android12.png', 1152),
];

void main() {
  test('marka PNG dosyalarını üret', () async {
    final outDir = Directory('assets/brand/png')..createSync(recursive: true);
    for (final (name, out, size) in _files) {
      final svg = File('assets/brand/$name.svg').readAsStringSync();
      final info = await vg.loadPicture(SvgStringLoader(svg), null);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.scale(size / info.size.width, size / info.size.height);
      canvas.drawPicture(info.picture);
      final picture = recorder.endRecording();

      final image = await picture.toImage(size, size);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('${outDir.path}/$out')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
      info.picture.dispose();
      picture.dispose();
      image.dispose();
    }
  });
}

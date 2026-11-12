import 'package:url_launcher/url_launcher.dart';

import '../../data/models/culture_event.dart';

Future<void> openDirections(CultureEvent e) => launchUrl(
      Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${e.lat},${e.lng}',
      ),
      mode: LaunchMode.externalApplication,
    );

/// İletişim metnini (telefon, web adresi, e-posta) tıklanabilir bağlantıya çevirir.
Uri? contactUri(String contact) {
  final value = contact.trim();
  final digits = value.replaceAll(RegExp(r'[^0-9+]'), '');
  if (value.contains('@') && !value.contains('/')) {
    return Uri(scheme: 'mailto', path: value);
  }
  if (digits.length >= 10 && digits.length >= value.replaceAll(' ', '').length - 2) {
    return Uri(scheme: 'tel', path: digits);
  }
  if (value.contains('.') && !value.contains(' ')) {
    return Uri.parse(value.startsWith('http') ? value : 'https://$value');
  }
  return null;
}

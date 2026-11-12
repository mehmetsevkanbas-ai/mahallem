import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/models/culture_event.dart';
import '../../data/models/event_category.dart';
import '../../l10n/app_localizations.dart';

/// Ekran genişliği eşikleri.
class Breakpoints {
  const Breakpoints._();

  static const medium = 840.0;
  static const large = 1200.0;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  bool get isWide => screenWidth >= Breakpoints.medium;
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// İçeriği geniş ekranlarda ortalayıp okunabilir genişlikte tutar.
class ConstrainedContent extends StatelessWidget {
  const ConstrainedContent({
    super.key,
    required this.child,
    this.maxWidth = 760,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}

/// Etkinlik görseli; görsel yoksa kategori renginde degrade gösterir.
class EventImage extends StatelessWidget {
  const EventImage({super.key, required this.event, this.iconSize = 48});

  final CultureEvent event;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final url = event.imageUrl;
    final placeholder = _CategoryPlaceholder(
      category: event.category,
      iconSize: iconSize,
    );
    if (url == null || url.isEmpty) return placeholder;
    if (url.startsWith('data:')) {
      return Image.memory(
        UriData.parse(url).contentAsBytes(),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      );
    }
    if (kIsWeb) {
      // Belediye görsel sunucuları CORS başlığı göndermiyor; web'de görsel
      // gerekirse tarayıcının kendi <img> öğesiyle gösterilir.
      return Image.network(
        url,
        fit: BoxFit.cover,
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        loadingBuilder: (_, child, progress) => progress == null ? child : placeholder,
        errorBuilder: (_, _, _) => placeholder,
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => placeholder,
    );
  }
}

class _CategoryPlaceholder extends StatelessWidget {
  const _CategoryPlaceholder({required this.category, required this.iconSize});

  final EventCategory category;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final c = category.color;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(c, Colors.white, 0.15)!,
            Color.lerp(c, Colors.black, 0.25)!,
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -iconSize * 0.4,
            bottom: -iconSize * 0.4,
            child: Icon(
              category.icon,
              size: iconSize * 2.6,
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          Center(
            child: Icon(category.icon, size: iconSize, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Kategori etiketi.
class CategoryBadge extends StatelessWidget {
  const CategoryBadge({
    super.key,
    required this.category,
    this.onImage = false,
  });

  final EventCategory category;

  /// Görselin üzerinde gösterilecekse beyaz zemin kullanılır.
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    final color = category.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: onImage
            ? Colors.white.withValues(alpha: 0.92)
            : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            category.label(context.l10n),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Color.lerp(color, Colors.black, 0.2),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

/// Küçük bilgi rozeti (Ücretsiz, Kurs, Onay bekliyor vb.).
class InfoPill extends StatelessWidget {
  const InfoPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      );
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final EventStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return switch (status) {
      EventStatus.pending => InfoPill(
          label: l10n.statusPending,
          color: const Color(0xFFE6A100),
          icon: Icons.hourglass_top_rounded,
        ),
      EventStatus.approved => InfoPill(
          label: l10n.statusApproved,
          color: const Color(0xFF2E9D5B),
          icon: Icons.check_rounded,
        ),
      EventStatus.rejected => InfoPill(
          label: l10n.statusRejected,
          color: const Color(0xFFD64545),
          icon: Icons.close_rounded,
        ),
    };
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: scheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.cloud_off_rounded,
        message: context.l10n.errorGeneric(error.toString()),
        action: onRetry == null
            ? null
            : FilledButton.tonal(
                onPressed: onRetry,
                child: Text(context.l10n.retry),
              ),
      );
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

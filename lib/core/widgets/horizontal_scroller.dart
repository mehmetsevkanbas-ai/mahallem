import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Bilgisayarda da kullanılabilen yatay kaydırma alanı.
///
/// Flutter web'de yatay listeler fareyle sürüklenemez ve dikey tekerlek
/// hareketi onları kaydırmaz; bu yüzden çip satırının sonuna ulaşılamıyordu.
/// Bu bileşen:
/// * fare ve dokunmatik yüzeyle sürüklemeyi açar,
/// * dikey tekerlek hareketini yatay kaydırmaya çevirir,
/// * geniş ekranda taşan yönde ok düğmeleri ve yumuşak kenar gölgesi gösterir.
class HorizontalScroller extends StatefulWidget {
  const HorizontalScroller({
    super.key,
    required this.builder,
    this.fadeColor,
    this.showArrows,
  });

  /// Verilen denetleyiciyi kullanan yatay kaydırılabilir öğeyi kurar.
  final Widget Function(BuildContext context, ScrollController controller)
  builder;

  /// Kenar gölgesinin rengi (varsayılan: yüzey rengi).
  final Color? fadeColor;

  /// Ok düğmeleri; varsayılan olarak yalnızca 600 px'ten geniş ekranlarda.
  final bool? showArrows;

  @override
  State<HorizontalScroller> createState() => _HorizontalScrollerState();
}

class _HorizontalScrollerState extends State<HorizontalScroller> {
  final _controller = ScrollController();
  bool _canBack = false;
  bool _canForward = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_sync);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_sync)
      ..dispose();
    super.dispose();
  }

  void _sync() {
    if (!_controller.hasClients) return;
    final p = _controller.position;
    final back = p.pixels > p.minScrollExtent + 1;
    final forward = p.pixels < p.maxScrollExtent - 1;
    if (back != _canBack || forward != _canForward) {
      setState(() {
        _canBack = back;
        _canForward = forward;
      });
    }
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_controller.hasClients) return;
    final p = _controller.position;
    if (p.maxScrollExtent <= 0) return;
    // Yatay hareket (dokunmatik yüzey, shift+tekerlek) varsa onu, yoksa dikey
    // tekerleği kullan. Liste sonuna gelince olayı bırak ki sayfa kaysın.
    final delta = event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs()
        ? event.scrollDelta.dx
        : event.scrollDelta.dy;
    if ((delta < 0 && !_canBack) || (delta > 0 && !_canForward)) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      final target = (p.pixels + delta).clamp(
        p.minScrollExtent,
        p.maxScrollExtent,
      );
      _controller.jumpTo(target);
    });
  }

  void _page(int direction) {
    if (!_controller.hasClients) return;
    final p = _controller.position;
    final step = math.max(160.0, p.viewportDimension * 0.7);
    _controller.animateTo(
      (p.pixels + direction * step).clamp(p.minScrollExtent, p.maxScrollExtent),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fade = widget.fadeColor ?? scheme.surface;
    final arrows = widget.showArrows ?? MediaQuery.sizeOf(context).width >= 600;

    final scrollable = NotificationListener<ScrollMetricsNotification>(
      onNotification: (_) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => mounted ? _sync() : null,
        );
        return false;
      },
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          scrollbars: false,
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus,
          },
        ),
        child: Listener(
          onPointerSignal: _onPointerSignal,
          child: widget.builder(context, _controller),
        ),
      ),
    );

    if (!arrows) return scrollable;

    return Stack(
      children: [
        scrollable,
        if (_canBack)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: _EdgeButton(
              icon: Icons.chevron_left_rounded,
              fade: fade,
              alignment: Alignment.centerLeft,
              tooltip: MaterialLocalizations.of(context).previousPageTooltip,
              onPressed: () => _page(-1),
            ),
          ),
        if (_canForward)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: _EdgeButton(
              icon: Icons.chevron_right_rounded,
              fade: fade,
              alignment: Alignment.centerRight,
              tooltip: MaterialLocalizations.of(context).nextPageTooltip,
              onPressed: () => _page(1),
            ),
          ),
      ],
    );
  }
}

class _EdgeButton extends StatelessWidget {
  const _EdgeButton({
    required this.icon,
    required this.fade,
    required this.alignment,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final Color fade;
  final Alignment alignment;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final left = alignment == Alignment.centerLeft;
    return Container(
      width: 56,
      alignment: alignment,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: left ? Alignment.centerLeft : Alignment.centerRight,
          end: left ? Alignment.centerRight : Alignment.centerLeft,
          colors: [
            fade,
            fade.withValues(alpha: 0.85),
            fade.withValues(alpha: 0),
          ],
          stops: const [0, 0.45, 1],
        ),
      ),
      child: Material(
        color: scheme.surfaceContainerHighest,
        shape: const CircleBorder(),
        elevation: 2,
        shadowColor: Colors.black26,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Tooltip(
            message: tooltip,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(icon, size: 22, color: scheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}

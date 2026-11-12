import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../core/config/env.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../data/models/culture_event.dart';
import '../../data/models/event_category.dart';
import '../../data/repositories/repositories.dart';
import '../../providers/providers.dart';
import '../map/map_layers.dart';
import '../shell/app_shell.dart';

/// Kullanıcının yeni etkinlik veya kurs eklediği form.
/// Gönderilen kayıtlar yönetici onayına düşer.
class AddEventScreen extends ConsumerStatefulWidget {
  const AddEventScreen({super.key});

  @override
  ConsumerState<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends ConsumerState<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _schedule = TextEditingController();
  final _venue = TextEditingController();
  final _address = TextEditingController();
  final _price = TextEditingController();
  final _organizer = TextEditingController();
  final _contact = TextEditingController();

  EventKind _kind = EventKind.event;
  EventCategory? _category;
  DateTime? _start;
  DateTime? _end;
  bool _isFree = true;
  LatLng? _location;
  PickedImage? _image;
  bool _busy = false;
  bool _submitted = false;

  List<TextEditingController> get _controllers => [
        _title, _description, _schedule, _venue,
        _address, _price, _organizer, _contact,
      ];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _reset() {
    _formKey.currentState?.reset();
    for (final c in _controllers) {
      c.clear();
    }
    setState(() {
      _kind = EventKind.event;
      _category = null;
      _start = null;
      _end = null;
      _isFree = true;
      _location = null;
      _image = null;
      _submitted = false;
    });
  }

  Future<DateTime?> _pickDateTime(DateTime? initial, {bool withTime = true}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year, now.month, now.day).subtract(
        Duration(days: _kind == EventKind.course ? 365 : 0),
      ),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return null;
    if (!withTime) return date;
    final time = await showTimePicker(
      context: context,
      initialTime: initial != null
          ? TimeOfDay.fromDateTime(initial)
          : const TimeOfDay(hour: 20, minute: 0),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 82,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final name = file.name.toLowerCase();
    final ext = name.contains('.') ? name.split('.').last : 'jpg';
    setState(() => _image = PickedImage(
          bytes: bytes,
          extension: const {'png', 'webp', 'gif'}.contains(ext) ? ext : 'jpg',
        ));
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    setState(() => _submitted = true);
    final formOk = _formKey.currentState!.validate();
    String? problem;
    if (_category == null) {
      problem = l10n.fieldCategory;
    } else if (_kind == EventKind.event && _start == null) {
      problem = l10n.startRequired;
    } else if (_location == null) {
      problem = l10n.locationRequired;
    }
    if (!formOk || problem != null) {
      if (problem != null) showSnack(context, problem);
      return;
    }

    final draft = EventDraft(
      title: _title.text.trim(),
      description: _description.text.trim(),
      category: _category!,
      kind: _kind,
      startAt: _start,
      endAt: _end,
      schedule: _kind == EventKind.course ? _schedule.text : null,
      lat: _location!.latitude,
      lng: _location!.longitude,
      venueName: _venue.text,
      address: _address.text,
      price: _price.text,
      isFree: _isFree,
      organizer: _organizer.text,
      contact: _contact.text,
    );

    setState(() => _busy = true);
    try {
      await ref.read(eventRepositoryProvider).create(draft, image: _image);
      refreshEventLists(ref);
      if (!mounted) return;
      _reset();
      setState(() => _busy = false);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.celebration_rounded, size: 44),
          title: Text(l10n.submitSuccessTitle),
          content: Text(l10n.submitSuccessBody, textAlign: TextAlign.center),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
      if (mounted) context.go('/profile');
    } catch (e) {
      if (mounted) showSnack(context, l10n.errorGeneric('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? l10n.errorRequired : null;

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ConstrainedContent(
            maxWidth: 760,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
              children: [
                const MobileBrandBar(),
                Text(l10n.addEventTitle, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  l10n.addEventSubtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // Görsel
                _ImagePickerBox(
                  image: _image,
                  category: _category,
                  onPick: _pickImage,
                  onRemove: () => setState(() => _image = null),
                ),
                const SizedBox(height: 24),

                // Tür
                SegmentedButton<EventKind>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: EventKind.event,
                      label: Text(l10n.kindEvent),
                      icon: const Icon(Icons.event_rounded),
                    ),
                    ButtonSegment(
                      value: EventKind.course,
                      label: Text(l10n.kindCourse),
                      icon: const Icon(Icons.school_rounded),
                    ),
                  ],
                  selected: {_kind},
                  onSelectionChanged: (s) => setState(() => _kind = s.first),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _title,
                  maxLength: 120,
                  decoration: InputDecoration(labelText: l10n.fieldTitle),
                  validator: (v) {
                    final r = required(v);
                    if (r != null) return r;
                    return v!.trim().length < 3 ? l10n.errorRequired : null;
                  },
                ),
                const SizedBox(height: 8),

                // Kategori
                Text(l10n.fieldCategory, style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in EventCategory.values)
                      ChoiceChip(
                        avatar: Icon(
                          c.icon,
                          size: 18,
                          color: _category == c ? Colors.white : c.color,
                        ),
                        label: Text(c.label(l10n)),
                        selected: _category == c,
                        selectedColor: c.color,
                        labelStyle: TextStyle(
                          color: _category == c ? Colors.white : null,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) => setState(() => _category = c),
                      ),
                  ],
                ),
                if (_submitted && _category == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 12),
                    child: Text(
                      l10n.errorRequired,
                      style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 20),

                // Tarih / program
                if (_kind == EventKind.course) ...[
                  TextFormField(
                    controller: _schedule,
                    decoration: InputDecoration(
                      labelText: l10n.fieldSchedule,
                      hintText: l10n.fieldScheduleHint,
                      prefixIcon: const Icon(Icons.event_repeat_rounded),
                    ),
                    validator: required,
                  ),
                  const SizedBox(height: 14),
                ],
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: l10n.fieldStart,
                        value: _start,
                        withTime: _kind == EventKind.event,
                        error: _submitted && _kind == EventKind.event && _start == null
                            ? l10n.errorRequired
                            : null,
                        onTap: () async {
                          final v = await _pickDateTime(
                            _start,
                            withTime: _kind == EventKind.event,
                          );
                          if (v != null) setState(() => _start = v);
                        },
                        onClear: () => setState(() => _start = null),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateField(
                        label: l10n.fieldEnd,
                        value: _end,
                        withTime: _kind == EventKind.event,
                        onTap: () async {
                          final v = await _pickDateTime(
                            _end ?? _start,
                            withTime: _kind == EventKind.event,
                          );
                          if (v != null) setState(() => _end = v);
                        },
                        onClear: () => setState(() => _end = null),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _description,
                  minLines: 3,
                  maxLines: 8,
                  maxLength: 2000,
                  decoration: InputDecoration(
                    labelText: l10n.fieldDescription,
                    alignLabelWithHint: true,
                  ),
                  validator: required,
                ),
                const SizedBox(height: 12),

                // Konum
                Text(l10n.pickLocation, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  l10n.pickLocationHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _submitted && _location == null
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                _LocationPicker(
                  value: _location,
                  color: _category?.color ?? theme.colorScheme.primary,
                  icon: _category?.icon,
                  onChanged: (p) => setState(() => _location = p),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _venue,
                  decoration: InputDecoration(
                    labelText: l10n.fieldVenue,
                    prefixIcon: const Icon(Icons.storefront_rounded),
                  ),
                  validator: required,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _address,
                  decoration: InputDecoration(
                    labelText: l10n.fieldAddress,
                    prefixIcon: const Icon(Icons.signpost_rounded),
                  ),
                ),
                const SizedBox(height: 20),

                // Ücret
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.fieldIsFree),
                  value: _isFree,
                  onChanged: (v) => setState(() => _isFree = v),
                ),
                if (!_isFree) ...[
                  TextFormField(
                    controller: _price,
                    decoration: InputDecoration(
                      labelText: l10n.fieldPrice,
                      hintText: l10n.fieldPriceHint,
                      prefixIcon: const Icon(Icons.payments_rounded),
                    ),
                    validator: required,
                  ),
                  const SizedBox(height: 14),
                ],
                const SizedBox(height: 6),
                TextFormField(
                  controller: _organizer,
                  decoration: InputDecoration(
                    labelText: l10n.fieldOrganizer,
                    prefixIcon: const Icon(Icons.groups_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _contact,
                  decoration: InputDecoration(
                    labelText: l10n.fieldContact,
                    prefixIcon: const Icon(Icons.call_rounded),
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _busy ? null : _submit,
                  icon: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(l10n.submitEvent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.withTime,
    required this.onTap,
    required this.onClear,
    this.error,
  });

  final String label;
  final DateTime? value;
  final bool withTime;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? context.l10n.selectDate
        : withTime
            ? formatFullDateTime(context, value!)
            : formatDay(context, value!);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: error,
          prefixIcon: const Icon(Icons.calendar_month_rounded),
          suffixIcon: value == null
              ? null
              : IconButton(icon: const Icon(Icons.close_rounded), onPressed: onClear),
        ),
        child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _LocationPicker extends StatelessWidget {
  const _LocationPicker({
    required this.value,
    required this.color,
    required this.onChanged,
    this.icon,
  });

  final LatLng? value;
  final Color color;
  final IconData? icon;
  final ValueChanged<LatLng> onChanged;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 300,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: value ?? Env.cityCenter,
              initialZoom: 14,
              onTap: (_, point) => onChanged(point),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              baseTileLayer(context),
              if (value != null)
                MarkerLayer(markers: [
                  Marker(
                    point: value!,
                    width: 44,
                    height: 56,
                    alignment: Alignment.topCenter,
                    child: PinMarker(color: color, icon: icon),
                  ),
                ]),
              mapAttribution(),
            ],
          ),
        ),
      );
}

class _ImagePickerBox extends StatelessWidget {
  const _ImagePickerBox({
    required this.image,
    required this.category,
    required this.onPick,
    required this.onRemove,
  });

  final PickedImage? image;
  final EventCategory? category;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 190,
        child: image == null
            ? Material(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                child: InkWell(
                  onTap: onPick,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_rounded,
                        size: 44,
                        color: category?.color ?? scheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.addImage, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(image!.bytes, fit: BoxFit.cover),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Row(
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: onPick,
                          style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: Text(l10n.changeImage),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: l10n.removeImage,
                          onPressed: onRemove,
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

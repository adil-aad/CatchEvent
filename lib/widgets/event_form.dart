import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/event_model.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import 'custom_button.dart';
import 'custom_text_field.dart';
import 'event_image.dart';

/// The shared create / edit event form.
///
/// Both `CreateEventScreen` and `EditEventScreen` render this, so the fields,
/// pickers and validation live in one place. Pass [initialEvent] to pre-fill
/// it for editing; leave it null to create.
///
/// The form assembles the [EventModel] itself — preserving the original
/// organizer and registered count when editing — and hands it to [onSubmit],
/// which returns an error message or null on success.
class EventForm extends StatefulWidget {
  final EventModel? initialEvent;
  final String submitLabel;
  final Future<String?> Function(EventModel event) onSubmit;

  const EventForm({
    super.key,
    this.initialEvent,
    required this.submitLabel,
    required this.onSubmit,
  });

  @override
  State<EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<EventForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _capacityController;
  late final TextEditingController _imageUrlController;
  final _dateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  late String _category;
  DateTime? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _isSubmitting = false;

  /// Preview of the pasted image URL, refreshed when the field loses focus.
  String _previewUrl = '';

  @override
  void initState() {
    super.initState();
    final event = widget.initialEvent;

    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController =
        TextEditingController(text: event?.description ?? '');
    _locationController = TextEditingController(text: event?.location ?? '');
    _capacityController = TextEditingController(
      text: event == null ? '' : event.capacity.toString(),
    );
    _imageUrlController = TextEditingController(text: event?.imageUrl ?? '');
    _previewUrl = event?.imageUrl ?? '';

    _category = event?.category ?? AppConstants.categories.first;

    if (event != null) {
      _date = DateTime.tryParse(event.date);
      _startTime = _parseTime(event.startTime);
      _endTime = _parseTime(event.endTime);
      if (_date != null) _dateController.text = _formatDateForDisplay(_date!);
      // The time fields are filled in didChangeDependencies — TimeOfDay.format
      // needs MaterialLocalizations, which is not available during initState.
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_startTime != null && _startTimeController.text.isEmpty) {
      _startTimeController.text = _startTime!.format(context);
    }
    if (_endTime != null && _endTimeController.text.isEmpty) {
      _endTimeController.text = _endTime!.format(context);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    _imageUrlController.dispose();
    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------- time helpers

  static TimeOfDay? _parseTime(String raw) {
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// `HH:mm`, the storage format from Project.md §16.
  static String _timeToStorage(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// `yyyy-MM-dd`, the storage format from Project.md §16.
  static String _dateToStorage(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

  static String _formatDateForDisplay(DateTime date) =>
      DateFormat('MMMM d, y').format(date);

  /// Minutes since midnight, for comparing start and end times.
  static int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;

  // ------------------------------------------------------------ pickers

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _date ?? now;
    final firstDate = DateTime(now.year - 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      _dateController.text = _formatDateForDisplay(picked);
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? _startTime : _endTime) ??
          const TimeOfDay(hour: 14, minute: 0),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
        _startTimeController.text = picked.format(context);
      } else {
        _endTime = picked;
        _endTimeController.text = picked.format(context);
      }
    });
  }

  // --------------------------------------------------------------- submit

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // The pickers are read-only fields, so their rules are checked here.
    if (_date == null || _startTime == null || _endTime == null) {
      _showMessage('Please choose a date, start time and end time.');
      return;
    }
    if (_minutes(_endTime!) <= _minutes(_startTime!)) {
      _showMessage('End time must be after the start time.');
      return;
    }

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final existing = widget.initialEvent;
    final event = EventModel(
      id: existing?.id ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      imageUrl: _imageUrlController.text.trim(),
      // Editing never reassigns ownership.
      organizerId: existing?.organizerId ?? user.uid,
      organizerName: existing?.organizerName ?? user.name,
      date: _dateToStorage(_date!),
      startTime: _timeToStorage(_startTime!),
      endTime: _timeToStorage(_endTime!),
      location: _locationController.text.trim(),
      capacity: int.parse(_capacityController.text.trim()),
      registeredCount: existing?.registeredCount ?? 0,
      createdAt: existing?.createdAt,
    );

    setState(() => _isSubmitting = true);
    final error = await widget.onSubmit(event);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (error != null) _showMessage(error);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CustomTextField(
            controller: _titleController,
            label: 'Title',
            prefixIcon: Icons.title,
            validator: (value) => Validators.required(value, 'Title'),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _descriptionController,
            label: 'Description',
            prefixIcon: Icons.notes,
            maxLines: 4,
            validator: (value) => Validators.required(value, 'Description'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: InputDecoration(
              labelText: 'Category',
              prefixIcon: const Icon(Icons.category_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: AppConstants.categories
                .map(
                  (category) => DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _category = value);
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _dateController,
            label: 'Date',
            hint: 'Choose a date',
            prefixIcon: Icons.calendar_today_outlined,
            readOnly: true,
            onTap: _pickDate,
            validator: (value) => Validators.required(value, 'Date'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _startTimeController,
                  label: 'Start Time',
                  prefixIcon: Icons.schedule_outlined,
                  readOnly: true,
                  onTap: () => _pickTime(isStart: true),
                  validator: (value) =>
                      Validators.required(value, 'Start time'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  controller: _endTimeController,
                  label: 'End Time',
                  prefixIcon: Icons.schedule_outlined,
                  readOnly: true,
                  onTap: () => _pickTime(isStart: false),
                  validator: (value) => Validators.required(value, 'End time'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _locationController,
            label: 'Location',
            prefixIcon: Icons.location_on_outlined,
            validator: (value) => Validators.required(value, 'Location'),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _capacityController,
            label: 'Maximum Participants',
            prefixIcon: Icons.groups_outlined,
            keyboardType: TextInputType.number,
            validator: Validators.capacity,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _imageUrlController,
            label: 'Event Image URL (optional)',
            hint: 'https://…',
            prefixIcon: Icons.image_outlined,
            keyboardType: TextInputType.url,
            validator: Validators.imageUrl,
            onChanged: (value) => setState(() => _previewUrl = value.trim()),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: EventImage(imageUrl: _previewUrl, height: 140),
          ),
          const SizedBox(height: 8),
          Text(
            'Paste a link to an image. Leave it empty to use a placeholder.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 28),
          CustomButton(
            label: widget.submitLabel,
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../models/event.dart';
import '../services/matrix_service.dart';
import 'map_picker_screen.dart';

class EventEditScreen extends StatefulWidget {
  final ProtestEvent? event; // If null, we are in "Add" mode

  const EventEditScreen({super.key, this.event});

  @override
  State<EventEditScreen> createState() => _EventEditScreenState();
}

class _EventEditScreenState extends State<EventEditScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _locationNameController;
  late TextEditingController _seriesController;
  
  // State
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late double _latitude;
  late double _longitude;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _titleController = TextEditingController(text: event?.title ?? '');
    _descController = TextEditingController(text: event?.description ?? '');
    _locationNameController = TextEditingController(text: event?.locationName ?? '');
    _seriesController = TextEditingController(text: event?.series ?? '');
    
    _latitude = event?.latitude ?? 44.4759;
    _longitude = event?.longitude ?? -73.2121;

    if (event != null) {
      _selectedDate = event.timestamp;
      _selectedTime = TimeOfDay.fromDateTime(event.timestamp);
    } else {
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationNameController.dispose();
    _seriesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _pickLocation() async {
    final LatLng? picked = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          initialLocation: LatLng(_latitude, _longitude),
        ),
      ),
    );

    if (picked != null) {
      setState(() {
        _latitude = picked.latitude;
        _longitude = picked.longitude;
      });
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final fullDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final newEvent = ProtestEvent(
        id: widget.event?.id ?? '', 
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        locationName: _locationNameController.text.trim(),
        series: _seriesController.text.trim().isEmpty ? null : _seriesController.text.trim(),
        timestamp: fullDateTime,
        latitude: _latitude, 
        longitude: _longitude,
        roomId: widget.event?.roomId,
      );

      await MatrixService.instance.saveProtestEvent(newEvent);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving to Matrix: $e')),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.event != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        title: Text(isEditing ? 'Edit Action' : 'New Action'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isSaving ? null : _saveEvent,
          )
        ],
      ),
      body: _isSaving 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFB71C1C)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _seriesController,
                      decoration: const InputDecoration(
                        labelText: 'Event Series (Optional, e.g. No Kings)',
                        border: OutlineInputBorder(),
                        helperText: "Group this event with others under a common movement name.",
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Event Title', border: OutlineInputBorder()),
                      validator: (val) => val!.isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationNameController,
                      decoration: const InputDecoration(labelText: 'Location Name', border: OutlineInputBorder()),
                      validator: (val) => val!.isEmpty ? 'Location is required' : null,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _pickLocation,
                      icon: const Icon(Icons.map, color: Color(0xFFB71C1C)),
                      label: Text("COORDINATES: ${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)}"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _selectDate,
                            child: Text(DateFormat('MMM d, y').format(_selectedDate)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _selectTime,
                            child: Text(_selectedTime.format(context)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      maxLines: 5,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                      validator: (val) => val!.isEmpty ? 'Description is required' : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveEvent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB71C1C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(isEditing ? 'Update Event' : 'Create Event'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

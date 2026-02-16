import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';

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
  
  // State
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize data from existing event OR set defaults for new event
    final event = widget.event;
    _titleController = TextEditingController(text: event?.title ?? '');
    _descController = TextEditingController(text: event?.description ?? '');
    _locationNameController = TextEditingController(text: event?.locationName ?? '');
    
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
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFB71C1C)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFB71C1C)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Combine Date and Time
      final fullDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final eventData = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'locationName': _locationNameController.text.trim(),
        'timestamp': Timestamp.fromDate(fullDateTime),
        // For now, we default to Burlington if it's a new event without coords
        // In the future, we can add a "Pick on Map" feature
        'latitude': widget.event?.latitude ?? 44.4759, 
        'longitude': widget.event?.longitude ?? -73.2121,
      };

      if (widget.event == null) {
        // ADD NEW
        await FirebaseFirestore.instance.collection('events').add(eventData);
      } else {
        // UPDATE EXISTING
        await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.event!.id)
            .update(eventData);
      }

      if (mounted) Navigator.pop(context); // Go back
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e')),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // Explicit Back Button
        ),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TITLE
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Event Title',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (val) => val!.isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // LOCATION NAME
                    TextFormField(
                      controller: _locationNameController,
                      decoration: const InputDecoration(
                        labelText: 'Location Name (e.g. City Hall)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.place),
                      ),
                      validator: (val) => val!.isEmpty ? 'Location is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // DATE & TIME ROW
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectDate,
                            icon: const Icon(Icons.calendar_today, color: Color(0xFFB71C1C)),
                            label: Text(DateFormat('MMM d, y').format(_selectedDate)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectTime,
                            icon: const Icon(Icons.access_time, color: Color(0xFFB71C1C)),
                            label: Text(_selectedTime.format(context)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // DESCRIPTION
                    TextFormField(
                      controller: _descController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Description / Plan',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      validator: (val) => val!.isEmpty ? 'Description is required' : null,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // BIG SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveEvent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB71C1C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
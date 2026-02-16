import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../screens/event_edit_screen.dart'; // Import the Edit Screen

class EventDetailsPanel extends StatelessWidget {
  final ProtestEvent event;

  const EventDetailsPanel({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Line
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 2. Title
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.bold, 
              color: Color(0xFFB71C1C)
            ),
          ),
          const SizedBox(height: 20),

          // 3. Info Row: Date & Time
          _buildInfoRow(
            Icons.calendar_today, 
            DateFormat('EEEE, MMMM d, y').format(event.timestamp),
            isBold: true
          ),
          _buildInfoRow(
            Icons.access_time, 
            DateFormat('h:mm a').format(event.timestamp),
          ),
          const SizedBox(height: 10),

          // 4. Info Row: Location
          _buildInfoRow(
            Icons.location_on, 
            event.locationName.isNotEmpty ? event.locationName : 'Unknown Location',
            isBold: true
          ),
          Padding(
            padding: const EdgeInsets.only(left: 36, bottom: 10),
            child: Text(
              "${event.latitude.toStringAsFixed(4)}, ${event.longitude.toStringAsFixed(4)}",
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          
          const Divider(height: 30),

          // 5. Description
          const Text(
            "ABOUT THIS ACTION",
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.bold, 
              letterSpacing: 1.2,
              color: Colors.grey
            ),
          ),
          const SizedBox(height: 8),
          Text(
            event.description,
            style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
          ),
          
          const SizedBox(height: 30),

          // 6. Action Buttons (Edit & Close)
          Row(
            children: [
              // EDIT BUTTON
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Close the panel first, then go to edit
                    Navigator.pop(context); 
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventEditScreen(event: event),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit, color: Color(0xFFB71C1C)),
                  label: const Text('Edit', style: TextStyle(color: Color(0xFFB71C1C))),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFB71C1C)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),

              // CLOSE BUTTON
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFFB71C1C)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
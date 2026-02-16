import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Actions'),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Connect to the 'events' collection in your database
        stream: FirebaseFirestore.instance.collection('events').orderBy('timestamp').snapshots(),
        builder: (context, snapshot) {
          // 1. Show loading spinner while waiting for data
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // 2. Convert database documents into a list of Event objects
          final events = snapshot.data!.docs.map((doc) => ProtestEvent.fromSnapshot(doc)).toList();

          // 3. Handle empty state
          if (events.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("No upcoming events reported."),
                ],
              ),
            );
          }

          // 4. Build the actual list
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.event, color: Color(0xFFB71C1C)),
                  title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  // Format the date to look nice (e.g. "October 10, 2025 • 2:00 PM")
                  subtitle: Text(DateFormat('MMMM d, y • h:mm a').format(event.timestamp)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Show details when tapped (Reusing the map popup style)
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Text(event.description),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB71C1C),
                                foregroundColor: Colors.white
                              ),
                              child: const Text("Close"),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
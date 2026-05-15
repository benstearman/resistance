import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../widgets/event_details_panel.dart';
import 'event_edit_screen.dart';
import '../services/matrix_service.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = MatrixService.instance.client?.userID ?? 'Not Logged In';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actions v1.0.16-debug'),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Debug Info"),
                  content: Text("User: $userId\nSpace: ${MatrixService.resistanceSpaceId}"),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
                ),
              );
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFB71C1C),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          final userId = MatrixService.instance.client?.userID ?? '';
          final isGuest = userId.contains('guest');
          if (isGuest || userId.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please login or join the movement to add actions.")),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EventEditScreen()),
          );
        },
      ),
      body: StreamBuilder<List<ProtestEvent>>(
        stream: MatrixService.instance.getProtestEvents(),
        builder: (context, snapshot) {
          // 1. Show loading spinner or error
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData) {
            if (MatrixService.instance.client?.isLogged() != true) {
              MatrixService.instance.loginAsGuest();
              return const Center(child: CircularProgressIndicator());
            }
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data!;

          // 2. Handle empty state
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

          // 3. Build the list
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.event, color: Color(0xFFB71C1C)),
                  title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(DateFormat('MMMM d, y • h:mm a').format(event.timestamp)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => EventDetailsPanel(event: event),
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
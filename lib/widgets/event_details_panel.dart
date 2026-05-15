import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:matrix/matrix.dart';
import 'package:share_plus/share_plus.dart';
import '../models/event.dart';
import '../screens/event_edit_screen.dart';
import '../screens/room_chat_screen.dart';
import '../services/matrix_service.dart';

class EventDetailsPanel extends StatelessWidget {
  final ProtestEvent event;

  const EventDetailsPanel({super.key, required this.event});

  Future<void> _joinAndOpenChat(BuildContext context) async {
    final client = MatrixService.instance.client;
    if (client == null || event.roomId == null) return;

    try {
      var room = client.getRoomById(event.roomId!);
      if (room == null || room.membership != Membership.join) {
        await client.joinRoomById(event.roomId!);
        await Future.delayed(const Duration(seconds: 1));
        room = client.getRoomById(event.roomId!);
      }

      if (room != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RoomChatScreen(room: room!)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not join chat: $e")),
        );
      }
    }
  }

  Future<void> _shareEvent(BuildContext context) async {
    final String shareUrl = "https://resistance.chat/#/event/${event.id}";
    final String text = "Join the Action: ${event.title}\n${event.locationName}\n$shareUrl";
    
    await Share.share(text, subject: event.title);
  }

  Future<void> _deleteEvent(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Permanently Delete?"),
        content: const Text("This action will be removed from the map for all participants."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("DELETE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await MatrixService.instance.deleteProtestEvent(event.id);
        if (context.mounted) {
          Navigator.pop(context); // Close panel
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Action permanently removed.")));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Deletion failed: $e")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.series != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFB71C1C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFB71C1C).withOpacity(0.3)),
              ),
              child: Text(
                event.series!.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB71C1C),
                  letterSpacing: 1.5,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  event.title.toUpperCase(),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFB71C1C), letterSpacing: 1.1),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.blueGrey),
                    onPressed: () => _shareEvent(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blueGrey),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => EventEditScreen(event: event)));
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _detailRow(Icons.place, event.locationName, isBold: true),
          _detailRow(Icons.access_time, DateFormat('EEEE, MMM d • h:mm a').format(event.timestamp)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(thickness: 1),
          ),
          const Text("INTEL / MISSION PLAN", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(event.description, style: const TextStyle(fontSize: 16, height: 1.6)),
          const SizedBox(height: 32),
          
          if (event.roomId != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _joinAndOpenChat(context),
                  icon: const Icon(Icons.chat_bubble),
                  label: const Text("OPEN SECURE CHAT"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("RETURN TO MAP", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () => _deleteEvent(context),
              icon: const Icon(Icons.delete_forever, color: Colors.red, size: 20),
              label: const Text("CANCEL THIS ACTION (ADMIN ONLY)", style: TextStyle(color: Colors.red, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

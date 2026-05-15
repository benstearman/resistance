import 'package:flutter/material.dart';
import '../services/matrix_service.dart';
import 'package:matrix/matrix.dart';
import 'invite_display_screen.dart';
import 'invite_scanner_screen.dart';
import 'room_chat_screen.dart';

class ChatRoomList extends StatelessWidget {
  final VoidCallback onLogout;
  const ChatRoomList({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final client = MatrixService.instance.client!;

    return StreamBuilder(
      stream: client.onSync.stream,
      builder: (context, snapshot) {
        // Show all rooms that are not spaces
        final rooms = client.rooms.where((room) => !room.isSpace).toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const InviteScannerScreen()),
                        );
                      },
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text("SCAN QR"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (rooms.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text("No Resistance channels active."),
                      const SizedBox(height: 24),
                      const Text(
                        "Join a channel by scanning a QR code\nor by searching for public rooms.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 32),
                      TextButton(
                        onPressed: () async {
                          try {
                            await client.logout();
                          } catch (e) {
                            print("Logout failed: $e");
                          }
                          onLogout();
                        },
                        child: const Text("LOGOUT / SWITCH ACCOUNT"),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        backgroundImage: room.avatar != null ? NetworkImage(room.avatar!.toString()) : null,
                        child: room.avatar == null ? Text(room.getLocalizedDisplayname()[0]) : null,
                      ),
                      title: Text(room.getLocalizedDisplayname(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        room.lastEvent?.body ?? "Tap to start chatting...",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RoomChatScreen(room: room)),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

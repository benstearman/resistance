import 'package:flutter/material.dart';
import '../services/matrix_service.dart';

class ChatRoomList extends StatelessWidget {
  const ChatRoomList({super.key});

  @override
  Widget build(BuildContext context) {
    final client = MatrixService.instance.client!;

    return StreamBuilder(
      stream: client.onSync.stream,
      builder: (context, snapshot) {
        final rooms = client.rooms; // Get joined rooms

        if (rooms.isEmpty) {
          return const Center(child: Text("No secure channels active."));
        }

        return ListView.builder(
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
                room.lastEvent?.body ?? "Decrypted message...",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                // TODO: Open Chat View
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Chat View Implementation Next...")),
                );
              },
            );
          },
        );
      },
    );
  }
}
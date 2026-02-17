import 'package:flutter/material.dart';
import '../services/matrix_service.dart';
import 'package:matrix/matrix.dart';

class ChatRoomList extends StatelessWidget {
  const ChatRoomList({super.key});

  @override
  Widget build(BuildContext context) {
    final client = MatrixService.instance.client!;
    final String resistanceSpaceId = "!cUqQYleHdhIDZrVlLW:resistance.chat";

    return StreamBuilder(
      stream: client.onSync.stream,
      builder: (context, snapshot) {
        final String resistanceSpaceId = "!cUqQYleHdhIDZrVlLW:resistance.chat";

        // Filter rooms using the direct string constant for the parent relationship
        final rooms = client.rooms.where((room) {
          // Check for the space parent state event using the raw Matrix event type
          final parentEvent = room.getState('m.space.parent', resistanceSpaceId);
          
          // Include the room if it belongs to the Resistance Space and isn't the Space itself
          return parentEvent != null && room.id != resistanceSpaceId;
        }).toList();

        if (rooms.isEmpty) {
          return const Center(child: Text("No Resistance channels active."));
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
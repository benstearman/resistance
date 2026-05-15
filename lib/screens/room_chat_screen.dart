import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:intl/intl.dart';

class RoomChatScreen extends StatefulWidget {
  final Room room;

  const RoomChatScreen({super.key, required this.room});

  @override
  State<RoomChatScreen> createState() => _RoomChatScreenState();
}

class _RoomChatScreenState extends State<RoomChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  late Future<Timeline> _timelineFuture;

  @override
  void initState() {
    super.initState();
    _timelineFuture = widget.room.getTimeline();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final text = _messageController.text.trim();
    _messageController.clear();
    
    await widget.room.sendTextEvent(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.room.getLocalizedDisplayname()),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Timeline>(
        future: _timelineFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final timeline = snapshot.data!;

          return Column(
            children: [
              Expanded(
                child: StreamBuilder(
                  stream: widget.room.onUpdate.stream,
                  builder: (context, _) {
                    final events = timeline.events.where((e) => e.type == EventTypes.Message).toList();

                    return ListView.builder(
                      reverse: true,
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        final isMe = event.senderId == widget.room.client.userID;

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe ? const Color(0xFFB71C1C) : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  Text(
                                    event.senderId ?? "Unknown",
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                  ),
                                Text(
                                  event.body,
                                  style: TextStyle(color: isMe ? Colors.white : Colors.black),
                                ),
                                Text(
                                  DateFormat('h:mm a').format(event.originServerTs),
                                  style: TextStyle(fontSize: 8, color: isMe ? Colors.white70 : Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: "Enter secure message...",
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFFB71C1C)),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

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

  void _sendImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    // Show a loading indicator
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Uploading image...")),
    );

    try {
      await widget.room.sendFileEvent(
        MatrixFile(
          bytes: file.bytes!,
          name: file.name,
          mimeType: "image/\${file.extension ?? 'png'}",
        ),
        extraContent: {
          "msgtype": MessageTypes.Image,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload image: $e")),
      );
    }
  }

  Widget _buildMessageContent(Event event, bool isMe) {
    if (event.content['msgtype'] == MessageTypes.Image) {
      final mxcUrl = event.content['url'];
      if (mxcUrl is! String) return const Text("[Invalid Image]");

      final imageUrl = Uri.parse(mxcUrl).getDownloadUri(widget.room.client);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  backgroundColor: Colors.transparent,
                  child: InteractiveViewer(
                    child: Image.network(imageUrl.toString()),
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl.toString(),
                width: 250,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    width: 250,
                    height: 150,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
          ),
          if (event.body.isNotEmpty && event.body != file_picker_name_fallback)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                event.body,
                style: TextStyle(color: isMe ? Colors.white : Colors.black),
              ),
            ),
        ],
      );
    }

    return Text(
      event.body,
      style: TextStyle(color: isMe ? Colors.white : Colors.black),
    );
  }

  static const String file_picker_name_fallback = "file";

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
                    final events = timeline.events
                        .where((e) => e.type == EventTypes.Message)
                        .toList();

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
                                _buildMessageContent(event, isMe),
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
                    IconButton(
                      icon: const Icon(Icons.attach_file, color: Colors.grey),
                      onPressed: _sendImage,
                    ),
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

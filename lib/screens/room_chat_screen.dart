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
      final String extension = file.extension ?? 'png';
      await widget.room.sendFileEvent(
        MatrixFile(
          bytes: file.bytes!,
          name: file.name,
          mimeType: "image/$extension",
        ),
        extraContent: {
          "msgtype": "m.image",
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
    final dynamic msgTypeRaw = event.content['msgtype'];
    final String msgType = msgTypeRaw?.toString() ?? '';
    final dynamic info = event.content['info'];
    final dynamic file = event.content['file'];
    
    // Check multiple possible URL locations
    String? mxcUrl;
    if (event.content['url'] is String) {
      mxcUrl = event.content['url'] as String;
    } else if (file is Map && file['url'] is String) {
      mxcUrl = file['url'] as String;
    } else if (info is Map && info['url'] is String) {
      mxcUrl = info['url'] as String;
    } else if (info is Map && info['thumbnail_url'] is String) {
      mxcUrl = info['thumbnail_url'] as String;
    }
    
    final bool isImageMsg = msgType == 'm.image' || msgType == 'MessageTypes.Image';
    final bool isFileMsg = msgType == 'm.file' || msgType == 'MessageTypes.File';
    
    // Extremely permissive image check
    final bool isImage = mxcUrl != null && mxcUrl.startsWith('mxc://') && (
      isImageMsg || 
      event.body.toLowerCase().contains(RegExp(r'\.(png|jpe?g|gif|webp)$')) ||
      (info is Map && info['mimetype']?.toString().contains('image') == true)
    );

    if (isImage) {
      // MSC3916: Authenticated Media Download
      // The SDK helper Uri.getDownloadUri often returns the legacy /_matrix/media/v3 path which returns 404 on this server.
      // We manually construct the /_matrix/client/v1/media/download path and use query-param auth for Web compatibility.
      
      String imageUrl = "";
      final token = widget.room.client.accessToken;
      try {
        final uri = Uri.parse(mxcUrl!);
        final serverName = uri.host;
        final mediaId = uri.path.replaceAll('/', '');
        final homeserver = widget.room.client.homeserver.toString().replaceAll(RegExp(r'/$'), '');
        imageUrl = "$homeserver/_matrix/client/v1/media/download/$serverName/$mediaId?access_token=$token";
      } catch (e) {
        // Fallback to SDK if parsing fails
        imageUrl = Uri.parse(mxcUrl!).getDownloadUri(widget.room.client).toString() + "&access_token=$token";
      }
      
      print("DIAGNOSTIC: Constructed Image URL: " + imageUrl);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Image URL: " + imageUrl))
              );
              print("IMAGE URL DEBUG: " + imageUrl);
            },
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  backgroundColor: Colors.transparent,
                  child: InteractiveViewer(
                    child: Image.network(imageUrl),
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
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
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  width: 250,
                  height: 150,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, color: Colors.grey, size: 40),
                        Text("Failed to load image", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ]
                    )
                  )
                ),
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

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
    
    // Robust image check: Has an MXC URL and either is an image type or has image extension in body
    final bool isImage = mxcUrl != null && mxcUrl.startsWith('mxc://') && (
      isImageMsg || 
      event.body.toLowerCase().contains(".jpg") ||
      event.body.toLowerCase().contains(".jpeg") ||
      event.body.toLowerCase().contains(".png") ||
      event.body.toLowerCase().contains(".gif") ||
      event.body.toLowerCase().contains(".webp") ||
      (info is Map && info['mimetype']?.toString().contains('image') == true)
    );

    if (isImage) {
      // MSC3916: Authenticated Media Download
      // We use ONLY the Authorization header. 
      // Mixing both causes 401 error. 
      
      String imageUrl = "";
      final token = widget.room.client.accessToken;
      try {
        final uri = Uri.parse(mxcUrl!);
        final serverName = uri.host;
        final mediaId = uri.path.split('/').lastWhere((s) => s.isNotEmpty, orElse: () => "");
        final homeserver = widget.room.client.homeserver.toString().replaceAll(RegExp(r'/$'), '');
        
        // Manual construction of the authenticated path (NO token in URL)
        imageUrl = "$homeserver/_matrix/client/v1/media/download/$serverName/$mediaId";
      } catch (e) {
        // Fallback to SDK if parsing fails
        imageUrl = Uri.parse(mxcUrl!).getDownloadUri(widget.room.client).toString();
      }

      final headers = {
        'Authorization': 'Bearer ' + token.toString(),
      };
      
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
                    child: Image.network(imageUrl, headers: headers),
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                headers: headers,
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
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 250,
                  color: Colors.black87,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(child: Icon(Icons.error_outline, color: Colors.yellow, size: 40)),
                      const SizedBox(height: 8),
                      const Text("DEBUG: IMAGE LOAD FAILED", style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 10)),
                      const Divider(color: Colors.yellow),
                      Text("TYPE: " + msgType, style: const TextStyle(color: Colors.white, fontSize: 8)),
                      const SizedBox(height: 4),
                      const Text("STRICT HEADER URL:", style: TextStyle(color: Colors.yellow, fontSize: 8, fontWeight: FontWeight.bold)),
                      SelectableText(imageUrl, style: const TextStyle(color: Colors.white, fontSize: 7)),
                      const SizedBox(height: 4),
                      Text("ERROR: " + error.toString(), style: const TextStyle(color: Colors.redAccent, fontSize: 7)),
                    ]
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
                              color: isMe ? Colors.purple[900] : Colors.orange[800],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  Text(
                                    event.senderId ?? "Unknown",
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
                                  ),
                                _buildMessageContent(event, isMe),
                                Text(
                                  DateFormat('h:mm a').format(event.originServerTs),
                                  style: TextStyle(fontSize: 8, color: isMe ? Colors.white70 : Colors.white60),
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

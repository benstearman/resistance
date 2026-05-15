import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class InviteDisplayScreen extends StatelessWidget {
  final String roomId;
  final String roomName;

  const InviteDisplayScreen({super.key, required this.roomId, required this.roomName});

  @override
  Widget build(BuildContext context) {
    // Point to our own web app instead of matrix.to
    final String inviteUrl = "https://resistance.chat/#/join/$roomId";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Room Invite"),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Invite to $roomName",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              QrImageView(
                data: inviteUrl,
                version: QrVersions.auto,
                size: 250.0,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 32),
              const Text(
                "Scan this QR code with the Resistance App to join this secure channel.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              SelectableText(
                inviteUrl,
                style: const TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

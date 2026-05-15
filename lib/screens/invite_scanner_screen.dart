import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/matrix_service.dart';

class InviteScannerScreen extends StatefulWidget {
  const InviteScannerScreen({super.key});

  @override
  State<InviteScannerScreen> createState() => _InviteScannerScreenState();
}

class _InviteScannerScreenState extends State<InviteScannerScreen> {
  bool _isProcessing = false;

  Future<void> _handleScan(String code) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      // Extract Room ID from multiple link formats
      String roomId = code;
      if (code.contains("matrix.to/#/")) {
        roomId = code.split("matrix.to/#/").last;
      } else if (code.contains("resistance.chat/#/join/")) {
        roomId = code.split("resistance.chat/#/join/").last;
      }

      await MatrixService.instance.client!.joinRoomById(roomId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Successfully joined channel!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to join: $e")),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Invite"),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleScan(barcode.rawValue!);
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_isProcessing)
            const Center(child: CircularProgressIndicator(color: Colors.red)),
        ],
      ),
    );
  }
}

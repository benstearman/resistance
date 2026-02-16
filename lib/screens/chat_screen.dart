import 'package:flutter/material.dart';
import '../services/matrix_service.dart';
import 'chat_login_screen.dart';
import 'chat_room_list.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await MatrixService.instance.init();
    if (MatrixService.instance.client?.isLogged() ?? false) {
      setState(() => _isLoggedIn = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Network'),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        actions: [
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await MatrixService.instance.client?.logout();
                setState(() => _isLoggedIn = false);
              },
            ),
        ],
      ),
      body: _isLoggedIn 
          ? const ChatRoomList() 
          : ChatLoginScreen(onLoginSuccess: () => setState(() => _isLoggedIn = true)),
    );
  }
}
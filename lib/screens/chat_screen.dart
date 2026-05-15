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
    final service = MatrixService.instance;
    if ((service.client?.isLogged() ?? false) && !service.isGuest) {
      setState(() => _isLoggedIn = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = MatrixService.instance;
    final bool actuallyLoggedIn = _isLoggedIn && !service.isGuest;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Network'),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        actions: [
          if (actuallyLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                try {
                  await MatrixService.instance.client?.logout();
                } catch (e) {
                  print("Logout failed: $e");
                }
                setState(() => _isLoggedIn = false);
              },
            ),
        ],
      ),
      body: actuallyLoggedIn 
          ? ChatRoomList(onLogout: () => setState(() => _isLoggedIn = false)) 
          : ChatLoginScreen(onLoginSuccess: () => setState(() => _isLoggedIn = true)),
    );
  }
}
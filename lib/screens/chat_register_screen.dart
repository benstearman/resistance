import 'package:flutter/material.dart';
import '../services/matrix_service.dart';
import 'package:matrix/matrix.dart';

class ChatRegisterScreen extends StatefulWidget {
  final VoidCallback onRegistrationSuccess;

  const ChatRegisterScreen({super.key, required this.onRegistrationSuccess});

  @override
  State<ChatRegisterScreen> createState() => _ChatRegisterScreenState();
}

class _ChatRegisterScreenState extends State<ChatRegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _tokenController = TextEditingController(); // For registration token
  bool _isLoading = false;
  String? _session;

  Future<void> _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final client = MatrixService.instance.client!;
      
      // 1. Initial attempt to get a session
      try {
        await client.checkHomeserver(Uri.parse("https://matrix.resistance.chat"));
        await client.register(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );
      } on MatrixException catch (e) {
        if (e.session != null) {
          _session = e.session;
          // 2. Submit the dummy auth with the session we just got
          await client.register(
            username: _usernameController.text.trim(),
            password: _passwordController.text,
            auth: AuthenticationData(
              type: 'm.login.dummy',
              session: _session,
            ),
          );
        } else {
          rethrow;
        }
      }

      widget.onRegistrationSuccess();
    } catch (e) {
      if (!mounted) return;
      
      String message = e.toString();
      if (e is MatrixException && e.error == 'M_FORBIDDEN') {
        message = "Registration requires a token or is disabled on the server.";
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration Failed: $message")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("JOIN THE RESISTANCE"),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.person_add, size: 80, color: Color(0xFFB71C1C)),
            const SizedBox(height: 20),
            const Text(
              "CREATE SECURE IDENTITY",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: "Username",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Confirm Password",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("INITIALIZE ACCOUNT"),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Note: If registration fails with M_FORBIDDEN, ensure public registration is enabled in Synapse.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

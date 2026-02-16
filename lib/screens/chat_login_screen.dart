import 'package:flutter/material.dart';
import '../services/matrix_service.dart';

class ChatLoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const ChatLoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<ChatLoginScreen> createState() => _ChatLoginScreenState();
}

class _ChatLoginScreenState extends State<ChatLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await MatrixService.instance.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );
      widget.onLoginSuccess();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login Failed: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.security, size: 80, color: Color(0xFFB71C1C)),
          const SizedBox(height: 20),
          const Text(
            "SECURE COMMS",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: "Matrix Username",
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
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("ESTABLISH UPLINK"),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Don't have an account? Register at matrix.org",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import '../services/api_service.dart'; // <-- Ensure import

class SummaryScreen extends StatelessWidget {
  final String title;
  final String summaryText;
  final ApiService api; // <-- Add api field

  const SummaryScreen({
    super.key,
    required this.title,
    required this.summaryText,
    required this.api, // <-- Require api in constructor
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Text('Resumen de $title'),
        actions: [ // <-- Add actions block
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) async {
              if (value == 'profile') {
                // Pass api
                Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(api: api)));
              } else if (value == 'logout') {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                // Clear token in ApiService instance as well
                api.clearToken();
                if (context.mounted) {
                  // Pass api
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen(api: api)),
                    (route) => false,
                  );
                }
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Ver perfil'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Cerrar sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(summaryText, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
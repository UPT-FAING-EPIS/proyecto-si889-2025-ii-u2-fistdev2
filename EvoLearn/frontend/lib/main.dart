import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'config.dart';
import 'providers/theme_provider.dart';

void main() {
  runApp(const EstudiaFacilApp());
}

class EstudiaFacilApp extends StatelessWidget {
  const EstudiaFacilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider()..loadTheme(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final api = ApiService(baseUrl: getBaseUrl());
          
          return MaterialApp(
            title: 'EstudiaFácil',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: LoginScreen(api: api),
          );
        },
      ),
    );
  }
}

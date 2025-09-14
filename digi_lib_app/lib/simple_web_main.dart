import 'package:flutter/material.dart';

void main() {
  runApp(const SimpleDigiLibApp());
}

class SimpleDigiLibApp extends StatelessWidget {
  const SimpleDigiLibApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DigiLib - Digital Library',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DigiLib - Digital Library'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books, size: 100, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'Welcome to DigiLib',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Your Digital Library Management System',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 40),
            Text(
              '🎉 Web deployment is working!',
              style: TextStyle(
                fontSize: 20,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('DigiLib web app is running successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
        child: const Icon(Icons.play_arrow),
      ),
    );
  }
}

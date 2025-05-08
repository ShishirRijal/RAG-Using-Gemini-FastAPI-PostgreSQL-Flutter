import 'package:flutter/material.dart';
import 'package:rag_using_ollama_fastapi_flutter/core/theme.dart';
import 'package:rag_using_ollama_fastapi_flutter/screens/home_page.dart'; // Import the new home page location

void main() {
  runApp(const RagPdfApp());
}

class RagPdfApp extends StatelessWidget {
  const RagPdfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RAG PDF Assistant',
      debugShowCheckedModeBanner: false,
      theme: theme,
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

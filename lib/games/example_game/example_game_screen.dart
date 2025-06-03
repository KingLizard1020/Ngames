import 'package:flutter/material.dart';

class ExampleGameScreen extends StatelessWidget {
  const ExampleGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Example Game')),
      body: const Center(child: Text('Game Placeholder')),
    );
  }
}

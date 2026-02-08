import 'package:flutter/material.dart';
import 'cpu_simulator.dart';

void main() {
  runApp(const CPUSimulatorApp());
}

class CPUSimulatorApp extends StatelessWidget {
  const CPUSimulatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CPU Simulator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pink,
          secondary: Colors.purple,
        ),
        fontFamily: 'Quicksand',
      ),
      home: const CPUSimulator(),
    );
  }
}

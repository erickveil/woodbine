import 'package:flutter/material.dart';
import 'pages/dice_roller_page.dart';

class DiceRollerApp extends StatelessWidget {
  const DiceRollerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Woodbine',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 51, 44, 21)),
        useMaterial3: true,
      ),
      home: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFEEEEEE), // light gray background color
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpg'),
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
          ),
        ),
        child: const DiceRollerPage(),
      ),
    );
  }
}

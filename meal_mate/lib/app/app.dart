import 'package:flutter/material.dart';
import 'theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MealMate',
      theme: appTheme,
      home: const Scaffold(
        body: Center(child: Text('MealMate — Foundation')),
      ),
    );
  }
}

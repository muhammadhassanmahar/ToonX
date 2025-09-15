import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ToonXApp());
}

class ToonXApp extends StatelessWidget {
  const ToonXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToonX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

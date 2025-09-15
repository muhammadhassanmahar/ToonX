import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/api_service.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = false;
  File? _selectedImage;

  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() => _loading = true);

    final result = await ApiService.processImage(_selectedImage!.path);

    setState(() => _loading = false);

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ToonX"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: _loading
            ? const SpinKitFadingCircle(
                color: Colors.blue,
                size: 60,
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Upload an image to convert",
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _processImage,
                    child: const Text("Process Image"),
                  ),
                ],
              ),
      ),
    );
  }
}

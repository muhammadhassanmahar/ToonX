import 'dart:typed_data'; // ✅ For Uint8List
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

// Mobile-only imports
// ignore: avoid_web_libraries_in_flutter
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

// ✅ Import your service and screens
import '../services/api_service.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image; // Mobile
  Uint8List? _webImage; // Web
  bool _processing = false;

  final ImagePicker _picker = ImagePicker();

  /// Pick image (web + mobile)
  Future<void> _pickImage() async {
    if (!kIsWeb) {
      var status = await Permission.photos.request();
      if (!status.isGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Gallery permission denied")),
        );
        return;
      }
    }

    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (!mounted) return;
      if (kIsWeb) {
        _webImage = await pickedFile.readAsBytes();
        setState(() => _image = null);
      } else {
        setState(() => _image = File(pickedFile.path));
      }
    }
  }

  /// Call Cartoonify API via ApiService
  Future<void> _cartoonify() async {
    if (_image == null && _webImage == null) return;

    setState(() {
      _processing = true;
    });

    try {
      // ✅ Call updated ApiService
      final cartoonPathOrUrl = await ApiService.cartoonifyImage(_image!);

      if (!mounted) return;

      if (cartoonPathOrUrl != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              originalImage: _image!,
              cartoonPathOrUrl: cartoonPathOrUrl,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Failed to cartoonify image")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Error: $e")),
      );
    }

    if (mounted) {
      setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = kIsWeb
        ? (_webImage != null
            ? Image.memory(_webImage!, height: 200)
            : const Text("No image selected"))
        : (_image != null
            ? Image.file(_image!, height: 200)
            : const Text("No image selected"));

    return Scaffold(
      appBar: AppBar(
        title: const Text("🎨 ToonX Cartoonify"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: imageWidget,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Pick Image"),
                ),
                const SizedBox(height: 20),
                _processing
                    ? const SpinKitFadingCircle(
                        color: Colors.deepPurple,
                        size: 50,
                      )
                    : ElevatedButton.icon(
                        onPressed: _cartoonify,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text("Cartoonify"),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

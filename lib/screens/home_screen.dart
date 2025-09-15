import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  bool _processing = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _cartoonify() async {
    if (_image == null) return;

    setState(() => _processing = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("https://api.deepai.org/api/toonify"), // Cartoonify API
      );

      request.headers['Api-Key'] =
          "06be970e-afa0-4150-a186-eda5b221334c"; // tumhari API key

      request.files.add(await http.MultipartFile.fromPath('image', _image!.path));

      var response = await request.send();
      var responseBody = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        print("✅ Cartoonify Success: ${responseBody.body}");
        // TODO: response se image URL nikalna & download/save karna
      } else {
        print("❌ Error: ${response.statusCode} - ${responseBody.body}");
      }
    } catch (e) {
      print("⚠️ Exception: $e");
    }

    setState(() => _processing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ToonX"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _image == null
                  ? const Text("No image selected")
                  : Image.file(_image!, height: 200),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library),
                label: const Text("Pick Image"),
              ),
              const SizedBox(height: 20),

              // ✅ Yahan loader ya button show hoga
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
    );
  }
}

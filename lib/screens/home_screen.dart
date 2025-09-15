import 'dart:io';
import 'dart:convert';
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
  String? _cartoonUrl;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    // ✅ Check permission before picking
    var status = await Permission.photos.request();
    if (status.isGranted) {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gallery permission denied")),
      );
    }
  }

  Future<void> _cartoonify() async {
    if (_image == null) return;

    setState(() {
      _processing = true;
      _cartoonUrl = null;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("https://api.deepai.org/api/toonify"), // Cartoonify API
      );

      request.headers['Api-Key'] =
          "06be970e-afa0-4150-a186-eda5b221334c"; // Tumhari API key

      request.files
          .add(await http.MultipartFile.fromPath('image', _image!.path));

      var response = await request.send();
      var responseBody = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final data = json.decode(responseBody.body);
        setState(() {
          _cartoonUrl = data["output_url"];
        });
        print("✅ Cartoonify Success: $_cartoonUrl");
      } else {
        print("❌ Error: ${response.statusCode} - ${responseBody.body}");
      }
    } catch (e) {
      print("⚠️ Exception: $e");
    }

    setState(() => _processing = false);
  }

  Future<void> _downloadCartoon() async {
    if (_cartoonUrl == null) return;

    try {
      // ✅ Get storage directory
      final dir = await getTemporaryDirectory();
      final filePath = "${dir.path}/toonx_cartoon.jpg";

      final response = await http.get(Uri.parse(_cartoonUrl!));
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // ✅ Save to gallery
      await GallerySaver.saveImage(file.path);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saved to gallery ✅")),
      );
    } catch (e) {
      print("⚠️ Download error: $e");
    }
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

              // ✅ Loader ya button
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

              const SizedBox(height: 20),

              // ✅ Cartoonify result ke liye button
              if (_cartoonUrl != null)
                Column(
                  children: [
                    Image.network(_cartoonUrl!, height: 200),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _downloadCartoon,
                      icon: const Icon(Icons.download),
                      label: const Text("Download"),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

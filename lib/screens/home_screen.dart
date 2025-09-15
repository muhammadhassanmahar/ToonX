import 'dart:convert';
import 'dart:typed_data'; // ✅ For Uint8List
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:http/http.dart' as http;

// Mobile-only imports
// ignore: avoid_web_libraries_in_flutter
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image; // Mobile
  Uint8List? _webImage; // Web
  bool _processing = false;
  String? _cartoonUrl;

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

  /// Call Toonify API
  Future<void> _cartoonify() async {
    if (_image == null && _webImage == null) return;

    setState(() {
      _processing = true;
      _cartoonUrl = null;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("https://api.deepai.org/api/toonify"),
      );
      request.headers['Api-Key'] = "06be970e-afa0-4150-a186-eda5b221334c";

      if (kIsWeb && _webImage != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            _webImage!,
            filename: 'upload.jpg',
          ),
        );
      } else if (_image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', _image!.path),
        );
      }

      var response = await request.send();
      var responseBody = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final data = json.decode(responseBody.body);
        if (!mounted) return;
        setState(() => _cartoonUrl = data["output_url"]);
        debugPrint("✅ Cartoonify Success: $_cartoonUrl");
      } else {
        debugPrint("❌ Error: ${response.statusCode} - ${responseBody.body}");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed: ${responseBody.body}")),
        );
      }
    } catch (e) {
      debugPrint("⚠️ Exception: $e");
    }

    if (!mounted) return;
    setState(() => _processing = false);
  }

  /// Download or handle cartoon
  Future<void> _downloadCartoon() async {
    if (_cartoonUrl == null) return;

    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("💡 Right-click on image to save in web browsers."),
        ),
      );
    } else {
      try {
        final dir = await getTemporaryDirectory();
        final filePath = "${dir.path}/toonx_cartoon.jpg";
        final response = await http.get(Uri.parse(_cartoonUrl!));
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        await GallerySaver.saveImage(file.path);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Saved to gallery")),
        );
      } catch (e) {
        debugPrint("⚠️ Download error: $e");
      }
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
                const SizedBox(height: 20),
                if (_cartoonUrl != null)
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(_cartoonUrl!, height: 200),
                      ),
                      const SizedBox(height: 12),
                      // ✅ Fixed prefer_const_constructors warning
                      if (kIsWeb)
                        ElevatedButton.icon(
                          onPressed: _downloadCartoon,
                          icon: const Icon(Icons.download),
                          label: const Text("Right-click to save (Web)"),
                        )
                      else
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
      ),
    );
  }
}

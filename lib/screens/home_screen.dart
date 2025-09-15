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

  /// ✅ Pick image from gallery
  Future<void> _pickImage() async {
    var status = await Permission.photos.request();

    if (status.isGranted) {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        if (!mounted) return; // ✅ Fix
        setState(() => _image = File(pickedFile.path));
      }
    } else {
      if (!mounted) return; // ✅ Fix
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Gallery permission denied")),
      );
    }
  }

  /// ✅ Call Toonify API
  Future<void> _cartoonify() async {
    if (_image == null) return;

    setState(() {
      _processing = true;
      _cartoonUrl = null;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("https://api.deepai.org/api/toonify"),
      );

      request.headers['Api-Key'] =
          "06be970e-afa0-4150-a186-eda5b221334c"; // 👉 apni API key

      request.files
          .add(await http.MultipartFile.fromPath('image', _image!.path));

      var response = await request.send();
      var responseBody = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final data = json.decode(responseBody.body);
        if (!mounted) return; // ✅ Fix
        setState(() => _cartoonUrl = data["output_url"]);
        debugPrint("✅ Cartoonify Success: $_cartoonUrl");
      } else {
        debugPrint("❌ Error: ${response.statusCode} - ${responseBody.body}");
        if (!mounted) return; // ✅ Fix
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed: ${responseBody.body}")),
        );
      }
    } catch (e) {
      debugPrint("⚠️ Exception: $e");
    }

    if (!mounted) return; // ✅ Fix
    setState(() => _processing = false);
  }

  /// ✅ Download image and save to gallery
  Future<void> _downloadCartoon() async {
    if (_cartoonUrl == null) return;

    try {
      final dir = await getTemporaryDirectory();
      final filePath = "${dir.path}/toonx_cartoon.jpg";

      final response = await http.get(Uri.parse(_cartoonUrl!));
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      await GallerySaver.saveImage(file.path);

      if (!mounted) return; // ✅ Fix
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Saved to gallery")),
      );
    } catch (e) {
      debugPrint("⚠️ Download error: $e");
    }
  }

  /// ✅ UI
  @override
  Widget build(BuildContext context) {
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
                // Selected image preview
                _image == null
                    ? const Text("No image selected")
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_image!, height: 200),
                      ),
                const SizedBox(height: 20),

                // Pick Image
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Pick Image"),
                ),
                const SizedBox(height: 20),

                // Loader / Cartoonify button
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

                // Cartoon result
                if (_cartoonUrl != null)
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(_cartoonUrl!, height: 200),
                      ),
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
      ),
    );
  }
}

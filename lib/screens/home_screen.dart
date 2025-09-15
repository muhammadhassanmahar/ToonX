import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../widgets/custom_button.dart';
import '../widgets/animated_card.dart';
import '../services/api_service.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  bool _loading = false;
  bool _processing = false;

  Future<void> _pickImage(ImageSource src) async {
    final picked = await ImagePicker().pickImage(source: src, imageQuality: 85, maxWidth: 1600);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  Future<void> _cartoonify() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please pick an image first')));
      return;
    }
    setState(() {
      _processing = true;
    });
    final cartoonUrl = await ApiService.cartoonifyImage(_image!);
    setState(() {
      _processing = false;
    });
    if (cartoonUrl != null && mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ResultScreen(originalImage: _image!, cartoonUrl: cartoonUrl)));
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cartoonify failed. Try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          return Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ToonX', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple.shade700)),
                    IconButton(onPressed: () => _showAbout(), icon: Icon(Icons.info_outline, color: Colors.deepPurple.shade700)),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: isWide
                      ? Row(
                          children: [
                            Expanded(child: _buildLeftCard()),
                            const SizedBox(width: 18),
                            Expanded(child: _buildPreviewCard()),
                          ],
                        )
                      : Column(
                          children: [
                            Expanded(child: _buildLeftCard()),
                            const SizedBox(height: 16),
                            SizedBox(height: 260, child: _buildPreviewCard()),
                          ],
                        ),
                ),
                const SizedBox(height: 12),
                Row(children: [Expanded(child: CustomButton(text: 'Pick from Gallery', onPressed: () => _pickImage(ImageSource.gallery)))]),
                const SizedBox(height: 8),
                Row(children: [Expanded(child: CustomButton(text: 'Take Photo', onPressed: () => _pickImage(ImageSource.camera)))]),
                const SizedBox(height: 12),
                Row(children: [Expanded(child: CustomButton(text: 'Cartoonify', onPressed: _cartoonify, loading: _processing))]),
                const SizedBox(height: 6),
              ],
            ),
          );
        }),
      ),
      floatingActionButton: _image == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _cartoonify,
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Quick Cartoon'),
            ),
    );
  }

  Widget _buildLeftCard() {
    return AnimatedCard(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How it works', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple.shade700)),
            const SizedBox(height: 8),
            const Text('1. Pick or take a photo\n2. Tap Cartoonify\n3. Save or share your cartoon image', style: TextStyle(fontSize: 14, height: 1.6)),
            const Spacer(),
            Center(child: Image.asset('assets/images/illustration.png', height: 140, fit: BoxFit.contain)),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return AnimatedCard(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.deepPurple.shade50, borderRadius: BorderRadius.circular(16)),
        child: Center(
          child: _image == null
              ? Column(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.photo, size: 64), SizedBox(height: 8), Text('No image selected')])
              : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_image!, fit: BoxFit.cover)),
        ),
      ),
    );
  }

  void _showAbout() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: const [
          Text('ToonX', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Convert your photos into cool cartoons using CartoonGAN powered by DeepAI.'),
          SizedBox(height: 12),
        ]),
      ),
    );
  }
}

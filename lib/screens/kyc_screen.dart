import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  File? selectedImage;
  String extractedText = "";
  bool isLoading = false;

  final ImagePicker picker = ImagePicker();

  // ✅ Pick image
  Future<void> pickImage(ImageSource source) async {
    final XFile? picked = await picker.pickImage(source: source);

    if (picked == null) return;

    setState(() {
      selectedImage = File(picked.path);
      extractedText = "";
    });

    // OCR after picking
    await runOCR();
  }

  // ✅ OCR function
  Future<void> runOCR() async {
    if (selectedImage == null) return;

    setState(() => isLoading = true);

    try {
      final inputImage = InputImage.fromFile(selectedImage!);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

      final RecognizedText recognizedText =
      await textRecognizer.processImage(inputImage);

      await textRecognizer.close();

      setState(() {
        extractedText = recognizedText.text;
      });
    } catch (e) {
      setState(() {
        extractedText = "OCR Failed: $e";
      });
    }

    setState(() => isLoading = false);
  }

  // ✅ Upload image + OCR text to API
  Future<void> uploadKyc() async {
    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select image first")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // 🔥 Replace with your API endpoint
      final uri = Uri.parse("https://your-api.com/kyc/upload");

      var request = http.MultipartRequest("POST", uri);

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath("kyc_image", selectedImage!.path),
      );

      // Add extracted OCR text
      request.fields["ocr_text"] = extractedText;

      // Optional: Add userId
      request.fields["user_id"] = "123";

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("KYC Uploaded Successfully ✅")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload Failed ❌: $responseBody")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload Error: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  // ✅ Extract Aadhaar / PAN number (Optional)
  String extractIdNumber(String text) {
    // Aadhaar format: 1234 5678 9012
    final aadhaarRegex = RegExp(r"\b\d{4}\s\d{4}\s\d{4}\b");
    final panRegex = RegExp(r"\b[A-Z]{5}[0-9]{4}[A-Z]{1}\b");

    final aadhaarMatch = aadhaarRegex.firstMatch(text);
    if (aadhaarMatch != null) return "Aadhaar: ${aadhaarMatch.group(0)}";

    final panMatch = panRegex.firstMatch(text);
    if (panMatch != null) return "PAN: ${panMatch.group(0)}";

    return "No Aadhaar/PAN detected";
  }

  @override
  Widget build(BuildContext context) {
    final detected = extractIdNumber(extractedText);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("KYC Upload + OCR"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Preview
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
              ),
              child: selectedImage == null
                  ? const Center(child: Text("No Image Selected"))
                  : ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(selectedImage!, fit: BoxFit.cover),
              ),
            ),

            const SizedBox(height: 16),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Camera"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo),
                    label: const Text("Gallery"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Loading
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              const SizedBox.shrink(),

            const SizedBox(height: 16),

            // Extracted ID
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
              ),
              child: Text(
                "Detected: $detected",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // OCR Text
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
              ),
              child: Text(
                extractedText.isEmpty
                    ? "OCR text will appear here..."
                    : extractedText,
                style: const TextStyle(fontSize: 13),
              ),
            ),

            const SizedBox(height: 20),

            // Upload Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: uploadKyc,
                icon: const Icon(Icons.cloud_upload),
                label: const Text("Upload KYC"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

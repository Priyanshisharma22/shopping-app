import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'enter_amount_screen.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  final ImagePicker picker = ImagePicker();
  bool scanned = false;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  // ================= CAMERA SCAN =================

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;

    controller.scannedDataStream.listen((scanData) {
      if (!scanned) {
        scanned = true;
        _handleQrResult(scanData.code ?? "");
      }
    });
  }

  // ================= GALLERY SCAN =================

  Future<void> pickQrFromGallery() async {
    final XFile? picked =
    await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    final inputImage = InputImage.fromFile(File(picked.path));
    final barcodeScanner = BarcodeScanner();

    final barcodes = await barcodeScanner.processImage(inputImage);

    await barcodeScanner.close();

    if (barcodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No QR found in image")),
      );
      return;
    }

    final qrText = barcodes.first.rawValue ?? "";
    _handleQrResult(qrText);
  }

  // ================= COMMON HANDLER =================

  void _handleQrResult(String qrText) {
    if (qrText.isEmpty) {
      scanned = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("QR not detected")),
      );
      return;
    }

    try {
      // Expected real UPI QR:
      // upi://pay?pa=rahul@upi&pn=Rahul

      final uri = Uri.parse(qrText);
      final receiverUpiId =
          uri.queryParameters["pa"] ?? "unknown@upi";

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              EnterAmountScreen(receiverUpiId: receiverUpiId),
        ),
      );
    } catch (e) {
      scanned = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid QR format")),
      );
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan QR"),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo),
            onPressed: pickQrFromGallery,
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: pickQrFromGallery,
                icon: const Icon(Icons.upload_file),
                label: const Text("Upload QR Image"),
              ),
            ),
          )
        ],
      ),
    );
  }
}
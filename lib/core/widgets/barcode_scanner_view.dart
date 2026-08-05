import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../platform/capabilities.dart';

/// Opens a full-screen camera barcode scanner and resolves with the first
/// scanned code's `rawValue`, or `null` if the owner backs out without
/// scanning anything. This is the one shared entry point every screen
/// that wants "scan instead of type" (Daily Sales' product search,
/// `ProductFormSheet`'s barcode field) should call — no screen builds its
/// own camera view.
///
/// Callers must check [PlatformCapabilities.hasCamera] themselves before
/// showing whatever button leads here (same convention QuickCapture's
/// photo capture already establishes) — this function does not re-check
/// it, since by the time it's called the owner already tapped a
/// camera-shaped button that should never have been visible on a
/// no-camera platform in the first place.
///
/// **Verification note**: this sandbox has no Android SDK/emulator (see
/// `NotificationService`'s own doc comment for the same limitation on a
/// different feature) — the camera permission prompt and real barcode
/// decoding are not verified on a real device here, only that this code
/// compiles and analyzes cleanly and that a scanned value correctly
/// propagates back through [findProductByBarcode]
/// (`barcode_lookup_test.dart`).
Future<String?> showBarcodeScanner(BuildContext context) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(builder: (context) => const _BarcodeScannerScreen()),
  );
}

class _BarcodeScannerScreen extends StatefulWidget {
  const _BarcodeScannerScreen();

  @override
  State<_BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<_BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final rawValue = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (rawValue == null || rawValue.isEmpty) return;

    _handled = true;
    Navigator.of(context).pop(rawValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('scanBarcodeTitle'.tr)),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.black54,
              padding: const EdgeInsets.all(16),
              child: Text(
                'scanBarcodeHint'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

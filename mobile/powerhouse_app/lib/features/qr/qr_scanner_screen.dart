import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/app_theme.dart';
import '../../core/api_service.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late MobileScannerController controller;
  bool isScanning = true;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (!isScanning) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
         setState(() => isScanning = false);
         await controller.stop(); // Stop camera before processing
         _handleScan(code);
      }
    }
  }

  Future<void> _handleScan(String code) async {
    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    try {
      final res = await ApiService.post('/qr/scan', {'code_hash': code});
      if (mounted) Navigator.pop(context); // Remove loading

      if (res['success'] == true) {
        _showResult(true, res['message'] ?? 'Attendance Marked!');
      } else {
        if (res['error_code'] == 'GYM_CLOSED') {
          _showGymClosed(res['message'] ?? 'Gym is currently closed.');
        } else {
          _showResult(false, res['message'] ?? 'Invalid QR Code');
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showResult(false, 'Network Error');
    }
  }

  void _showResult(bool success, String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : AppColors.error,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              success ? 'SUCCESS' : 'FAILED',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: success ? Colors.green : AppColors.error),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await controller.start(); // Restart camera
                  setState(() => isScanning = true);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.surfaceHigh),
                child: const Text('SCAN AGAIN', style: TextStyle(color: AppColors.onSurface)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context, true), // Pop to dashboard
              child: const Text('BACK TO DASHBOARD', style: TextStyle(color: AppColors.secondary, fontSize: 12)),
            ),
          ],
        ),
      ),
    ).then((val) {
      if (val == true && mounted) {
         Navigator.pop(context);
      }
    });
  }

  void _showGymClosed(String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.nightlight_round, color: AppColors.secondary, size: 64),
            const SizedBox(height: 16),
            const Text(
              'GYM IS CLOSED',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.onSurface),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true); // Go back to dashboard entirely
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('BACK TO DASHBOARD', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('SCAN QR CODE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
        actions: [
          IconButton(
            onPressed: () => controller.switchCamera(),
            icon: const Icon(Icons.cameraswitch, color: Colors.grey),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          // Scanner Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                   // Decorative corners
                   _buildCorner(0, 0, 1, 0),
                   _buildCorner(null, 0, 0, 1),
                   _buildCorner(0, null, 1, 0),
                   _buildCorner(null, null, 0, 1),
                ],
              ),
            ),
          ),
          const Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'ALIGN QR CODE WITHIN FRAME',
                style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(double? top, double? left, int rotateX, int rotateY) {
    return Positioned(
      top: top,
      left: left,
      child: Transform.scale(
        scaleX: rotateX == 1 ? 1 : -1,
        scaleY: rotateY == 1 ? 1 : -1,
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.primary, width: 4),
              left: BorderSide(color: AppColors.primary, width: 4),
            ),
          ),
        ),
      ),
    );
  }
}

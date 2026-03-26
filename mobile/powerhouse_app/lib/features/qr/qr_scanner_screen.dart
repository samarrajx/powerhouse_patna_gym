import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/app_theme.dart';
import '../../core/api_service.dart';
import '../../core/ui/design_system.dart';
import '../../core/ui/app_card.dart';
import '../../core/ui/streak_popup.dart';

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
        _showResult(true, res['message'] ?? 'Attendance Marked!', data: res['data']);
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

  void _showResult(bool success, String message, {Map<String, dynamic>? data}) {
    // If it's a successful 'IN' scan with streak data, show celebration instead of standard result
    if (success && data?['action'] == 'IN' && data?['streak'] != null) {
      final streak = data!['streak'];
      StreakPopup.show(context, streak['current'] ?? 0, streak['isNewRecord'] ?? false).then((_) {
        // After popup closes, return to dashboard
        if (mounted) Navigator.pop(context, true);
      });
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surf(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.surfHigh(context)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (success ? AppColors.success : AppColors.primary).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                success ? Icons.check_circle_outline : Icons.error_outline,
                color: success ? AppColors.success : AppColors.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              success ? 'SUCCESS' : 'SCAN FAILED',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: success ? AppColors.success : AppColors.primary, letterSpacing: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              message, 
              textAlign: TextAlign.center, 
              style: TextStyle(color: AppColors.text2(context), fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 32),
            if (!success)
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await controller.start(); // Restart camera
                  setState(() => isScanning = true);
                },
                child: const Text('TRY AGAIN'),
              )
            else
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('DISMISS'),
              ),
            const SizedBox(height: 12),
            if (!success)
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('BACK TO DASHBOARD', style: TextStyle(color: AppColors.text3(context), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
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

  // Removed old _showStreakPopup as it's replaced by StreakPopup.show

  void _showGymClosed(String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surf(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.surfHigh(context)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.primaryDim, shape: BoxShape.circle),
              child: const Icon(Icons.lock_clock, color: AppColors.primary, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'GYM IS CLOSED',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.primary, letterSpacing: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              message, 
              textAlign: TextAlign.center, 
              style: TextStyle(color: AppColors.text2(context), fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              child: const Text('BACK TO DASHBOARD'),
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('SCAN QR CODE'),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context), 
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () => controller.toggleTorch(),
            icon: const Icon(Icons.flashlight_on, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          // Scanner Overlay Mask
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      // Hollow center
                      Center(
                        child: Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.transparent),
                          ),
                        ),
                      ),
                       // Decorative corners
                       _buildCorner(0, 0, 1, 1),
                       _buildCorner(null, 0, -1, 1),
                       _buildCorner(0, null, 1, -1),
                       _buildCorner(null, null, -1, -1),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Text(
                    'ALIGN QR WITHIN FRAME',
                    style: TextStyle(color: Colors.white, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(double? top, double? left, double scaleX, double scaleY) {
    return Positioned(
      top: top,
      left: left,
      child: Transform.scale(
        scaleX: scaleX,
        scaleY: scaleY,
        child: Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.primary, width: 5),
              left: BorderSide(color: AppColors.primary, width: 5),
            ),
          ),
        ),
      ),
    );
  }
}

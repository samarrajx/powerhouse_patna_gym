import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/attendance_provider.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool isProcessing = false;

  void handleScan(BarcodeCapture capture) async {
    if (isProcessing) return; // Prevent duplicate reads
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      setState(() => isProcessing = true);
      
      final String code = barcodes.first.rawValue!;
      controller.stop();

      // Submit via Riverpod Provider
      final success = await ref.read(attendanceProvider.notifier).processScan(code);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Attendance Marked Successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Go back to dashboard
      } else {
        final error = ref.read(attendanceProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(error.toString()), backgroundColor: Colors.red),
        );
        setState(() => isProcessing = false);
        controller.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR'), backgroundColor: Colors.transparent),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: handleScan,
          ),
          if (isProcessing)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFCAFD00)),
            ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFCAFD00), width: 3),
                borderRadius: BorderRadius.circular(12)
              ),
            )
          )
        ],
      )
    );
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await controller.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/dio_client.dart';

enum _State { scanning, loading, success, fail }

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});
  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final _ctrl = MobileScannerController(facing: CameraFacing.back, torchEnabled: false);
  _State _st = _State.scanning;
  String _msg = 'Align QR code within the frame';
  Color _frameColor = Colors.white54;

  Future<void> _handle(BarcodeCapture cap) async {
    if (_st != _State.scanning) return;
    final code = cap.barcodes.firstOrNull?.rawValue;
    if (code == null) return;
    _ctrl.stop();
    setState(() { _st = _State.loading; _msg = 'Verifying with server...'; _frameColor = AppColors.lime.withOpacity(0.5); });

    final res = await apiCall(dio.post('/qr/scan', data: {'code_hash': code}));
    if (!mounted) return;

    if (res['success'] == true) {
      setState(() { _st = _State.success; _msg = res['message'] ?? 'Attendance marked!'; _frameColor = AppColors.lime; });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) context.go('/dashboard');
    } else {
      setState(() { _st = _State.fail; _msg = res['message'] ?? 'Invalid QR code'; _frameColor = AppColors.coral; });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) { setState(() { _st = _State.scanning; _msg = 'Try scanning again'; _frameColor = Colors.white54; }); _ctrl.start(); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => context.go('/dashboard')),
        title: Text('Scan QR Code', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(icon: const Icon(Icons.flashlight_on_rounded), onPressed: () => _ctrl.toggleTorch()),
        ],
      ),
      body: Stack(
        children: [
          if (_st != _State.loading) MobileScanner(controller: _ctrl, onDetect: _handle),
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(center: Alignment.center, radius: 0.6, colors: [Colors.transparent, Colors.black.withOpacity(0.7)]),
            ),
          ),
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                width: 260, height: 260,
                decoration: BoxDecoration(
                  border: Border.all(color: _frameColor, width: 2.5),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: _frameColor.withOpacity(0.3), blurRadius: 24, spreadRadius: 2)],
                ),
                child: _BuildInner(_st),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _frameColor.withOpacity(0.3)),
                ),
                child: Text(_msg, style: TextStyle(color: _frameColor, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
}

class _BuildInner extends StatelessWidget {
  final _State st;
  const _BuildInner(this.st, {super.key});
  @override
  Widget build(BuildContext context) {
    if (st == _State.loading) return const Center(child: SizedBox(width: 40, height: 40, child: CircularProgressIndicator(color: AppColors.lime, strokeWidth: 3)));
    if (st == _State.success) return const Center(child: Icon(Icons.check_circle_rounded, color: AppColors.lime, size: 80));
    if (st == _State.fail)    return const Center(child: Icon(Icons.cancel_rounded, color: AppColors.coral, size: 80));
    return const SizedBox.shrink();
  }
}

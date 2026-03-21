import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/app_theme.dart';
import '../../core/api_service.dart';

class QRGeneratorScreen extends StatefulWidget {
  const QRGeneratorScreen({super.key});

  @override
  State<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  String? qrCode;
  int countdown = 30;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _fetchQR();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchQR() async {
    final res = await ApiService.get('/qr/generate');
    if (mounted && res['success'] == true) {
      setState(() {
        qrCode = res['data']['qr_code'];
        countdown = res['data']['expires_in'] ?? 30;
      });
      _startTimer();
    }
  }

  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (countdown > 0) {
        setState(() => countdown--);
      } else {
        t.cancel();
        _fetchQR();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ENTRY QR GENERATOR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('SHOW THIS TO THE MEMBER', style: TextStyle(color: AppColors.secondary, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 40, spreadRadius: 10),
                ],
              ),
              child: qrCode == null
                  ? const SizedBox(width: 250, height: 250, child: Center(child: CircularProgressIndicator()))
                  : QrImageView(
                      data: qrCode!,
                      version: QrVersions.auto,
                      size: 250.0,
                    ),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'REFRESHING IN ${countdown}S',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
            const SizedBox(height: 64),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'This QR code is dynamic and expires every 30 seconds for security.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
  bool isGymClosed = false;
  String closedMessage = '';
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
    if (mounted) {
      if (res['success'] == true) {
        setState(() {
          isGymClosed = false;
          qrCode = res['data']['qr_code'];
          countdown = res['data']['expires_in'] ?? 30;
        });
        _startTimer();
      } else if (res['error_code'] == 'GYM_CLOSED') {
        setState(() {
          isGymClosed = true;
          closedMessage = res['message'] ?? 'Gym is currently closed.';
        });
      }
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
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('ENTRY STATION'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('STATION QR CODE', style: TextStyle(color: AppColors.text3(context), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 8),
              const Text('MEMBER SCAN POINT', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 48),
              
              // QR Container with Glassmorphism
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surf(context),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.surfHigh(context)),
                  boxShadow: [
                    BoxShadow(color: AppColors.primaryGlow.withOpacity(0.15), blurRadius: 40, offset: const Offset(0, 10)),
                  ],
                ),
                child: isGymClosed
                    ? _buildClosedState()
                    : (qrCode == null
                        ? _buildLoadingState()
                        : _buildQRState()),
              ),
              
              const SizedBox(height: 48),
              
              if (!isGymClosed && qrCode != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(color: AppColors.primaryDim, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'RENEWING IN ${countdown}s',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Ensure members scan from their app. Valid for one entry only.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.text3(context), fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      width: 240,
      height: 240,
      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }

  Widget _buildClosedState() {
    return SizedBox(
      width: 240,
      height: 240,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primaryDim, shape: BoxShape.circle),
            child: const Icon(Icons.lock_clock, color: AppColors.primary, size: 48),
          ),
          const SizedBox(height: 24),
          const Text('STATION CLOSED', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary)),
          const SizedBox(height: 8),
          Text(closedMessage, textAlign: TextAlign.center, style: TextStyle(color: AppColors.text3(context), fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildQRState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 8),
      ),
      child: QrImageView(
        data: qrCode!,
        version: QrVersions.auto,
        size: 240.0,
        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/dio_client.dart';

class AdminQrScreen extends ConsumerStatefulWidget {
  const AdminQrScreen({super.key});
  @override
  ConsumerState<AdminQrScreen> createState() => _AdminQrScreenState();
}

class _AdminQrScreenState extends ConsumerState<AdminQrScreen> {
  String? _qrHash;
  int _timeLeft = 0;
  bool _loading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchNextQr();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft <= 1) {
          _fetchNextQr();
          _timeLeft = 30;
        } else {
          _timeLeft--;
        }
      });
    });
  }

  Future<void> _fetchNextQr() async {
    setState(() => _loading = true);
    try {
      final res = await apiCall(dio.get('/qr/generate'));
      if (mounted && res['success'] == true) {
        setState(() {
          _qrHash = res['data']['qr_code'];
          _timeLeft = 30;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _qrHash = null; _timeLeft = 0; });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _timeLeft / 30;
    return Scaffold(
      appBar: AppBar(
        title: Text('Live QR Turnstile', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/admin')),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight, end: Alignment.bottomLeft,
            colors: [Color(0xFF0E120A), AppColors.bg, Color(0xFF080C14)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Auto-refreshes every 30 seconds', 
                          style: TextStyle(color: AppColors.text2, fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 16),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _qrHash != null ? AppTheme.lime.withOpacity(0.6) : Colors.white12,
                              width: _qrHash != null ? 3 : 1,
                            ),
                            boxShadow: _qrHash != null
                                ? [BoxShadow(color: AppTheme.lime.withOpacity(0.2), blurRadius: 40, spreadRadius: 5)]
                                : null,
                          ),
                          child: _loading && _qrHash == null
                              ? const Center(child: CircularProgressIndicator(color: AppTheme.lime))
                              : _qrHash != null
                              ? Center(
                                  child: QrImageView(
                                    data: _qrHash!,
                                    size: 240,
                                    backgroundColor: Colors.white,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.qr_code, color: Colors.grey, size: 60),
                                    const SizedBox(height: 12),
                                    Text('No active QR', style: TextStyle(color: Colors.grey.shade600)),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 28),
                        if (_qrHash != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: AppTheme.surfaceHigh,
                              color: _timeLeft > 5 ? AppTheme.lime : AppTheme.coral,
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Expires in ${_timeLeft}s',
                            style: TextStyle(
                              color: _timeLeft > 5 ? Colors.grey : AppTheme.coral,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Text('Members should scan this code using the Power House App', 
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13), textAlign: TextAlign.center),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'design_system.dart';
import 'app_card.dart';

class StreakPopup extends StatefulWidget {
  final int count;
  final bool isNewRecord;

  const StreakPopup({
    super.key,
    required this.count,
    this.isNewRecord = false,
  });

  static Future<void> show(BuildContext context, int count, bool isNewRecord) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StreakPopup(count: count, isNewRecord: isNewRecord),
    );
  }

  @override
  State<StreakPopup> createState() => _StreakPopupState();
}

class _StreakPopupState extends State<StreakPopup> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    // Auto close after 1.5 seconds (to allow for animation and reading)
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) Navigator.pop(context);
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Material(
            color: Colors.transparent,
            child: AppCard(
              backgroundColor: const Color(0xFF1A1A1A),
              padding: const EdgeInsets.all(AppPadding.p24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.amber, size: 48),
                  AppSpacing.s16,
                  const Text(
                    '+1 DAY ADDED',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 2,
                    ),
                  ),
                  AppSpacing.s8,
                  Text(
                    "YOU'RE ON A ${widget.count} DAY STREAK",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  if (widget.isNewRecord) ...[
                    AppSpacing.s12,
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppRadius.r8),
                      ),
                      child: const Text(
                        'NEW PERSONAL BEST!',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

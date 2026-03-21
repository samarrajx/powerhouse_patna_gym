import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Glassmorphic card widget — the core visual pattern
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? borderRadius;
  final Color? borderColor;
  final VoidCallback? onTap;
  final double blurSigma;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.borderColor,
    this.onTap,
    this.blurSigma = 20,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(borderRadius ?? 18);
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.glass,
              borderRadius: br,
              border: Border.all(color: borderColor ?? AppColors.border, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Status badge pill
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge(this.label, {super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
        ],
      ),
    );
  }
}

/// Big stat card used on dashboards
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final String? sub;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(color: accent.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, color: accent, size: 17),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(label, style: const TextStyle(color: AppColors.text2, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: accent == AppColors.lime ? AppColors.text1 : accent,
            fontSize: 28, fontWeight: FontWeight.w700, fontFamily: 'SpaceGrotesk', letterSpacing: -0.5)),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(sub!, style: const TextStyle(color: AppColors.text2, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}

/// Glowing pulse dot
class PulseDot extends StatefulWidget {
  final Color color;
  const PulseDot({super.key, this.color = AppColors.lime});
  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _anim = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 10, height: 10,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: widget.color.withOpacity(0.6 * (1 - _anim.value)), blurRadius: 12 + 10 * _anim.value, spreadRadius: 2 * _anim.value)],
        ),
      ),
    );
  }
}

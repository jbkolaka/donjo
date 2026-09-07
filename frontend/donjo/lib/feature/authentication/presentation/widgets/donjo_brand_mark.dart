import 'package:flutter/material.dart';
import 'package:donjo/core/theme/app_palette.dart';
import 'package:donjo/core/theme/spacing/app_spacing.dart';

/// Crisp IBM Carbon style geometric brand mark for Donjo.
class DonjoBrandMark extends StatelessWidget {
  const DonjoBrandMark({super.key, this.size = 36, this.showWordmark = false});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: p.buttonPrimary,
        borderRadius: BorderRadius.circular(AppRadius.field),
        boxShadow: [
          BoxShadow(
            color: p.buttonPrimary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'D',
        style: TextStyle(
          color: const Color(0xFF161616),
          fontSize: size * 0.58,
          fontWeight: FontWeight.w900,
          fontFamily: 'IBM Plex Sans',
          letterSpacing: -0.5,
          height: 1,
        ),
      ),
    );

    if (!showWordmark) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        mark,
        const SizedBox(width: AppSpacing.spacing03),
        Text(
          'Donjo',
          style: context.appText.headlineMedium.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: p.textPrimary,
          ),
        ),
      ],
    );
  }
}

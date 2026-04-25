import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class FactChip extends StatelessWidget {
  const FactChip({super.key, required this.fact});
  final String fact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.purpleAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(PhosphorIconsRegular.lightbulb,
              color: Colors.purpleAccent, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fact,
              style: GoogleFonts.inter(
                color: Colors.purpleAccent,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

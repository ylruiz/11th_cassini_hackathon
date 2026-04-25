import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SourceBadge extends StatelessWidget {
  const SourceBadge({super.key, required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(PhosphorIconsRegular.broadcast,
            color: Colors.white24, size: 13),
        const SizedBox(width: 6),
        Text(
          'Data source: $source',
          style: GoogleFonts.inter(
            color: Colors.white24,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

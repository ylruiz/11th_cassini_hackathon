import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class TimelineTabs extends StatelessWidget {
  const TimelineTabs({super.key, required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF00D4FF);
    return Container(
      color: const Color(0xFF060E1A),
      child: TabBar(
        controller: controller,
        indicatorColor: primary,
        labelColor: primary,
        unselectedLabelColor: Colors.white38,
        labelStyle:
            GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w400),
        tabs: [
          Tab(
            icon: Icon(PhosphorIconsRegular.clockCounterClockwise, size: 15),
            text: 'Past',
          ),
          Tab(
            icon: Icon(PhosphorIconsRegular.pulse, size: 15),
            text: 'Now',
          ),
          Tab(
            icon: Icon(PhosphorIconsRegular.trendUp, size: 15),
            text: 'What If',
          ),
        ],
      ),
    );
  }
}

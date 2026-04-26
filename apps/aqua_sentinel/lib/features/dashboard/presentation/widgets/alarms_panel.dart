import 'package:aqua_sentinel/features/alerts/providers/alarms_provider.dart';
import 'package:aqua_sentinel/features/alerts/models/alarm_model.dart';
import 'package:aqua_sentinel/features/dashboard/presentation/widgets/alarm_panel_item.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AlarmsPanel extends ConsumerWidget {
  const AlarmsPanel({
    super.key,
    required this.onClose,
    required this.onSelectAlarm,
  });

  final VoidCallback onClose;
  final void Function(Alarm) onSelectAlarm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAlarms = ref.watch(activeAlarmsProvider);

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black54,
        child: Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 320,
              color: const Color(0xFF0D1B2A),
              child: Column(
                children: [
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF060E1A),
                      border: Border(bottom: BorderSide(color: Colors.white10)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'ACTIVE ALARMS',
                          style: GoogleFonts.spaceGrotesk(
                            color: const Color(0xFF00D4FF),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                        const Spacer(),
                        if (activeAlarms.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF4757)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color(0xFFFF4757)
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              '${activeAlarms.length}',
                              style: GoogleFonts.spaceGrotesk(
                                color: const Color(0xFFFF4757),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(PhosphorIconsRegular.x,
                              color: Colors.white54, size: 18),
                          onPressed: onClose,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: activeAlarms.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  PhosphorIconsRegular.checkCircle,
                                  size: 48,
                                  color: const Color(0xFF00D4FF)
                                      .withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No active alarms',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white54,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: activeAlarms.length,
                            itemBuilder: (context, index) {
                              final alarm = activeAlarms[index];
                              return AlarmPanelItem(
                                alarm: alarm,
                                onTap: () => onSelectAlarm(alarm),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

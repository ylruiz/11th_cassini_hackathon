import 'package:aqua_sentinel/features/alerts/providers/alarms_provider.dart';
import 'package:aqua_sentinel/features/alerts/presentation/widgets/compact_alarm_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Future<void> showAlarmPanel(BuildContext context) async {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (_, scrollController) => AlarmPanelSheet(
        scrollController: scrollController,
      ),
    ),
  );
}

class AlarmPanelSheet extends ConsumerWidget {
  const AlarmPanelSheet({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAlarms = ref.watch(activeAlarmsProvider);
    final soundEnabled = ref.watch(soundEnabledProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1B2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: Color(0xFF00D4FF), width: 1),
          left: BorderSide(color: Color(0xFF00D4FF), width: 1),
          right: BorderSide(color: Color(0xFF00D4FF), width: 1),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Text(
                  'ACTIVE ALARMS',
                  style: GoogleFonts.spaceGrotesk(
                    color: const Color(0xFF00D4FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                if (activeAlarms.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4757).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFFF4757).withValues(alpha: 0.3),
                      ),
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
                  icon: Icon(
                    soundEnabled
                        ? PhosphorIconsRegular.speakerHigh
                        : PhosphorIconsRegular.speakerSlash,
                    color:
                        soundEnabled ? const Color(0xFF00D4FF) : Colors.white38,
                    size: 18,
                  ),
                  onPressed: () => ref
                      .read(soundEnabledProvider.notifier)
                      .state = !soundEnabled,
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
                          color: const Color(0xFF00D4FF).withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No active alarms',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'All systems operating normally',
                          style: GoogleFonts.inter(
                            color: Colors.white30,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: activeAlarms.length,
                    itemBuilder: (context, index) {
                      final alarm = activeAlarms[index];
                      return CompactAlarmCard(
                        alarm: alarm,
                        onAcknowledge: () {
                          ref
                              .read(alarmsProvider.notifier)
                              .acknowledge(alarm.id);
                        },
                        onResolve: () {
                          ref.read(alarmsProvider.notifier).resolve(alarm.id);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

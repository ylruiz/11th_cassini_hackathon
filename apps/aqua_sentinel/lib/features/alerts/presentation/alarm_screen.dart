import 'package:aqua_sentinel/features/alerts/presentation/widgets/alarm_card.dart';
import 'package:aqua_sentinel/features/alerts/presentation/widgets/alarm_panel_sheet.dart';
import 'package:aqua_sentinel/features/alerts/presentation/widgets/empty_state_container.dart';
import 'package:aqua_sentinel/features/alerts/presentation/widgets/compact_alarm_card.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../providers/alarms_provider.dart';

@RoutePage()
class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmsAsync = ref.watch(alarmsProvider);
    final activeAlarms = ref.watch(activeAlarmsProvider);
    final soundEnabled = ref.watch(soundEnabledProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060E1A),
        title: Text(
          'ALARMS',
          style: GoogleFonts.spaceGrotesk(
            color: const Color(0xFF00D4FF),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        leading: IconButton(
          icon:
              const Icon(PhosphorIconsRegular.arrowLeft, color: Colors.white54),
          onPressed: () => context.router.maybePop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              soundEnabled
                  ? PhosphorIconsRegular.speakerHigh
                  : PhosphorIconsRegular.speakerSlash,
              color: soundEnabled ? const Color(0xFF00D4FF) : Colors.white38,
            ),
            onPressed: () =>
                ref.read(soundEnabledProvider.notifier).state = !soundEnabled,
          ),
        ],
      ),
      body: alarmsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00D4FF)),
        ),
        error: (e, _) => Center(
          child: Text(
            'Failed to load alarms',
            style: GoogleFonts.inter(color: Colors.white54),
          ),
        ),
        data: (_) => activeAlarms.isEmpty
            ? const EmptyStateContainer()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: activeAlarms.length,
                itemBuilder: (context, index) {
                  final alarm = activeAlarms[index];
                  return AlarmCard(
                    alarm: alarm,
                    onAcknowledge: () {
                      ref.read(alarmsProvider.notifier).acknowledge(alarm.id);
                    },
                    onResolve: () {
                      ref.read(alarmsProvider.notifier).resolve(alarm.id);
                    },
                  ).animate().fadeIn(delay: Duration(milliseconds: index * 80));
                },
              ),
      ),
    );
  }
}

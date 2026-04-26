import 'package:aqua_sentinel/features/alerts/models/alarm_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AlarmCard extends StatelessWidget {
  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onAcknowledge,
    required this.onResolve,
  });

  final Alarm alarm;
  final VoidCallback onAcknowledge;
  final VoidCallback onResolve;

  Color get _severityColor {
    switch (alarm.severity) {
      case AlarmSeverity.critical:
        return const Color(0xFFFF4757);
      case AlarmSeverity.high:
        return const Color(0xFFFF9F43);
      case AlarmSeverity.medium:
        return const Color(0xFFFECA57);
      case AlarmSeverity.low:
        return const Color(0xFF54A0FF);
    }
  }

  IconData get _typeIcon {
    switch (alarm.type) {
      case AlarmType.waterQuality:
        return PhosphorIconsRegular.drop;
      case AlarmType.flood:
        return PhosphorIconsRegular.drop;
      case AlarmType.environmental:
        return PhosphorIconsRegular.leaf;
      case AlarmType.anomaly:
        return PhosphorIconsRegular.warningDiamond;
    }
  }

  String get _typeLabel {
    switch (alarm.type) {
      case AlarmType.waterQuality:
        return 'WATER QUALITY';
      case AlarmType.flood:
        return 'FLOOD';
      case AlarmType.environmental:
        return 'ENVIRONMENTAL';
      case AlarmType.anomaly:
        return 'ANOMALY';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2133),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _severityColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _severityColor.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _severityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_typeIcon, color: _severityColor, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _typeLabel,
                        style: GoogleFonts.spaceGrotesk(
                          color: _severityColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        alarm.triggeredBy,
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _severityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _severityColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    alarm.severity.name.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      color: _severityColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alarm.message,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      PhosphorIconsRegular.mapPin,
                      color: Colors.white38,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${alarm.location.latitude.toStringAsFixed(2)}°, ${alarm.location.longitude.toStringAsFixed(2)}°',
                      style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      PhosphorIconsRegular.clock,
                      color: Colors.white38,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(alarm.createdAt),
                      style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (alarm.status == AlarmStatus.active) ...[
                      Expanded(
                        child: GestureDetector(
                          onTap: onAcknowledge,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00D4FF)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF00D4FF)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'ACKNOWLEDGE',
                                style: GoogleFonts.spaceGrotesk(
                                  color: const Color(0xFF00D4FF),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: GestureDetector(
                        onTap: onResolve,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Center(
                            child: Text(
                              'RESOLVE',
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} UTC';
    } catch (_) {
      return iso;
    }
  }
}

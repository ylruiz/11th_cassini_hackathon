import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../data/alerts_provider.dart';
import '../models/alert_model.dart';

@RoutePage()
class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsProvider);
    final cs = Theme.of(context).colorScheme;
    final activeCount = alerts.where((a) => a.severity == AlertSeverity.high).length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        title: Row(
          children: [
            PhosphorIcon(PhosphorIcons.warning(), color: cs.error),
            const SizedBox(width: 8),
            const Text('Flood & Disaster Alerts'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AlertBanner(activeCount: activeCount)
              .animate()
              .fadeIn(duration: 300.ms),
          const SizedBox(height: 16),
          ...alerts.asMap().entries.map(
                (e) => _AlertCard(alert: e.value)
                    .animate()
                    .fadeIn(delay: (100 * (e.key + 1)).ms),
              ),
        ],
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.activeCount});
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    final hasAlerts = activeCount > 0;
    final color = hasAlerts
        ? Theme.of(context).colorScheme.error
        : Colors.greenAccent;
    final message = hasAlerts
        ? '$activeCount High-severity alert${activeCount == 1 ? '' : 's'}'
        : 'No critical alerts right now';

    return Card(
      color: color.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            PhosphorIcon(
              hasAlerts ? PhosphorIcons.warningCircle() : PhosphorIcons.checkCircle(),
              color: color,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                  const Text(
                    'Copernicus EMS — Live monitoring active',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});
  final AlertModel alert;

  Color _severityColor(BuildContext context) => switch (alert.severity) {
        AlertSeverity.high => Theme.of(context).colorScheme.error,
        AlertSeverity.medium => Colors.orangeAccent,
        AlertSeverity.low => Colors.yellowAccent,
      };

  String _severityLabel() => switch (alert.severity) {
        AlertSeverity.high => 'HIGH',
        AlertSeverity.medium => 'MEDIUM',
        AlertSeverity.low => 'LOW',
      };

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    _severityLabel(),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                ),
                const SizedBox(width: 8),
                Text(alert.issueType,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            // Plain-language description
            Text(
              alert.description,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                PhosphorIcon(PhosphorIcons.mapPin(),
                    size: 13,
                    color: Theme.of(context).colorScheme.tertiary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    alert.region,
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.tertiary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                PhosphorIcon(PhosphorIconsRegular.broadcast,
                    size: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .tertiary
                        .withValues(alpha: 0.7)),
                const SizedBox(width: 4),
                Text(
                  alert.source,
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .tertiary
                          .withValues(alpha: 0.7)),
                ),
                const Spacer(),
                Text(
                  alert.timestamp,
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .tertiary
                          .withValues(alpha: 0.5)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

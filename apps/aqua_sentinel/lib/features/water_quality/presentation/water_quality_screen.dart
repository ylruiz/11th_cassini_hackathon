import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../impact/providers/impact_provider.dart';
import '../../impact/models/impact_data.dart';
import '../data/water_quality_provider.dart';
import '../models/water_quality_data.dart';

@RoutePage()
class WaterQualityScreen extends StatelessWidget {
  const WaterQualityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF050505),
      body: WaterQualityView(),
    );
  }
}

class WaterQualityView extends ConsumerWidget {
  const WaterQualityView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedQualityBodyProvider);
    final data = ref.watch(waterQualityProvider(selectedId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _WqHeader(),
        const _BodySelector(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _OverallStatusCard(selectedId: selectedId, data: data)
                  .animate()
                  .fadeIn(duration: 400.ms),
              const SizedBox(height: 16),
              _IndicatorsSection(data: data)
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 80.ms),
              const SizedBox(height: 16),
              if (data.sectorImpacts.isNotEmpty) ...[
                _SectorImpactsSection(data: data)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 160.ms),
                const SizedBox(height: 16),
              ],
              if (data.pollutionEvents.isNotEmpty) ...[
                _PollutionEventsSection(data: data)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 240.ms),
                const SizedBox(height: 16),
              ],
              const _SourceFooter()
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 320.ms),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _WqHeader extends StatelessWidget {
  const _WqHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF060E1A),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4FF).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.3)),
            ),
            child: const Icon(PhosphorIconsRegular.drop,
                color: Color(0xFF00D4FF), size: 16),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WATER QUALITY',
                style: GoogleFonts.spaceGrotesk(
                  color: const Color(0xFF00D4FF),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'Sentinel-2 · Sentinel-3 · CMEMS · Copernicus C3S',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Body selector chips ──────────────────────────────────────────────────────

class _BodySelector extends ConsumerWidget {
  const _BodySelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedQualityBodyProvider);
    final scores = ref.watch(waterBodyRiskProvider);

    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFF060E1A),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: scores.length,
        itemBuilder: (context, i) {
          final score = scores[i];
          final isSelected = score.waterBodyId == selected;
          final color = _tierColor(score.tier);

          return GestureDetector(
            onTap: () => ref.read(selectedQualityBodyProvider.notifier).state =
                score.waterBodyId,
            child: AnimatedContainer(
              duration: 200.ms,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.15)
                    : const Color(0xFF0D1B2A),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? color : Colors.white12,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    score.waterBodyName,
                    style: GoogleFonts.inter(
                      color: isSelected ? Colors.white : Colors.white54,
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${score.riskScore}',
                    style: GoogleFonts.spaceGrotesk(
                      color: isSelected ? color : color.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _tierColor(RiskTier tier) => switch (tier) {
        RiskTier.low => const Color(0xFF2ED573),
        RiskTier.moderate => const Color(0xFFFECA57),
        RiskTier.high => const Color(0xFFFF9F43),
        RiskTier.critical => const Color(0xFFFF4757),
      };
}

// ─── Overall status card ──────────────────────────────────────────────────────

class _OverallStatusCard extends ConsumerWidget {
  const _OverallStatusCard({required this.selectedId, required this.data});
  final String selectedId;
  final WaterQualityData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scores = ref.watch(waterBodyRiskProvider);
    final score = scores.firstWhere((s) => s.waterBodyId == selectedId,
        orElse: () => scores.first);
    final color = _tierColor(score.tier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  score.tier.displayName,
                  style: GoogleFonts.spaceGrotesk(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${score.riskScore}',
                style: GoogleFonts.spaceGrotesk(
                  color: color,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                ' / 100',
                style: GoogleFonts.spaceGrotesk(
                  color: color.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                'Risk Score',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: score.riskScore / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.07),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            score.primaryThreat,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          if (data.monthDeltaLabel.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(PhosphorIconsRegular.arrowUp,
                    color: Colors.white38, size: 12),
                const SizedBox(width: 5),
                Text(
                  data.monthDeltaLabel,
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(PhosphorIconsRegular.users, color: Colors.white30, size: 12),
              const SizedBox(width: 5),
              Text(
                '${_formatPop(score.populationAtRisk)} people at risk',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(width: 16),
              Icon(PhosphorIconsRegular.clock, color: Colors.white30, size: 12),
              const SizedBox(width: 5),
              Text(
                score.lastUpdated,
                style: GoogleFonts.inter(color: Colors.white30, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _tierColor(RiskTier tier) => switch (tier) {
        RiskTier.low => const Color(0xFF2ED573),
        RiskTier.moderate => const Color(0xFFFECA57),
        RiskTier.high => const Color(0xFFFF9F43),
        RiskTier.critical => const Color(0xFFFF4757),
      };

  String _formatPop(int pop) {
    if (pop >= 1000000) return '${(pop / 1000000).toStringAsFixed(1)}M';
    if (pop >= 1000) return '${(pop / 1000).round()}K';
    return '$pop';
  }
}

// ─── Indicators section ───────────────────────────────────────────────────────

class _IndicatorsSection extends StatelessWidget {
  const _IndicatorsSection({required this.data});
  final WaterQualityData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: PhosphorIconsRegular.flask,
          title: 'QUALITY INDICATORS',
          subtitle: 'Measured via satellite + ground sensors',
        ),
        const SizedBox(height: 10),
        ...data.indicators.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _IndicatorCard(indicator: e.value)
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: e.key * 60)),
              ),
            ),
      ],
    );
  }
}

class _IndicatorCard extends StatelessWidget {
  const _IndicatorCard({required this.indicator});
  final WaterIndicator indicator;

  Color get _statusColor => switch (indicator.status) {
        IndicatorStatus.good => const Color(0xFF2ED573),
        IndicatorStatus.warning => const Color(0xFFFF9F43),
        IndicatorStatus.danger => const Color(0xFFFF4757),
      };

  String get _statusLabel => switch (indicator.status) {
        IndicatorStatus.good => 'SAFE',
        IndicatorStatus.warning => 'CAUTION',
        IndicatorStatus.danger => 'UNSAFE',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _statusColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 32,
                decoration: BoxDecoration(
                  color: _statusColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      indicator.label,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      indicator.value,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border:
                      Border.all(color: _statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  _statusLabel,
                  style: GoogleFonts.spaceGrotesk(
                    color: _statusColor,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            indicator.plainDescription,
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 11,
              height: 1.45,
            ),
          ),
          if (indicator.affectedGroups != null ||
              indicator.trendLabel != null) ...[
            const SizedBox(height: 6),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 6),
            if (indicator.affectedGroups != null)
              Row(
                children: [
                  const Icon(PhosphorIconsRegular.users,
                      color: Colors.white30, size: 11),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Affects: ${indicator.affectedGroups}',
                      style: GoogleFonts.inter(
                          color: Colors.white30, fontSize: 10),
                    ),
                  ),
                ],
              ),
            if (indicator.trendLabel != null) ...[
              if (indicator.affectedGroups != null) const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(PhosphorIconsRegular.arrowUp,
                      color: Colors.white30, size: 11),
                  const SizedBox(width: 4),
                  Text(
                    indicator.trendLabel!,
                    style:
                        GoogleFonts.inter(color: Colors.white30, fontSize: 10),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ─── Sector impacts section ───────────────────────────────────────────────────

class _SectorImpactsSection extends StatelessWidget {
  const _SectorImpactsSection({required this.data});
  final WaterQualityData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: PhosphorIconsRegular.buildings,
          title: 'WHAT THIS MEANS',
          subtitle: 'Impact by sector — who is affected and what to do',
        ),
        const SizedBox(height: 10),
        ...data.sectorImpacts.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SectorImpactCard(impact: e.value)
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: e.key * 60)),
              ),
            ),
      ],
    );
  }
}

class _SectorImpactCard extends StatelessWidget {
  const _SectorImpactCard({required this.impact});
  final WaterQualitySectorImpact impact;

  Color get _statusColor => switch (impact.status) {
        IndicatorStatus.good => const Color(0xFF2ED573),
        IndicatorStatus.warning => const Color(0xFFFF9F43),
        IndicatorStatus.danger => const Color(0xFFFF4757),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  impact.sectorName.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    color: _statusColor,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (impact.actionRequired) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4757).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: const Color(0xFFFF4757).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(PhosphorIconsRegular.warning,
                          color: Color(0xFFFF4757), size: 9),
                      const SizedBox(width: 3),
                      Text(
                        'ACTION REQUIRED',
                        style: GoogleFonts.spaceGrotesk(
                          color: const Color(0xFFFF4757),
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            impact.headline,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            impact.detail,
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pollution events section ─────────────────────────────────────────────────

class _PollutionEventsSection extends StatelessWidget {
  const _PollutionEventsSection({required this.data});
  final WaterQualityData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: PhosphorIconsRegular.warning,
          title: 'REPORTED CONCERNS',
          subtitle: 'Detected by satellite or field sensors',
        ),
        const SizedBox(height: 10),
        ...data.pollutionEvents.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PollutionEventCard(event: e.value)
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: e.key * 60)),
              ),
            ),
      ],
    );
  }
}

class _PollutionEventCard extends StatelessWidget {
  const _PollutionEventCard({required this.event});
  final WaterPollutionEvent event;

  Color get _statusColor => switch (event.status) {
        IndicatorStatus.good => const Color(0xFF2ED573),
        IndicatorStatus.warning => const Color(0xFFFF9F43),
        IndicatorStatus.danger => const Color(0xFFFF4757),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _statusColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIconsRegular.mapPin, color: _statusColor, size: 12),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  event.location,
                  style: GoogleFonts.spaceGrotesk(
                    color: _statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            event.description,
            style: GoogleFonts.inter(
              color: Colors.white60,
              fontSize: 11,
              height: 1.45,
            ),
          ),
          if (event.affectedPopulation != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(PhosphorIconsRegular.users,
                    color: Colors.white30, size: 11),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    event.affectedPopulation!,
                    style:
                        GoogleFonts.inter(color: Colors.white30, fontSize: 10),
                  ),
                ),
              ],
            ),
          ],
          if (event.recommendedAction != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF00D4FF).withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                    color: const Color(0xFF00D4FF).withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(PhosphorIconsRegular.arrowRight,
                      color: Color(0xFF00D4FF), size: 12),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      event.recommendedAction!,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF00D4FF),
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00D4FF), size: 13),
        const SizedBox(width: 7),
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            subtitle,
            style: GoogleFonts.inter(color: Colors.white30, fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _SourceFooter extends StatelessWidget {
  const _SourceFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF060E1A),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: const Color(0xFF00D4FF).withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
                color: Color(0xFF00D4FF), shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            'Powered by Copernicus · Galileo HAS · EGNOS · CMEMS · Copernicus C3S',
            style: GoogleFonts.inter(color: Colors.white30, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

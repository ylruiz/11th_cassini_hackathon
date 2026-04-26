import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class Footer extends StatelessWidget {
  const Footer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF00D4FF).withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIconsRegular.mapTrifold,
            color: const Color(0xFF00D4FF).withValues(alpha: 0.5),
            size: 13,
          ),
          const SizedBox(width: 6),
          Text(
            'OpenStreetMap',
            style: TextStyle(
              color: const Color(0xFF00D4FF).withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            PhosphorIconsRegular.mapPin,
            color: const Color(0xFF00D4FF).withValues(alpha: 0.7),
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            'Galileo / EGNOS',
            style: TextStyle(
              color: const Color(0xFF00D4FF).withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            PhosphorIconsRegular.broadcast,
            color: const Color(0xFF00D4FF).withValues(alpha: 0.7),
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            'Copernicus Sentinel-2',
            style: TextStyle(
              color: const Color(0xFF00D4FF).withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

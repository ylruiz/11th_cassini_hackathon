import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/alerts/data/alarms_provider.dart';
import '../../features/alerts/models/alarm_model.dart';

final flutterSoundProvider = Provider<FlutterSoundHelper>((ref) {
  final helper = FlutterSoundHelper();
  ref.onDispose(() => helper.dispose());
  return helper;
});

class FlutterSoundHelper {
  FlutterSoundHelper() : _player = FlutterSoundPlayer();

  final FlutterSoundPlayer _player;
  bool _isInitialized = false;
  StreamController<FoodData>? _streamController;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _player.openPlayer();
    _isInitialized = true;
  }

  Future<void> playAlarmSound(AlarmSeverity severity) async {
    if (!_isInitialized) await initialize();

    final frequencies = _getToneFrequencies(severity);
    final sampleRate = 44100;
    final durationMs = severity == AlarmSeverity.critical ? 600 : 300;
    final numSamples = (sampleRate * durationMs ~/ 1000);

    final repeatCount = severity == AlarmSeverity.critical ? 3 : 1;
    final gapMs = severity == AlarmSeverity.critical ? 80 : 0;

    for (int i = 0; i < repeatCount; i++) {
      await _playTone(frequencies, numSamples, sampleRate);
      if (i < repeatCount - 1 && gapMs > 0) {
        await Future.delayed(Duration(milliseconds: gapMs));
      }
    }
  }

  List<double> _getToneFrequencies(AlarmSeverity severity) {
    switch (severity) {
      case AlarmSeverity.critical:
        return [880.0, 1100.0];
      case AlarmSeverity.high:
        return [660.0, 880.0];
      case AlarmSeverity.medium:
        return [440.0, 660.0];
      case AlarmSeverity.low:
        return [440.0];
    }
  }

  Future<void> _playTone(
      List<double> frequencies, int numSamples, int sampleRate) async {
    final pcmData = List<int>.generate(numSamples, (i) {
      double sample = 0.0;
      for (final freq in frequencies) {
        final envelope = (i / numSamples);
        sample +=
            0.25 * envelope * _sin(2 * 3.14159265359 * freq * i / sampleRate);
      }
      return (sample * 32767).clamp(-32768, 32767).round();
    });

    final wavBytes = _buildWavBytes(pcmData, sampleRate);

    await _player.startPlayer(
      codec: Codec.pcm16,
      fromDataBuffer: wavBytes,
      sampleRate: sampleRate,
      numChannels: 1,
    );

    while (_player.isPlaying) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  double _sin(double x) {
    x = x % (2 * 3.14159265359);
    if (x < 0) x += 2 * 3.14159265359;
    double result = 0;
    double term = x;
    for (int n = 1; n <= 10; n++) {
      result += term;
      term *= -x * x / ((2 * n) * (2 * n + 1));
    }
    return result;
  }

  Uint8List _buildWavBytes(List<int> pcmData, int sampleRate) {
    final numChannels = 1;
    final bitsPerSample = 16;
    final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    final blockAlign = numChannels * bitsPerSample ~/ 8;
    final dataSize = pcmData.length * blockAlign;
    final totalSize = 44 + dataSize;

    final buffer = ByteData(totalSize);
    int offset = 0;

    buffer.setUint8(offset++, 0x52);
    buffer.setUint8(offset++, 0x49);
    buffer.setUint8(offset++, 0x46);
    buffer.setUint8(offset++, 0x46);
    buffer.setUint32(offset, totalSize - 8, Endian.little);
    offset += 4;
    buffer.setUint8(offset++, 0x57);
    buffer.setUint8(offset++, 0x41);
    buffer.setUint8(offset++, 0x56);
    buffer.setUint8(offset++, 0x45);
    buffer.setUint8(offset++, 0x66);
    buffer.setUint8(offset++, 0x6D);
    buffer.setUint8(offset++, 0x74);
    buffer.setUint8(offset++, 0x20);
    buffer.setUint32(offset, 16, Endian.little);
    offset += 4;
    buffer.setUint16(offset, 1, Endian.little);
    offset += 2;
    buffer.setUint16(offset, numChannels, Endian.little);
    offset += 2;
    buffer.setUint32(offset, sampleRate, Endian.little);
    offset += 4;
    buffer.setUint32(offset, byteRate, Endian.little);
    offset += 4;
    buffer.setUint16(offset, blockAlign, Endian.little);
    offset += 2;
    buffer.setUint16(offset, bitsPerSample, Endian.little);
    offset += 2;
    buffer.setUint8(offset++, 0x64);
    buffer.setUint8(offset++, 0x61);
    buffer.setUint8(offset++, 0x74);
    buffer.setUint8(offset++, 0x61);
    buffer.setUint32(offset, dataSize, Endian.little);
    offset += 4;

    for (final sample in pcmData) {
      buffer.setInt16(offset, sample, Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }

  Future<void> dispose() async {
    if (_isInitialized) {
      await _player.closePlayer();
      _isInitialized = false;
    }
    _streamController?.close();
  }
}

void playAlarmBeep(AlarmSeverity severity, WidgetRef ref) {
  final soundEnabled = ref.read(soundEnabledProvider);
  if (!soundEnabled) return;

  final helper = ref.read(flutterSoundProvider);
  helper.playAlarmSound(severity);

  if (severity == AlarmSeverity.critical || severity == AlarmSeverity.high) {
    HapticFeedback.heavyImpact();
  } else {
    HapticFeedback.mediumImpact();
  }
}

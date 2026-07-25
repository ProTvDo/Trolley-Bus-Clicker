import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

enum ToneShape { sine, square, sawtooth }

/// Procedurally synthesizes short WAV clips (no bundled sound assets),
/// mirroring the WebAudio oscillator/noise beeps of the original web game.
class SoundEngine {
  SoundEngine() {
    for (var i = 0; i < _poolSize; i++) {
      _players.add(AudioPlayer()..setReleaseMode(ReleaseMode.stop));
    }
  }

  static const _sampleRate = 22050;
  static const _poolSize = 4;
  final List<AudioPlayer> _players = [];
  int _next = 0;
  bool muted = false;

  Future<void> _playBytes(Uint8List bytes) async {
    if (muted) return;
    final player = _players[_next];
    _next = (_next + 1) % _poolSize;
    await player.play(BytesSource(bytes, mimeType: 'audio/wav'));
  }

  Uint8List _tone(double freq, double dur, ToneShape shape, double gain, {double? glideTo}) {
    final n = (dur * _sampleRate).round();
    final samples = Int16List(n);
    for (var i = 0; i < n; i++) {
      final t = i / _sampleRate;
      final progress = n <= 1 ? 0.0 : i / (n - 1);
      final f = glideTo == null ? freq : freq * pow(glideTo / freq, progress);
      final phase = 2 * pi * f * t;
      double raw;
      switch (shape) {
        case ToneShape.sine:
          raw = sin(phase);
          break;
        case ToneShape.square:
          raw = sin(phase) >= 0 ? 1.0 : -1.0;
          break;
        case ToneShape.sawtooth:
          final cyc = (f * t) % 1.0;
          raw = 2 * cyc - 1;
          break;
      }
      // simple attack/decay envelope similar to the linear/exponential ramps used in JS
      final attack = min(1.0, i / (0.01 * _sampleRate));
      final decay = pow(1 - progress, 2).toDouble();
      final env = min(attack, decay);
      samples[i] = (raw * gain * env * 32767).clamp(-32768, 32767).toInt();
    }
    return _wrapWav(samples);
  }

  Uint8List _noiseBurst(double dur, double gain) {
    final n = (dur * _sampleRate).round();
    final rng = Random();
    final samples = Int16List(n);
    for (var i = 0; i < n; i++) {
      final decay = 1 - i / n;
      final v = (rng.nextDouble() * 2 - 1) * decay * gain;
      samples[i] = (v * 32767).clamp(-32768, 32767).toInt();
    }
    return _wrapWav(samples);
  }

  Uint8List _wrapWav(Int16List samples) {
    final byteData = ByteData(44 + samples.length * 2);
    final dataLen = samples.length * 2;
    void writeStr(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        byteData.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    writeStr(0, 'RIFF');
    byteData.setUint32(4, 36 + dataLen, Endian.little);
    writeStr(8, 'WAVE');
    writeStr(12, 'fmt ');
    byteData.setUint32(16, 16, Endian.little);
    byteData.setUint16(20, 1, Endian.little); // PCM
    byteData.setUint16(22, 1, Endian.little); // mono
    byteData.setUint32(24, _sampleRate, Endian.little);
    byteData.setUint32(28, _sampleRate * 2, Endian.little);
    byteData.setUint16(32, 2, Endian.little);
    byteData.setUint16(34, 16, Endian.little);
    writeStr(36, 'data');
    byteData.setUint32(40, dataLen, Endian.little);
    for (var i = 0; i < samples.length; i++) {
      byteData.setInt16(44 + i * 2, samples[i], Endian.little);
    }
    return byteData.buffer.asUint8List();
  }

  void tap() => _playBytes(_tone(520, 0.06, ToneShape.square, 0.5));

  void buzz() => _playBytes(_noiseBurst(0.35, 0.9));

  void success() {
    _playBytes(_tone(660, 0.09, ToneShape.sine, 0.6));
    Future.delayed(const Duration(milliseconds: 90), () {
      _playBytes(_tone(880, 0.14, ToneShape.sine, 0.6));
    });
  }

  void loseLife() => _playBytes(_tone(220, 0.25, ToneShape.sawtooth, 0.5, glideTo: 110));

  /// A physical thud, distinct from [buzz]'s electrical crackle - for
  /// driving into a parked car rather than merely losing wire contact.
  void crash() {
    _playBytes(_noiseBurst(0.28, 0.9));
    Future.delayed(const Duration(milliseconds: 40), () {
      _playBytes(_tone(140, 0.22, ToneShape.sawtooth, 0.5, glideTo: 60));
    });
  }

  void gameOver() => _playBytes(_tone(300, 0.3, ToneShape.sawtooth, 0.4, glideTo: 90));

  void dispose() {
    for (final p in _players) {
      p.dispose();
    }
  }
}

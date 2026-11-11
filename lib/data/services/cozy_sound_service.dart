import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

import '../../domain/models/catalog.dart';
import '../../domain/models/game_state.dart';

/// Pure-Dart procedural PCM WAV audio engine for Solville:
/// 1. Tactile cozy one-shot SFX (dig, plant, water, harvest, coins, trophies)
/// 2. Seamless-looping soothing background soundscapes (`BgmTrack.sunnyLullaby`,
///    `BgmTrack.morningMeadow`, `BgmTrack.cozyRain`) synthesized with a 1.6s
///    raised-cosine overlap crossfade so loop wrap-around is 100% click-free.
///
/// Uses trigonometric phasor rotation and geometric decay recurrences to
/// synthesize 16-second loops in ~1–2 ms without per-sample transcendental calls.
class CozySoundService {
  CozySoundService({
    this.sfxEnabled = true,
    this.bgmTrack = BgmTrack.sunnyLullaby,
    this.bgmVolume = 0.38,
    this.silentPlatformOutput = false,
  });

  static const int _sampleRate = 22050;

  bool sfxEnabled;
  BgmTrack bgmTrack;
  double bgmVolume;

  /// When `true` (e.g. in headless widget tests), state & WAV synthesis still
  /// work without invoking native `AudioPlayer` platform channels.
  final bool silentPlatformOutput;

  bool _initialized = false;
  bool _bgmPlaying = false;
  BgmTrack? _loadedBgmTrack;

  final List<AudioPlayer> _sfxPool = <AudioPlayer>[];
  int _poolCursor = 0;
  AudioPlayer? _bgmPlayer;
  StreamSubscription<PlayerState>? _bgmStateSub;

  static final AudioContext _bgmAudioContext = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.gain,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.ambient,
      options: const <AVAudioSessionOptions>{
        AVAudioSessionOptions.mixWithOthers,
      },
    ),
  );

  static final AudioContext _sfxAudioContext = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.game,
      // Crucial on Android: never steal audio focus from the looping BGM player.
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.ambient,
      options: const <AVAudioSessionOptions>{
        AVAudioSessionOptions.mixWithOthers,
      },
    ),
  );

  // Static process-wide caches so WAV synthesis happens at most once per track/SFX.
  static final Map<SimEventType, Uint8List> _cachedSfx =
      <SimEventType, Uint8List>{};
  static final Map<BgmTrack, Uint8List> _cachedBgm = <BgmTrack, Uint8List>{};

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    if (_cachedSfx.isNotEmpty) return;

    _cachedSfx[SimEventType.dig] = _buildNotesWav(const <_Note>[
      _Note(185, 0.055, 0.28),
      _Note(145, 0.065, 0.22),
    ]);
    _cachedSfx[SimEventType.plant] = _buildNotesWav(const <_Note>[
      _Note(440, 0.055, 0.24),
      _Note(587.33, 0.08, 0.26),
    ]);
    _cachedSfx[SimEventType.water] = _buildNotesWav(const <_Note>[
      _Note(523.25, 0.045, 0.22),
      _Note(659.25, 0.055, 0.24),
      _Note(783.99, 0.07, 0.20),
    ]);
    _cachedSfx[SimEventType.refill] = _buildNotesWav(const <_Note>[
      _Note(392.0, 0.05, 0.24),
      _Note(523.25, 0.06, 0.26),
      _Note(659.25, 0.07, 0.26),
      _Note(783.99, 0.09, 0.24),
    ]);
    _cachedSfx[SimEventType.compost] = _buildNotesWav(const <_Note>[
      _Note(493.88, 0.06, 0.24),
      _Note(739.99, 0.10, 0.25),
    ]);
    _cachedSfx[SimEventType.harvest] = _buildNotesWav(const <_Note>[
      _Note(523.25, 0.06, 0.28),
      _Note(659.25, 0.11, 0.30),
    ]);
    _cachedSfx[SimEventType.coinsEarned] = _buildNotesWav(const <_Note>[
      _Note(880.0, 0.055, 0.25),
      _Note(1174.66, 0.12, 0.28),
    ]);
    _cachedSfx[SimEventType.shopPurchase] = _buildNotesWav(const <_Note>[
      _Note(587.33, 0.06, 0.25),
      _Note(783.99, 0.07, 0.26),
      _Note(987.77, 0.11, 0.26),
    ]);
    _cachedSfx[SimEventType.trophyUnlocked] = _buildNotesWav(const <_Note>[
      _Note(523.25, 0.08, 0.30),
      _Note(659.25, 0.08, 0.30),
      _Note(783.99, 0.09, 0.32),
      _Note(1046.50, 0.20, 0.34),
    ]);
    _cachedSfx[SimEventType.newDay] = _cachedSfx[SimEventType.trophyUnlocked]!;
  }

  /// Starts or switches the soothing background soundscape.
  Future<void> applyBgmSettings({BgmTrack? track, double? volume}) async {
    if (track != null) bgmTrack = track;
    if (volume != null) bgmVolume = volume.clamp(0.0, 1.0);

    if (bgmTrack == BgmTrack.off || bgmVolume <= 0.01) {
      _bgmPlaying = false;
      if (!silentPlatformOutput) {
        try {
          await _bgmPlayer?.stop();
        } catch (_) {}
      }
      return;
    }

    if (silentPlatformOutput) {
      _loadedBgmTrack = bgmTrack;
      _bgmPlaying = true;
      return;
    }

    try {
      if (_bgmPlayer == null) {
        final player = AudioPlayer();
        await player.setAudioContext(_bgmAudioContext);
        await player.setReleaseMode(ReleaseMode.loop);
        _bgmStateSub = player.onPlayerStateChanged.listen((state) {
          if (state == PlayerState.paused ||
              state == PlayerState.stopped ||
              state == PlayerState.completed) {
            _bgmPlaying = false;
          }
        });
        _bgmPlayer = player;
      } else {
        await _bgmPlayer!.setReleaseMode(ReleaseMode.loop);
      }
      await _bgmPlayer!.setVolume(bgmVolume);

      if (!_bgmPlaying || _loadedBgmTrack != bgmTrack) {
        final bytes = _getOrBuildBgmWav(bgmTrack);
        _loadedBgmTrack = bgmTrack;
        _bgmPlaying = true;
        await _bgmPlayer!.play(BytesSource(bytes), volume: bgmVolume);
      }
    } catch (_) {
      // Browser autoplay restriction before first gesture or headless test;
      // will automatically retry on first pointer tap via [ensureBgmActive].
      _bgmPlaying = false;
    }
  }

  /// Pauses looping BGM cleanly when the app moves to the background.
  Future<void> pauseBgm() async {
    _bgmPlaying = false;
    if (silentPlatformOutput) return;
    try {
      await _bgmPlayer?.pause();
    } catch (_) {}
  }

  /// Called on user interaction (or app resume) so background ambience starts
  /// or recovers seamlessly after interruptions (e.g. rewarded ads).
  Future<void> ensureBgmActive() async {
    if (bgmTrack != BgmTrack.off && !_bgmPlaying && bgmVolume > 0.01) {
      await applyBgmSettings();
    }
  }

  Future<void> playForEvent(SimEventType type) async {
    if (!sfxEnabled || silentPlatformOutput) return;
    initialize();
    final bytes = _cachedSfx[type];
    if (bytes == null) return;

    try {
      if (_sfxPool.length < 4) {
        final p = AudioPlayer();
        await p.setAudioContext(_sfxAudioContext);
        await p.setReleaseMode(ReleaseMode.stop);
        _sfxPool.add(p);
      }
      final player = _sfxPool[_poolCursor % _sfxPool.length];
      _poolCursor = (_poolCursor + 1) % _sfxPool.length;
      await player.play(BytesSource(bytes), volume: 0.42);
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _bgmStateSub?.cancel();
    _bgmStateSub = null;
    for (final p in _sfxPool) {
      try {
        await p.dispose();
      } catch (_) {}
    }
    _sfxPool.clear();
    try {
      await _bgmPlayer?.dispose();
    } catch (_) {}
    _bgmPlayer = null;
  }

  // ---------------------------------------------------------------------------
  // Seamless Soothing Soundscape Synthesis (Phasor-Accelerated)
  // ---------------------------------------------------------------------------

  /// Synthesizes (or returns cached) RIFF PCM WAV bytes for [track].
  Uint8List synthesizeTrackWav(BgmTrack track) => _getOrBuildBgmWav(track);

  Uint8List _getOrBuildBgmWav(BgmTrack track) {
    final existing = _cachedBgm[track];
    if (existing != null) return existing;

    final built = switch (track) {
      BgmTrack.sunnyLullaby => _buildSunnyLullabyLoop(),
      BgmTrack.morningMeadow => _buildMorningMeadowLoop(),
      BgmTrack.cozyRain => _buildCozyRainLoop(),
      BgmTrack.off => Uint8List(0),
    };
    _cachedBgm[track] = built;
    return built;
  }

  /// 16-second warm acoustic nylon/kalimba lullaby (`Fmaj7 -> Cmaj7 -> Dm9 -> Bbmaj7`)
  /// over a soft warm pad & whisper breeze.
  Uint8List _buildSunnyLullabyLoop() {
    const loopSec = 16.0;
    const overlapSec = 1.6;
    const totalSec = loopSec + overlapSec;
    final totalSamples = (totalSec * _sampleRate).round();
    final raw = Float64List(totalSamples);

    const chords = <List<double>>[
      <double>[174.61, 220.00, 261.63, 329.63], // Fmaj7
      <double>[130.81, 196.00, 246.94, 329.63], // Cmaj7
      <double>[146.83, 220.00, 261.63, 329.63], // Dm9
      <double>[116.54, 174.61, 220.00, 293.66], // Bbmaj7
      <double>[174.61, 220.00, 261.63, 329.63], // Bar 5 overlap = Bar 1!
    ];

    // 1. Warm breathing pad chords (phasor-rotated per voice + window phasor)
    for (var bar = 0; bar < chords.length; bar++) {
      final barStart = bar * 4.0;
      if (barStart >= totalSec) break;
      final chord = chords[bar];
      final startIdx = ((barStart - 0.5).clamp(0.0, totalSec) * _sampleRate)
          .round();
      final endIdx = ((barStart + 4.5).clamp(0.0, totalSec) * _sampleRate)
          .round();
      final span = math.max(1, endIdx - startIdx);

      final winAngleStep = 2.0 * math.pi / span;
      final winCosStep = math.cos(winAngleStep);
      final winSinStep = math.sin(winAngleStep);

      for (final freq in chord) {
        final omega = 2.0 * math.pi * freq / _sampleRate;
        final cosStep = math.cos(omega);
        final sinStep = math.sin(omega);
        final t0 = startIdx / _sampleRate;
        var s = math.sin(2.0 * math.pi * freq * t0);
        var c = math.cos(2.0 * math.pi * freq * t0);

        var winC = 1.0;
        var winS = 0.0;

        for (var i = startIdx; i < endIdx; i++) {
          final win = 0.5 - 0.5 * winC;
          raw[i] += s * 0.032 * win;

          final nextS = s * cosStep + c * sinStep;
          c = c * cosStep - s * sinStep;
          s = nextS;

          final nextWinC = winC * winCosStep - winS * winSinStep;
          winS = winS * winCosStep + winC * winSinStep;
          winC = nextWinC;
        }
      }
    }

    // 2. Soft fingerpicked nylon arpeggio notes
    const pattern = <int>[0, 2, 1, 3, 2, 1, 3, 2];
    const stepSec = 0.5;
    final totalSteps = (totalSec / stepSec).floor();
    for (var step = 0; step < totalSteps; step++) {
      final bar = (step ~/ 8) % 4;
      final noteFreq = chords[bar][pattern[step % pattern.length]] * 2.0;
      final noteStartSec = step * stepSec;
      if (bar.isOdd && step % 8 >= 6) continue;

      _mixPluckedWarmNote(
        raw,
        startSec: noteStartSec,
        durationSec: 1.35,
        freqHz: noteFreq,
        amplitude: 0.105,
      );
    }

    // 3. Whisper-soft low-pass meadow air
    final rng = math.Random(101);
    var lp = 0.0;
    for (var i = 0; i < totalSamples; i++) {
      final white = rng.nextDouble() * 2.0 - 1.0;
      lp = lp * 0.965 + white * 0.035;
      raw[i] += lp * 0.035;
    }

    return _encodeCrossfadedLoopWav(
      raw,
      loopSec: loopSec,
      overlapSec: overlapSec,
    );
  }

  /// 16-second soothing meadow breeze with gentle pentatonic wind-chimes & bird calls.
  Uint8List _buildMorningMeadowLoop() {
    const loopSec = 16.0;
    const overlapSec = 1.6;
    const totalSec = loopSec + overlapSec;
    final totalSamples = (totalSec * _sampleRate).round();
    final raw = Float64List(totalSamples);
    final rng = math.Random(202);

    // Dual-stage low-pass warm breeze modulated by slow breathing LFO phasors
    var lp1 = 0.0;
    var lp2 = 0.0;
    final lfo1Step = 2.0 * math.pi / (8.0 * _sampleRate);
    final lfo1Cos = math.cos(lfo1Step);
    final lfo1Sin = math.sin(lfo1Step);
    var s1 = 0.0;
    var c1 = 1.0;

    final lfo2Step = 2.0 * math.pi / (5.333 * _sampleRate);
    final lfo2Cos = math.cos(lfo2Step);
    final lfo2Sin = math.sin(lfo2Step);
    var s2 = 0.0;
    var c2 = 1.0;

    for (var i = 0; i < totalSamples; i++) {
      final white = rng.nextDouble() * 2.0 - 1.0;
      lp1 = lp1 * 0.94 + white * 0.06;
      lp2 = lp2 * 0.95 + lp1 * 0.05;
      final breezeSwell = 0.58 + 0.25 * s1 + 0.17 * c2;
      raw[i] += lp2 * 0.34 * breezeSwell;

      final nextS1 = s1 * lfo1Cos + c1 * lfo1Sin;
      c1 = c1 * lfo1Cos - s1 * lfo1Sin;
      s1 = nextS1;

      final nextS2 = s2 * lfo2Cos + c2 * lfo2Sin;
      c2 = c2 * lfo2Cos - s2 * lfo2Sin;
      s2 = nextS2;
    }

    // Soft distant wooden wind-chime / songbird flute notes (F major pentatonic)
    const chimeEvents = <(double, double, double)>[
      (1.2, 523.25, 0.075),
      (1.55, 587.33, 0.065),
      (4.8, 698.46, 0.070),
      (5.2, 587.33, 0.060),
      (9.0, 440.00, 0.075),
      (9.45, 523.25, 0.070),
      (13.1, 698.46, 0.065),
      (13.5, 880.00, 0.055),
      // Mirror first event at +16.0s for seamless overlap!
      (17.2, 523.25, 0.075),
    ];
    for (final (startSec, freq, amp) in chimeEvents) {
      _mixPluckedWarmNote(
        raw,
        startSec: startSec,
        durationSec: 1.5,
        freqHz: freq,
        amplitude: amp,
      );
    }

    return _encodeCrossfadedLoopWav(
      raw,
      loopSec: loopSec,
      overlapSec: overlapSec,
    );
  }

  /// 16-second warm lo-fi garden sunshower raindrop patter.
  Uint8List _buildCozyRainLoop() {
    const loopSec = 16.0;
    const overlapSec = 1.6;
    const totalSec = loopSec + overlapSec;
    final totalSamples = (totalSec * _sampleRate).round();
    final raw = Float64List(totalSamples);
    final rng = math.Random(303);

    // Muffled warm rain wash (low-passed so there is zero harsh high hiss)
    var brown = 0.0;
    var softRain = 0.0;
    for (var i = 0; i < totalSamples; i++) {
      final w = rng.nextDouble() * 2.0 - 1.0;
      brown = (brown * 0.982 + w * 0.018).clamp(-1.0, 1.0);
      softRain = softRain * 0.84 + w * 0.16;
      raw[i] += softRain * 0.045 + brown * 0.18;
    }

    // Gentle individual leaf-droplet patters
    for (var d = 0; d < 95; d++) {
      final startSec = rng.nextDouble() * (totalSec - 0.15);
      final freq = 520.0 + rng.nextDouble() * 480.0;
      _mixPluckedWarmNote(
        raw,
        startSec: startSec,
        durationSec: 0.09,
        freqHz: freq,
        amplitude: 0.032,
      );
    }

    return _encodeCrossfadedLoopWav(
      raw,
      loopSec: loopSec,
      overlapSec: overlapSec,
    );
  }

  void _mixPluckedWarmNote(
    Float64List buffer, {
    required double startSec,
    required double durationSec,
    required double freqHz,
    required double amplitude,
  }) {
    final startIdx = (startSec * _sampleRate).round();
    final count = (durationSec * _sampleRate).round();
    final endIdx = math.min(buffer.length, startIdx + count);
    final attackSamples = math.max(1, (0.022 * _sampleRate).round());

    final omega = 2.0 * math.pi * freqHz / _sampleRate;
    final cosStep = math.cos(omega);
    final sinStep = math.sin(omega);
    var s = 0.0;
    var c = 1.0;

    final decayFundStep = math.exp(-2.8 / count);
    final decayHarmStep = math.exp(-6.5 / count);
    var decayFund = 1.0;
    var decayHarm = 1.0;

    final atkStep = math.pi / attackSamples;
    final atkCosStep = math.cos(atkStep);
    final atkSinStep = math.sin(atkStep);
    var atkC = 1.0;
    var atkS = 0.0;

    for (var i = startIdx; i < endIdx; i++) {
      final local = i - startIdx;
      double attack;
      if (local < attackSamples) {
        attack = 0.5 - 0.5 * atkC;
        final nextAtkC = atkC * atkCosStep - atkS * atkSinStep;
        atkS = atkS * atkCosStep + atkC * atkSinStep;
        atkC = nextAtkC;
      } else {
        attack = 1.0;
      }

      // Double-angle identity: sin(2*theta) = 2 * sin(theta) * cos(theta)
      final sin2 = 2.0 * s * c;
      final sample =
          (0.84 * s * decayFund + 0.16 * sin2 * decayHarm) * attack * amplitude;
      buffer[i] += sample;

      final nextS = s * cosStep + c * sinStep;
      c = c * cosStep - s * sinStep;
      s = nextS;

      decayFund *= decayFundStep;
      decayHarm *= decayHarmStep;
    }
  }

  Uint8List _encodeCrossfadedLoopWav(
    Float64List raw, {
    required double loopSec,
    required double overlapSec,
  }) {
    final loopSamples = (loopSec * _sampleRate).round();
    final overlapSamples = (overlapSec * _sampleRate).round();
    final out = Float64List(loopSamples);

    final blendStep = math.pi / overlapSamples;
    final blendCosStep = math.cos(blendStep);
    final blendSinStep = math.sin(blendStep);
    var blendC = 1.0;
    var blendS = 0.0;

    for (var i = 0; i < overlapSamples; i++) {
      final w = 0.5 - 0.5 * blendC;
      out[i] = w * raw[i] + (1.0 - w) * raw[loopSamples + i];
      final nextC = blendC * blendCosStep - blendS * blendSinStep;
      blendS = blendS * blendCosStep + blendC * blendSinStep;
      blendC = nextC;
    }
    out.setRange(overlapSamples, loopSamples, raw, overlapSamples);

    return _floatBufferToWav(out);
  }

  Uint8List _buildNotesWav(List<_Note> notes) {
    var totalSamples = 0;
    for (final n in notes) {
      totalSamples += (n.durationSec * _sampleRate).round();
    }
    final out = Float64List(totalSamples);
    var cursor = 0;
    final invAttackSamples = 1.0 / (_sampleRate * 0.008);

    for (final note in notes) {
      final count = (note.durationSec * _sampleRate).round();
      final invCount = 1.0 / count;
      final omega = 2.0 * math.pi * note.freqHz / _sampleRate;
      final cosStep = math.cos(omega);
      final sinStep = math.sin(omega);
      var s = 0.0;
      var c = 1.0;

      for (var i = 0; i < count; i++) {
        final attack = (i * invAttackSamples).clamp(0.0, 1.0);
        final rem = 1.0 - (i * invCount);
        // Fast approximation of rem^1.45 using rem * sqrt(rem) (= rem^1.5)
        final decay = rem * math.sqrt(rem);
        final env = attack * decay * note.amplitude;
        final sin2 = 2.0 * s * c;
        out[cursor++] = (0.82 * s + 0.18 * sin2) * env;

        final nextS = s * cosStep + c * sinStep;
        c = c * cosStep - s * sinStep;
        s = nextS;
      }
    }
    return _floatBufferToWav(out);
  }

  Uint8List _floatBufferToWav(Float64List samples) {
    final numSamples = samples.length;
    final dataSize = numSamples * 2;
    final bytes = Uint8List(44 + dataSize);
    final buffer = ByteData.sublistView(bytes);

    void writeAscii(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        bytes[offset + i] = s.codeUnitAt(i);
      }
    }

    writeAscii(0, 'RIFF');
    buffer.setUint32(4, 36 + dataSize, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little);
    buffer.setUint16(22, 1, Endian.little);
    buffer.setUint32(24, _sampleRate, Endian.little);
    buffer.setUint32(28, _sampleRate * 2, Endian.little);
    buffer.setUint16(32, 2, Endian.little);
    buffer.setUint16(34, 16, Endian.little);
    writeAscii(36, 'data');
    buffer.setUint32(40, dataSize, Endian.little);

    if (Endian.host == Endian.little) {
      final pcmView = Int16List.sublistView(bytes, 44);
      for (var i = 0; i < numSamples; i++) {
        var v = samples[i];
        if (v > 1.0) {
          v = 1.0;
        } else if (v < -1.0) {
          v = -1.0;
        }
        pcmView[i] = (v * 32767.0).round();
      }
    } else {
      for (var i = 0; i < numSamples; i++) {
        final pcm = (samples[i].clamp(-1.0, 1.0) * 32767.0).round();
        buffer.setInt16(44 + i * 2, pcm, Endian.little);
      }
    }
    return bytes;
  }
}

class _Note {
  const _Note(this.freqHz, this.durationSec, this.amplitude);
  final double freqHz;
  final double durationSec;
  final double amplitude;
}

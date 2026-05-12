import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'api_client.dart';

/// Hybrid speech service:
/// - TTS: Backend Google Neural2 → flutter_tts fallback
/// - STT: record package for raw audio → Whisper via /api/transcribe
class SpeechService {
  SpeechService._();
  static final SpeechService instance = SpeechService._();

  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();

  bool _isPlaying = false;
  bool _isRecording = false;
  bool _stopped = false;

  void Function(String)? _onLiveTranscript;

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  Future<void> init() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (e) {
      debugPrint('TTS init failed: $e');
    }
  }

  Future<void> stopAll() async {
    _stopped = true;
    await stopSpeaking();
    await stopRecording();
  }

  void reset() {
    _stopped = false;
  }

  // ─── TTS ──────────────────────────────────────────────────────────────────

  bool get isPlaying => _isPlaying;

  /// Speak text. Tries backend Google TTS first, falls back to flutter_tts.
  /// Never throws — all errors are caught and logged.
  Future<void> speak(String text) async {
    if (text.isEmpty || _stopped) return;

    try {
      await stopSpeaking();
    } catch (_) {}

    if (_stopped) return;
    _isPlaying = true;

    final clean = text
        .replaceAll(RegExp(r'[*_`~#]'), '')
        .replaceAll(RegExp(r'https?://\S+'), 'link')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();

    try {
      await _speakViaBackend(clean);
    } catch (e) {
      if (_stopped) {
        _isPlaying = false;
        return;
      }
      debugPrint('Backend TTS failed, falling back to device TTS: $e');
      try {
        await _speakViaTts(clean);
      } catch (e2) {
        debugPrint('Device TTS also failed: $e2');
        // Silent failure — interview continues without audio
      }
    } finally {
      _isPlaying = false;
    }
  }

  Future<void> _speakViaBackend(String text) async {
    if (_stopped) throw Exception('stopped');

    final bytes = await ApiClient.instance.getBytes('/google-tts', {
      'text': text,
      'voice': 'en-US-Neural2-F',
    });

    if (_stopped) throw Exception('stopped');

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/aqia_tts_${DateTime.now().millisecondsSinceEpoch}.mp3');
    await file.writeAsBytes(bytes);

    final completer = Completer<void>();
    StreamSubscription? sub;
    sub = _audioPlayer.onPlayerComplete.listen((_) {
      if (!completer.isCompleted) completer.complete();
      sub?.cancel();
    });

    try {
      await _audioPlayer.play(DeviceFileSource(file.path));
      await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          sub?.cancel();
          completer.complete();
        },
      );
    } catch (e) {
      sub?.cancel();
      rethrow;
    }

    // Clean up temp file
    try { await file.delete(); } catch (_) {}
  }

  Future<void> _speakViaTts(String text) async {
    if (_stopped) return;
    final completer = Completer<void>();
    _tts.setCompletionHandler(() {
      if (!completer.isCompleted) completer.complete();
    });
    _tts.setErrorHandler((msg) {
      debugPrint('TTS error: $msg');
      if (!completer.isCompleted) completer.complete();
    });
    await _tts.speak(text);
    await completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () => completer.complete(),
    );
  }

  Future<void> stopSpeaking() async {
    _isPlaying = false;
    try { await _audioPlayer.stop(); } catch (_) {}
    try { await _tts.stop(); } catch (_) {}
  }

  // ─── STT ──────────────────────────────────────────────────────────────────

  bool get isRecording => _isRecording;

  /// Start recording. Throws if microphone permission is denied.
  Future<void> startRecording({void Function(String)? onLiveTranscript}) async {
    if (_isRecording || _stopped) return;
    _onLiveTranscript = onLiveTranscript;

    bool hasPermission = false;
    try {
      hasPermission = await _recorder.hasPermission();
    } catch (e) {
      throw Exception('Could not check microphone permission: $e');
    }

    if (!hasPermission) {
      throw Exception('Microphone permission denied. Please allow microphone access in Settings.');
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/aqia_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 16000,
        ),
        path: path,
      );
      _isRecording = true;
    } catch (e) {
      throw Exception('Failed to start recording: $e');
    }
  }

  /// Stop recording and transcribe via Whisper. Returns transcript or empty string.
  /// Never throws — transcription failures return empty string gracefully.
  Future<String> stopRecordingAndTranscribe() async {
    if (!_isRecording) return '';
    _isRecording = false;
    _onLiveTranscript = null;

    String? path;
    try {
      path = await _recorder.stop();
    } catch (e) {
      debugPrint('Error stopping recorder: $e');
      return '';
    }

    if (path == null) return '';

    final file = File(path);
    try {
      if (!await file.exists()) return '';
      final size = await file.length();
      if (size < 500) {
        // Too short — likely silence or mic not working
        debugPrint('Recording too short ($size bytes), skipping transcription');
        return '';
      }
    } catch (e) {
      debugPrint('Error checking recording file: $e');
      return '';
    }

    final transcript = await _transcribeFile(file);

    // Clean up recording file
    try { await file.delete(); } catch (_) {}

    return transcript;
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;
    _isRecording = false;
    _onLiveTranscript = null;
    try {
      await _recorder.stop();
    } catch (_) {}
  }

  Future<String> _transcribeFile(File file) async {
    if (_stopped) return '';

    for (int attempt = 0; attempt < 3; attempt++) {
      if (_stopped) return '';
      try {
        final result = await ApiClient.instance.postMultipart(
          '/api/transcribe',
          file: file,
          fieldName: 'file',
          filename: 'recording.m4a',
          mimeType: 'audio/m4a',
          fields: {'model': 'whisper-large-v3'},
        );
        final text = result['text'] as String? ?? '';
        if (text.isNotEmpty) return text;
        // Empty transcript — don't retry
        return '';
      } catch (e) {
        debugPrint('Transcription attempt ${attempt + 1}/3 failed: $e');
        if (attempt < 2) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }

    debugPrint('All transcription attempts failed — returning empty');
    return '';
  }

  void dispose() {
    try { _audioPlayer.dispose(); } catch (_) {}
    try { _recorder.dispose(); } catch (_) {}
    try { _tts.stop(); } catch (_) {}
  }
}

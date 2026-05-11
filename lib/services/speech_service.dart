import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'api_client.dart';

/// Hybrid speech service matching the web app's approach:
/// - TTS: Backend Google Neural2 → flutter_tts fallback
/// - STT: record package for raw audio → Whisper via /api/transcribe
///        + live speech_to_text for interim display (optional)
class SpeechService {
  SpeechService._();
  static final SpeechService instance = SpeechService._();

  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();

  bool _isPlaying = false;
  bool _isRecording = false;
  bool _stopped = false;

  // Live transcript callback (called during recording with partial text)
  void Function(String)? _onLiveTranscript;

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  Future<void> init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  /// Call when navigating away from the interview to stop everything.
  Future<void> stopAll() async {
    _stopped = true;
    await stopSpeaking();
    await stopRecording();
  }

  /// Reset stopped flag when starting a new interview.
  void reset() {
    _stopped = false;
  }

  // ─── TTS ──────────────────────────────────────────────────────────────────

  bool get isPlaying => _isPlaying;

  /// Speak text. Tries backend Google TTS first, falls back to flutter_tts.
  Future<void> speak(String text) async {
    if (text.isEmpty || _stopped) return;
    await stopSpeaking();
    if (_stopped) return;

    _isPlaying = true;

    // Clean text for TTS
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
      debugPrint('Backend TTS failed, using flutter_tts: $e');
      await _speakViaTts(clean);
    }

    _isPlaying = false;
  }

  Future<void> _speakViaBackend(String text) async {
    if (_stopped) throw Exception('stopped');

    final bytes = await ApiClient.instance.getBytes('/google-tts', {
      'text': text,
      'voice': 'en-US-Neural2-F',
    });

    if (_stopped) throw Exception('stopped');

    // Write to temp file and play
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/aqia_tts_${DateTime.now().millisecondsSinceEpoch}.mp3');
    await file.writeAsBytes(bytes);

    final completer = Completer<void>();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (!completer.isCompleted) completer.complete();
    });

    await _audioPlayer.play(DeviceFileSource(file.path));
    await completer.future.timeout(const Duration(seconds: 30));
  }

  Future<void> _speakViaTts(String text) async {
    if (_stopped) return;
    final completer = Completer<void>();
    _tts.setCompletionHandler(() {
      if (!completer.isCompleted) completer.complete();
    });
    _tts.setErrorHandler((msg) {
      if (!completer.isCompleted) completer.complete();
    });
    await _tts.speak(text);
    await completer.future.timeout(const Duration(seconds: 30));
  }

  Future<void> stopSpeaking() async {
    _isPlaying = false;
    await _audioPlayer.stop();
    await _tts.stop();
  }

  // ─── STT ──────────────────────────────────────────────────────────────────

  bool get isRecording => _isRecording;

  /// Start recording audio. [onLiveTranscript] receives partial text updates.
  Future<void> startRecording({void Function(String)? onLiveTranscript}) async {
    if (_isRecording || _stopped) return;
    _onLiveTranscript = onLiveTranscript;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw Exception('Microphone permission denied');
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/aqia_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 16000,
      ),
      path: path,
    );

    _isRecording = true;
  }

  /// Stop recording and transcribe via Whisper. Returns the transcript text.
  Future<String> stopRecordingAndTranscribe() async {
    if (!_isRecording) return '';
    _isRecording = false;
    _onLiveTranscript = null;

    final path = await _recorder.stop();
    if (path == null) return '';

    final file = File(path);
    if (!await file.exists()) return '';
    final size = await file.length();
    if (size < 1000) return ''; // Too short to be real speech

    return _transcribeFile(file);
  }

  /// Stop recording without transcribing (e.g. on early exit).
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

    // Retry up to 3 times
    for (int i = 0; i < 3; i++) {
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
        return result['text'] as String? ?? '';
      } catch (e) {
        debugPrint('Transcribe attempt ${i + 1} failed: $e');
        if (i < 2) await Future.delayed(const Duration(seconds: 1));
      }
    }
    return '';
  }

  void dispose() {
    _audioPlayer.dispose();
    _recorder.dispose();
    _tts.stop();
  }
}

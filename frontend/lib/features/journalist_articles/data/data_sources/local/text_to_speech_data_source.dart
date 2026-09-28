import 'package:flutter_tts/flutter_tts.dart';

import '../../../domain/entities/article_narration.dart';

/// The device's text-to-speech engine (offline, no API key).
class TextToSpeechDataSource {
  // Android rejects longer texts (TextToSpeech.getMaxSpeechInputLength() is 4000).
  static const int maxChunkLength = 3900;
  static const int _speakSucceeded = 1;
  static const double _comfortableSpeechRate = 0.45;

  final FlutterTts _tts;
  bool _isStopRequested = false;

  TextToSpeechDataSource(this._tts);

  /// Reads [narration] chunk by chunk and completes when it ends or [stop] is called.
  /// Throws an [Exception] when the device cannot speak.
  Future<void> speak(ArticleNarrationEntity narration) async {
    _isStopRequested = false;
    await _prepareVoice(narration.languageTag);
    for (final chunk in splitIntoChunks(narration.text)) {
      if (_isStopRequested) return;
      await _speakChunk(chunk);
    }
  }

  Future<void> stop() async {
    _isStopRequested = true;
    await _tts.stop();
  }

  /// Splits [text] at sentence boundaries into chunks of at most [maxChunkLength] characters.
  static List<String> splitIntoChunks(String text) {
    final chunks = <String>[];
    var current = StringBuffer();
    for (final sentence in text.split(RegExp(r'(?<=[.!?])\s+'))) {
      if (current.length + sentence.length + 1 > maxChunkLength && current.isNotEmpty) {
        chunks.add(current.toString());
        current = StringBuffer();
      }
      current.write(current.isEmpty ? sentence : ' $sentence');
    }
    if (current.isNotEmpty) chunks.add(current.toString());
    return chunks.expand(_splitOversizedSentence).toList();
  }

  static Iterable<String> _splitOversizedSentence(String chunk) sync* {
    for (var start = 0; start < chunk.length; start += maxChunkLength) {
      yield chunk.substring(start, (start + maxChunkLength).clamp(0, chunk.length));
    }
  }

  Future<void> _prepareVoice(String languageTag) async {
    await _tts.awaitSpeakCompletion(true);
    await _tts.setSpeechRate(_comfortableSpeechRate);
    if (await _tts.isLanguageAvailable(languageTag) == true) {
      await _tts.setLanguage(languageTag);
    }
  }

  Future<void> _speakChunk(String chunk) async {
    final result = await _tts.speak(chunk);
    if (result != _speakSucceeded && !_isStopRequested) {
      throw Exception('The device could not read the article aloud');
    }
  }
}

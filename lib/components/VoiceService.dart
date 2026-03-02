import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  final FlutterTts _tts = FlutterTts();

  VoiceService() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
  }

  Future<void> speak(String text, bool isEnglish) async {
    if (isEnglish) {
      await _tts.setLanguage("en-US");
    } else {
      await _tts.setLanguage("fil-PH");
    }
    await _tts.speak(text);
  }

  Future<void> speakSequence(List<String> texts, bool isEnglish, {int pauseMs = 300}) async {
    await _tts.setLanguage(isEnglish ? "en-US" : "fil-PH");

    for (final t in texts) {
      await _tts.speak(t);
      await _tts.awaitSpeakCompletion(true);
      await Future.delayed(Duration(milliseconds: pauseMs));
    }
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/config/app_language.dart';
import '../../core/config/app_settings_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/farm_state_repository.dart';
import '../../widgets/citadel_logo.dart';

class _Message {
  final bool farmer;
  final String text;
  const _Message(this.farmer, this.text);
}

class FarmAssistantScreen extends StatefulWidget {
  const FarmAssistantScreen({super.key});

  @override
  State<FarmAssistantScreen> createState() => _FarmAssistantScreenState();
}

class _FarmAssistantScreenState extends State<FarmAssistantScreen> {
  final _controller = TextEditingController();
  final _speech = stt.SpeechToText();
  final _tts = FlutterTts();
  final _messages = <_Message>[];
  bool _listening = false;
  bool _sending = false;
  bool _speaking = false;

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    _controller.dispose();
    super.dispose();
  }

  String _languageName(AppLanguage language) {
    switch (language) {
      case AppLanguage.hindi: return 'Hindi';
      case AppLanguage.haryanvi: return 'Haryanvi';
      case AppLanguage.punjabi: return 'Punjabi';
      case AppLanguage.english: return 'English';
    }
  }

  String _locale(AppLanguage language) =>
      language == AppLanguage.punjabi ? 'pa-IN'
      : language == AppLanguage.english ? 'en-IN' : 'hi-IN';

  String _copy(AppLanguage language, String en, String hi, String hr, String pa) {
    switch (language) {
      case AppLanguage.hindi: return hi;
      case AppLanguage.haryanvi: return hr;
      case AppLanguage.punjabi: return pa;
      case AppLanguage.english: return en;
    }
  }

  Future<void> _toggleListening(AppLanguage language) async {
    if (_sending) return;
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    final available = await _speech.initialize(
      onStatus: (status) {
        if (mounted && (status == 'done' || status == 'notListening')) {
          setState(() => _listening = false);
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _listening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Speech recognition unavailable: ${error.errorMsg}')),
          );
        }
      },
    );
    if (!available) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Speech recognition is unavailable. Type your question instead.'),
      ));
      return;
    }
    setState(() => _listening = true);
    await _speech.listen(
      localeId: _locale(language),
      pauseFor: const Duration(seconds: 3),
      listenFor: const Duration(seconds: 30),
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _controller.text = result.recognizedWords;
          _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
        });
      },
    );
  }

  Future<void> _send(AppLanguage language) async {
    final question = _controller.text.trim();
    if (question.length < 2 || _sending) return;
    await _speech.stop();
    setState(() {
      _listening = false;
      _sending = true;
      _messages.add(_Message(true, question));
      _controller.clear();
    });
    try {
      final response = await context.read<FarmStateProvider>()
          .askAssistant(question, _languageName(language));
      if (!mounted) return;
      setState(() => _messages.add(_Message(false, response.answer)));
      await _speak(response.answer, language);
    } catch (error) {
      if (!mounted) return;
      final message = _copy(language,
        'The online assistant is unavailable. Your sensors and local analytics are still working.',
        'ऑनलाइन सहायक उपलब्ध नहीं है। आपके सेंसर और स्थानीय रिपोर्ट अभी भी काम कर रहे हैं।',
        'ऑनलाइन सहायक चालू कोनी। सेंसर अर लोकल रिपोर्ट फेर भी चालू सैं।',
        'ਆਨਲਾਈਨ ਸਹਾਇਕ ਉਪਲਬਧ ਨਹੀਂ। ਸੈਂਸਰ ਅਤੇ ਲੋਕਲ ਰਿਪੋਰਟ ਅਜੇ ਵੀ ਚੱਲ ਰਹੇ ਹਨ।');
      setState(() => _messages.add(_Message(false, message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _speak(String text, AppLanguage language) async {
    setState(() => _speaking = true);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
    _tts.setErrorHandler((_) {
      if (mounted) setState(() => _speaking = false);
    });
    await _tts.setLanguage(_locale(language));
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.speak(text);
  }

  Future<void> _stopSpeaking() async {
    await _tts.stop();
    if (mounted) setState(() => _speaking = false);
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<AppSettingsProvider>().language;
    final welcome = _copy(language,
      'Ask me about your sensor readings, crop scans, irrigation, or farm risks.',
      'अपने सेंसर, फसल स्कैन, सिंचाई या खेत के खतरे के बारे में पूछें।',
      'सेंसर, फसल स्कैन, सिंचाई या खेत के खतरे के बारे में पूछो।',
      'ਸੈਂਸਰਾਂ, ਫਸਲ ਸਕੈਨ, ਸਿੰਚਾਈ ਜਾਂ ਖੇਤ ਦੇ ਖਤਰਿਆਂ ਬਾਰੇ ਪੁੱਛੋ।');
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(mainAxisSize: MainAxisSize.min, children: [
          CitadelLogo(size: 38), SizedBox(width: 8), Text('Citadel Assistant'),
        ]),
        actions: [
          if (_speaking) IconButton(onPressed: _stopSpeaking,
            tooltip: 'Stop speaking', icon: const Icon(Icons.stop_circle_outlined)),
        ],
      ),
      body: Column(children: [
        Container(
          width: double.infinity, margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.cardYellowBg,
            borderRadius: BorderRadius.circular(12)),
          child: const Row(children: [
            Icon(Icons.wifi, size: 18, color: AppColors.severityWarning),
            SizedBox(width: 8),
            Expanded(child: Text('Online feature • Local monitoring continues if this assistant disconnects.',
              style: TextStyle(fontSize: 12))),
          ]),
        ),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _messages.length + 1,
          itemBuilder: (context, index) {
            final message = index == 0 ? _Message(false, welcome) : _messages[index - 1];
            return Align(
              alignment: message.farmer ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 320),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: message.farmer ? AppColors.primaryGreen : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(message.text, style: TextStyle(
                  color: message.farmer ? Colors.white : AppColors.textPrimary,
                  height: 1.4)),
              ),
            );
          },
        )),
        SafeArea(top: false, child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          color: Colors.white,
          child: Row(children: [
            IconButton(
              onPressed: _sending ? null : () => _toggleListening(language),
              tooltip: _listening ? 'Stop listening' : 'Speak',
              style: IconButton.styleFrom(
                backgroundColor: _listening ? AppColors.severityCritical : AppColors.cardGreenBg),
              icon: Icon(_listening ? Icons.stop : Icons.mic,
                color: _listening ? Colors.white : AppColors.primaryGreen),
            ),
            const SizedBox(width: 8),
            Expanded(child: TextField(
              controller: _controller,
              enabled: !_sending,
              minLines: 1, maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(language),
              decoration: InputDecoration(
                hintText: _listening ? 'Listening…' : 'Ask a farm question',
                filled: true, fillColor: AppColors.surfaceMuted,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none),
              ),
            )),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sending ? null : () => _send(language),
              style: IconButton.styleFrom(backgroundColor: AppColors.primaryGreen),
              icon: _sending
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send, color: Colors.white),
            ),
          ]),
        )),
      ]),
    );
  }
}

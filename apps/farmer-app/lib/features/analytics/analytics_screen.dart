import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_language.dart';
import '../../core/config/app_settings_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/farm_analytics_report.dart';
import '../../data/repositories/farm_state_repository.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/citadel_logo.dart';
import '../../widgets/profile_avatar_button.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _hours = 168;

  String _copy(AppLanguage language, String en, String hi, String hr, String pa) {
    switch (language) {
      case AppLanguage.hindi: return hi;
      case AppLanguage.haryanvi: return hr;
      case AppLanguage.punjabi: return pa;
      case AppLanguage.english: return en;
    }
  }

  Future<void> _analyze() async {
    final provider = context.read<FarmStateProvider>();
    final ok = await provider.analyzeFarm(hours: _hours);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.severityCritical,
        content: Text(provider.analyticsError ?? 'Report generation failed.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<AppSettingsProvider>().language;
    final provider = context.watch<FarmStateProvider>();
    final report = provider.analyticsReport;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(children: [
          const CitadelLogo(size: 42),
          const SizedBox(width: 10),
          Expanded(child: Text(_copy(language, 'Understand my farm', 'मेरे खेत को समझें',
              'मेरे खेत नै समझो', 'ਮੇਰੇ ਖੇਤ ਨੂੰ ਸਮਝੋ'))),
        ]),
        actions: const [ProfileAvatarButton(size: 34)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _hero(language, provider),
          const SizedBox(height: 14),
          _periodPicker(language),
          const SizedBox(height: 14),
          if (report == null) _empty(language) else ...[
            _overview(language, report),
            const SizedBox(height: 18),
            _heading(_copy(language, 'What your sensors mean', 'आपके सेंसर का मतलब',
                'सेंसर के आंकड़े का मतलब', 'ਤੁਹਾਡੇ ਸੈਂਸਰਾਂ ਦਾ ਮਤਲਬ')),
            const SizedBox(height: 10),
            ..._metricCards(language, report),
            const SizedBox(height: 18),
            _heading(_copy(language, 'Crop-health picture', 'फसल स्वास्थ्य की स्थिति',
                'फसल की सेहत', 'ਫਸਲ ਦੀ ਸਿਹਤ')),
            const SizedBox(height: 10),
            _cropHealth(language, report),
            const SizedBox(height: 18),
            _heading(_copy(language, 'What you should do', 'आपको क्या करना चाहिए',
                'अब के करना सै', 'ਤੁਹਾਨੂੰ ਕੀ ਕਰਨਾ ਚਾਹੀਦਾ ਹੈ')),
            const SizedBox(height: 10),
            ...report.recommendations.map((item) => _recommendation(language, item)),
          ],
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  Widget _hero(AppLanguage language, FarmStateProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF075C31), AppColors.primaryGreen]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_copy(language, 'Your readings, explained simply', 'आपकी रीडिंग, आसान भाषा में',
            'आपके आंकड़े, आसान बोली में', 'ਤੁਹਾਡੀਆਂ ਰੀਡਿੰਗਾਂ, ਸੌਖੀ ਭਾਸ਼ਾ ਵਿੱਚ'),
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(_copy(language,
            'Citadel studies your stored sensor readings, crop scans and irrigation activity, then explains how they can affect your crop.',
            'Citadel आपके सेव किए गए सेंसर डेटा, फसल स्कैन और सिंचाई गतिविधि को समझकर फसल पर असर बताता है।',
            'Citadel सेंसर, फसल स्कैन अर सिंचाई के आंकड़े देख कै फसल पै असर समझावै सै।',
            'Citadel ਸੈਂਸਰ ਰੀਡਿੰਗਾਂ, ਫਸਲ ਸਕੈਨ ਅਤੇ ਸਿੰਚਾਈ ਦੇ ਡਾਟੇ ਤੋਂ ਫਸਲ ਉੱਤੇ ਅਸਰ ਸਮਝਾਉਂਦਾ ਹੈ।'),
          style: const TextStyle(color: Colors.white70, height: 1.45)),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: provider.isAnalyzingFarm ? null : _analyze,
          icon: provider.isAnalyzingFarm
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.auto_graph),
          label: Text(_copy(language, 'Get to know my farm', 'मेरे खेत की रिपोर्ट बनाएं',
              'मेरा खेत समझाओ', 'ਮੇਰੇ ਖੇਤ ਦੀ ਰਿਪੋਰਟ ਬਣਾਓ')),
        )),
      ]),
    );
  }

  Widget _periodPicker(AppLanguage language) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 24, label: Text('24h')),
        ButtonSegment(value: 168, label: Text('7 days')),
        ButtonSegment(value: 720, label: Text('30 days')),
      ],
      selected: {_hours},
      onSelectionChanged: (selection) => setState(() => _hours = selection.first),
    );
  }

  Widget _empty(AppLanguage language) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Column(children: [
      const Icon(Icons.analytics_outlined, size: 54, color: AppColors.primaryGreen),
      const SizedBox(height: 12),
      Text(_copy(language, 'Tap the button to analyze locally stored farm data.',
          'स्थानीय रूप से सेव खेत के डेटा को समझने के लिए बटन दबाएं।',
          'खेत का सेव डेटा समझण खातर बटन दबाओ।',
          'ਸੰਭਾਲੇ ਹੋਏ ਖੇਤ ਡਾਟੇ ਦਾ ਵਿਸ਼ਲੇਸ਼ਣ ਕਰਨ ਲਈ ਬਟਨ ਦਬਾਓ।'), textAlign: TextAlign.center),
    ]),
  );

  Widget _overview(AppLanguage language, FarmAnalyticsReport report) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_copy(language, 'Report overview', 'रिपोर्ट सारांश', 'रिपोर्ट का सार', 'ਰਿਪੋਰਟ ਸਾਰ'),
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      const SizedBox(height: 14),
      Row(children: [
        _stat('${report.readingCount}', _copy(language, 'Readings', 'रीडिंग', 'रीडिंग', 'ਰੀਡਿੰਗਾਂ')),
        _stat('${report.completenessPct.toStringAsFixed(0)}%', _copy(language, 'Data complete', 'पूरा डेटा', 'पूरा डेटा', 'ਪੂਰਾ ਡਾਟਾ')),
        _stat('${report.cropScanCount}', _copy(language, 'Crop scans', 'फसल स्कैन', 'फसल स्कैन', 'ਫਸਲ ਸਕੈਨ')),
      ]),
    ]),
  );

  Widget _stat(String value, String label) => Expanded(child: Column(children: [
    Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
      color: AppColors.primaryGreen)),
    Text(label, textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
  ]));

  Widget _heading(String value) => Text(value,
    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800));

  List<Widget> _metricCards(AppLanguage language, FarmAnalyticsReport report) {
    final definitions = [
      ('soilMoisturePct', 'Soil moisture', 'मिट्टी की नमी', 'माटी की नमी', 'ਮਿੱਟੀ ਦੀ ਨਮੀ', Icons.water_drop,
        'Moisture tells us how much water is available near the roots. Too little can slow growth; too much can damage roots.'),
      ('temperatureC', 'Temperature', 'तापमान', 'गरमी', 'ਤਾਪਮਾਨ', Icons.thermostat,
        'Temperature affects growth and water loss. High heat can stress the crop and increase its water need.'),
      ('humidityPct', 'Humidity', 'हवा की नमी', 'हवा की नमी', 'ਹਵਾ ਦੀ ਨਮੀ', Icons.air,
        'Humidity is moisture in the air. Warm, humid conditions can make some crop diseases more likely.'),
      ('rainfallMm', 'Rainfall', 'बारिश', 'बरसात', 'ਮੀਂਹ', Icons.grain,
        'Rain adds water naturally. Heavy rainfall can make irrigation unnecessary and increase drainage risk.'),
      ('waterLevelPct', 'Water level', 'पानी का स्तर', 'पाणी का लेवल', 'ਪਾਣੀ ਦਾ ਪੱਧਰ', Icons.water,
        'Water level helps identify available water and possible overflow or flooding conditions.'),
    ];
    return definitions.map((definition) {
      final metric = report.metrics[definition.$1];
      final name = _copy(language, definition.$2, definition.$3, definition.$4, definition.$5);
      final explanation = language == AppLanguage.english
          ? definition.$7
          : _localizedMetricMeaning(language, definition.$1);
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _metricCard(language, name, definition.$6, metric, explanation),
      );
    }).toList();
  }

  String _localizedMetricMeaning(AppLanguage language, String key) {
    final values = <String, List<String>>{
      'soilMoisturePct': ['जड़ों के पास उपलब्ध पानी बताता है। बहुत कम या बहुत ज्यादा नमी फसल को नुकसान पहुंचा सकती है।', 'जड़ां धोरे कितणा पाणी सै यो बतावै सै। घणी कम या घणी नमी फसल नै नुकसान दे सके सै।', 'ਜੜ੍ਹਾਂ ਕੋਲ ਉਪਲਬਧ ਪਾਣੀ ਦੱਸਦੀ ਹੈ। ਬਹੁਤ ਘੱਟ ਜਾਂ ਵੱਧ ਨਮੀ ਫਸਲ ਨੂੰ ਨੁਕਸਾਨ ਕਰ ਸਕਦੀ ਹੈ।'],
      'temperatureC': ['तापमान फसल की बढ़त और पानी की जरूरत को प्रभावित करता है। ज्यादा गर्मी फसल पर दबाव डालती है।', 'गरमी फसल की बढ़त अर पाणी की जरूरत पै असर करै सै। ज्यादा गरमी फसल नै कमजोर कर सके सै।', 'ਤਾਪਮਾਨ ਫਸਲ ਦੇ ਵਾਧੇ ਅਤੇ ਪਾਣੀ ਦੀ ਲੋੜ ਉੱਤੇ ਅਸਰ ਕਰਦਾ ਹੈ। ਵੱਧ ਗਰਮੀ ਫਸਲ ਨੂੰ ਤਣਾਅ ਦਿੰਦੀ ਹੈ।'],
      'humidityPct': ['हवा की नमी ज्यादा होने पर गर्म मौसम में बीमारी का खतरा बढ़ सकता है।', 'हवा में घणी नमी अर गरमी हो तो बीमारी का खतरा बढ़ सके सै।', 'ਗਰਮ ਮੌਸਮ ਵਿੱਚ ਵੱਧ ਨਮੀ ਨਾਲ ਬਿਮਾਰੀ ਦਾ ਖਤਰਾ ਵੱਧ ਸਕਦਾ ਹੈ।'],
      'rainfallMm': ['बारिश से प्राकृतिक पानी मिलता है। ज्यादा बारिश में सिंचाई रोकें और जल निकासी देखें।', 'बरसात तै पाणी मिलै सै। घणी बरसात में सिंचाई रोक कै निकासी देखो।', 'ਮੀਂਹ ਨਾਲ ਕੁਦਰਤੀ ਪਾਣੀ ਮਿਲਦਾ ਹੈ। ਵੱਧ ਮੀਂਹ ਵਿੱਚ ਸਿੰਚਾਈ ਰੋਕੋ ਅਤੇ ਨਿਕਾਸੀ ਵੇਖੋ।'],
      'waterLevelPct': ['पानी का स्तर उपलब्ध पानी और बाढ़ या ओवरफ्लो का खतरा समझने में मदद करता है।', 'पाणी का लेवल उपलब्ध पाणी अर भराव का खतरा बतावै सै।', 'ਪਾਣੀ ਦਾ ਪੱਧਰ ਉਪਲਬਧ ਪਾਣੀ ਅਤੇ ਹੜ੍ਹ ਜਾਂ ਓਵਰਫਲੋ ਦਾ ਖਤਰਾ ਦੱਸਦਾ ਹੈ।'],
    };
    final index = language == AppLanguage.hindi ? 0 : language == AppLanguage.haryanvi ? 1 : 2;
    return values[key]![index];
  }

  Widget _metricCard(AppLanguage language, String name, IconData icon,
      MetricAnalytics? metric, String meaning) {
    final available = metric != null && metric.count > 0;
    final value = available ? '${metric.average!.toStringAsFixed(1)} ${metric.unit}' : '--';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(backgroundColor: AppColors.cardGreenBg,
            child: Icon(icon, color: AppColors.primaryGreen)),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 10),
        Text(meaning, style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
        if (available) ...[
          const SizedBox(height: 9),
          Text('${_copy(language, 'Range', 'सीमा', 'हद', 'ਸੀਮਾ')} '
              '${metric.minimum}–${metric.maximum} ${metric.unit} • '
              '${_trend(language, metric.trend)}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: AppColors.primaryGreen)),
        ],
      ]),
    );
  }

  String _trend(AppLanguage language, String trend) {
    final translations = {
      'rising': ['बढ़ रहा है', 'बढ़ रया सै', 'ਵੱਧ ਰਿਹਾ ਹੈ'],
      'falling': ['घट रहा है', 'घट रया सै', 'ਘੱਟ ਰਿਹਾ ਹੈ'],
      'stable': ['स्थिर', 'ठीक-ठाक', 'ਸਥਿਰ'],
      'unavailable': ['उपलब्ध नहीं', 'उपलब्ध कोनी', 'ਉਪਲਬਧ ਨਹੀਂ'],
    };
    if (language == AppLanguage.english) return trend;
    final index = language == AppLanguage.hindi ? 0 : language == AppLanguage.haryanvi ? 1 : 2;
    return translations[trend]?[index] ?? trend;
  }

  Widget _cropHealth(AppLanguage language, FarmAnalyticsReport report) {
    if (report.cropScanCount == 0) {
      return _messageCard(Icons.camera_alt_outlined,
        _copy(language, 'No crop scans in this period. Scan a tomato leaf to include visual crop health.',
          'इस अवधि में कोई फसल स्कैन नहीं है। फसल स्वास्थ्य जोड़ने के लिए टमाटर की पत्ती स्कैन करें।',
          'इस टैम में फसल स्कैन कोनी। टमाटर का पत्ता स्कैन करो।',
          'ਇਸ ਸਮੇਂ ਵਿੱਚ ਕੋਈ ਫਸਲ ਸਕੈਨ ਨਹੀਂ। ਟਮਾਟਰ ਦਾ ਪੱਤਾ ਸਕੈਨ ਕਰੋ।'));
    }
    final labels = report.cropLabels.entries.map((entry) => '${entry.key.replaceAll('_', ' ')}: ${entry.value}').join(' • ');
    return _messageCard(Icons.eco_outlined, labels);
  }

  Widget _recommendation(AppLanguage language, FarmRecommendation item) {
    final localized = _recommendationCopy(language, item);
    final color = item.priority == 'high' ? AppColors.severityCritical
        : item.priority == 'medium' ? AppColors.severityWarning : AppColors.primaryGreen;
    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 4))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(localized.$1, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(localized.$2, style: const TextStyle(color: AppColors.textSecondary, height: 1.35)),
      ]),
    );
  }

  (String, String) _recommendationCopy(AppLanguage language, FarmRecommendation item) {
    if (language == AppLanguage.english) return (item.title, item.message);
    final title = <String, List<String>>{
      'Reconnect the field node': ['फील्ड नोड दोबारा जोड़ें', 'फील्ड नोड जोड़ो', 'ਫੀਲਡ ਨੋਡ ਮੁੜ ਜੋੜੋ'],
      'Inspect drainage': ['जल निकासी जांचें', 'पाणी की निकासी देखो', 'ਪਾਣੀ ਦੀ ਨਿਕਾਸੀ ਜਾਂਚੋ'],
      'Review irrigation timing': ['सिंचाई का समय जांचें', 'सिंचाई का टैम देखो', 'ਸਿੰਚਾਈ ਦਾ ਸਮਾਂ ਜਾਂਚੋ'],
      'Protect crops from heat stress': ['फसल को गर्मी से बचाएं', 'फसल नै गरमी तै बचाओ', 'ਫਸਲ ਨੂੰ ਗਰਮੀ ਤੋਂ ਬਚਾਓ'],
      'Inspect affected leaves': ['प्रभावित पत्तियां जांचें', 'खराब पत्ते देखो', 'ਪ੍ਰਭਾਵਿਤ ਪੱਤੇ ਜਾਂਚੋ'],
      'Check missing sensors': ['बंद सेंसर जांचें', 'बंद सेंसर देखो', 'ਬੰਦ ਸੈਂਸਰ ਜਾਂਚੋ'],
      'Continue monitoring': ['निगरानी जारी रखें', 'निगरानी चालू राखो', 'ਨਿਗਰਾਨੀ ਜਾਰੀ ਰੱਖੋ'],
    }[item.title];
    if (title == null) return (item.title, item.message);
    final index = language == AppLanguage.hindi ? 0 : language == AppLanguage.haryanvi ? 1 : 2;
    final messages = <String, List<String>>{
      'Reconnect the field node': ['इस अवधि में सेंसर रीडिंग नहीं मिली। फील्ड नोड का कनेक्शन जांचें।', 'इस टैम में सेंसर रीडिंग कोनी मिली। फील्ड नोड जोड़ो।', 'ਇਸ ਸਮੇਂ ਵਿੱਚ ਸੈਂਸਰ ਰੀਡਿੰਗ ਨਹੀਂ ਮਿਲੀ। ਫੀਲਡ ਨੋਡ ਦਾ ਕਨੈਕਸ਼ਨ ਜਾਂਚੋ।'],
      'Inspect drainage': ['पानी अधिक रहा है। खेत की जल निकासी की जांच करें।', 'पाणी घणा रया सै। खेत की निकासी देखो।', 'ਪਾਣੀ ਵੱਧ ਰਿਹਾ ਹੈ। ਖੇਤ ਦੀ ਨਿਕਾਸੀ ਜਾਂਚੋ।'],
      'Review irrigation timing': ['मिट्टी में कम नमी मिली। सिंचाई के समय और मात्रा की जांच करें।', 'माटी में नमी कम मिली। सिंचाई का टैम अर मात्रा देखो।', 'ਮਿੱਟੀ ਵਿੱਚ ਨਮੀ ਘੱਟ ਮਿਲੀ। ਸਿੰਚਾਈ ਦਾ ਸਮਾਂ ਅਤੇ ਮਾਤਰਾ ਜਾਂਚੋ।'],
      'Protect crops from heat stress': ['गर्मी के संकेत मिले। ठंडे समय में सिंचाई और फसल निरीक्षण करें।', 'गरमी के संकेत मिले। ठंडे टैम सिंचाई अर फसल की जांच करो।', 'ਗਰਮੀ ਦੇ ਸੰਕੇਤ ਮਿਲੇ। ਠੰਢੇ ਸਮੇਂ ਸਿੰਚਾਈ ਅਤੇ ਫਸਲ ਦੀ ਜਾਂਚ ਕਰੋ।'],
      'Inspect affected leaves': ['फसल स्कैन में संभावित समस्या मिली। पास के पौधों की जांच करें और उपचार से पहले विशेषज्ञ से पूछें।', 'फसल स्कैन में दिक्कत मिली। धोरे के पौधे देखो अर इलाज तै पहले सलाह लो।', 'ਫਸਲ ਸਕੈਨ ਵਿੱਚ ਸੰਭਾਵਿਤ ਸਮੱਸਿਆ ਮਿਲੀ। ਨੇੜਲੇ ਪੌਦੇ ਜਾਂਚੋ ਅਤੇ ਇਲਾਜ ਤੋਂ ਪਹਿਲਾਂ ਮਾਹਿਰ ਦੀ ਸਲਾਹ ਲਵੋ।'],
      'Check missing sensors': ['कुछ सेंसर डेटा नहीं भेज रहे हैं। तार और सेंसर की जांच करें।', 'कुछ सेंसर डेटा कोनी भेज रहे। तार अर सेंसर देखो।', 'ਕੁਝ ਸੈਂਸਰ ਡਾਟਾ ਨਹੀਂ ਭੇਜ ਰਹੇ। ਤਾਰਾਂ ਅਤੇ ਸੈਂਸਰ ਜਾਂਚੋ।'],
      'Continue monitoring': ['कोई तत्काल खतरा नहीं मिला। नियमित निगरानी जारी रखें।', 'कोई तुरन्त खतरा कोनी मिला। निगरानी चालू राखो।', 'ਕੋਈ ਤੁਰੰਤ ਖਤਰਾ ਨਹੀਂ ਮਿਲਿਆ। ਨਿਯਮਤ ਨਿਗਰਾਨੀ ਜਾਰੀ ਰੱਖੋ।'],
    }[item.title];
    return (title[index], messages?[index] ?? item.message);
  }

  Widget _messageCard(IconData icon, String message) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Row(children: [Icon(icon, color: AppColors.primaryGreen), const SizedBox(width: 12),
      Expanded(child: Text(message, style: const TextStyle(height: 1.4)))]),
  );
}

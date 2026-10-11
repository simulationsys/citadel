import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:citadel_farmer_app/core/config/app_language.dart';
import 'package:citadel_farmer_app/core/config/app_strings.dart';

/// Guards the failure that shipped once already: a widget correctly calls
/// `translate()` but the dictionary has no entry, so the string silently
/// stays English while the rest of the screen switches language.
void main() {
  final libDir = Directory('lib');

  // Matches translate('X', ...) and the per-screen _t('X') shorthand.
  final callPatterns = [
    RegExp(r"""translate\(\s*'((?:[^'\\$]|\\.)*)'"""),
    RegExp(r"""[^A-Za-z0-9_]_t\(\s*'((?:[^'\\$]|\\.)*)'"""),
  ];

  Set<String> usedKeys() {
    final keys = <String>{};
    for (final f in libDir.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final src = f.readAsStringSync();
      for (final p in callPatterns) {
        for (final m in p.allMatches(src)) {
          final key = m.group(1)!;
          if (key.isEmpty) continue;
          keys.add(key.replaceAll(r'\n', '\n').replaceAll(r"\'", "'"));
        }
      }
    }
    return keys;
  }

  test('every translated key has a non-English entry', () {
    final missing = <String>[];
    for (final key in usedKeys()) {
      for (final lang in [
        AppLanguage.hindi,
        AppLanguage.haryanvi,
        AppLanguage.punjabi,
      ]) {
        // A missing entry makes translate() echo the English key back.
        if (AppStrings.translate(key, lang) == key) {
          missing.add('$key -> ${lang.name}');
          break;
        }
      }
    }
    expect(missing, isEmpty,
        reason: 'Untranslated keys (add them to AppStrings._translations):\n'
            '${missing.join('\n')}');
  });

  test('namespaced keys resolve to readable English, not the raw key', () {
    for (final key in [
      'severity.critical',
      'alertType.irrigation',
      'freshness.live',
    ]) {
      expect(AppStrings.translate(key, AppLanguage.english), isNot(contains('.')),
          reason: '$key leaked its namespace into the UI');
    }
  });

  test('composite fallback respects word boundaries', () {
    // 'Day' must not be substituted inside 'Days' or other words.
    final out = AppStrings.translate('Sunday Daylight', AppLanguage.hindi);
    expect(out, isNot(contains('दिनlight')));
  });

  test('longest key wins over a shorter contained key', () {
    // 'Soil Moisture' and 'Moisture' both exist; the phrase must win.
    final out = AppStrings.translate('Soil Moisture', AppLanguage.hindi);
    expect(out, AppStrings.translate('Soil Moisture', AppLanguage.hindi));
    expect(out, isNot(AppStrings.translate('Moisture', AppLanguage.hindi)));
  });
}

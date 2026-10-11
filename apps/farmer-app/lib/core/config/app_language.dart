/// Supported languages in the Citadel Farmer App.
///
/// Haryanvi is a dialect of Hindi with no official ISO 639 code,
/// so we treat it as a custom app-level language rather than a Flutter locale.
enum AppLanguage {
  english,
  hindi,
  haryanvi,
  punjabi;

  /// Display name in the language's own script (for UI pickers).
  String get nativeName {
    switch (this) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.hindi:
        return 'हिन्दी';
      case AppLanguage.haryanvi:
        return 'हरियाणवी';
      case AppLanguage.punjabi:
        return 'ਪੰਜਾਬੀ';
    }
  }

  /// Display label with English name in parentheses (for settings UI).
  String get displayLabel {
    switch (this) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.hindi:
        return 'हिन्दी (Hindi)';
      case AppLanguage.haryanvi:
        return 'हरियाणवी (Haryanvi)';
      case AppLanguage.punjabi:
        return 'ਪੰਜਾਬੀ (Punjabi)';
    }
  }

  /// Persist-friendly string key for SharedPreferences.
  String get storageKey => name;

  /// Parse from persisted string, defaulting to English.
  static AppLanguage fromStorageKey(String? key) {
    if (key == null) return AppLanguage.english;
    for (final lang in AppLanguage.values) {
      if (lang.name == key) return lang;
    }
    return AppLanguage.english;
  }
}

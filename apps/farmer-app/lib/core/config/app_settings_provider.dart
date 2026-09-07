import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsProvider extends ChangeNotifier {
  bool _isHindi = false;
  String _userName = 'Ramesh Kumar';
  String? _profileImagePath;
  String _userLocation = 'Rohtak, Haryana';
  String _farmingCycle = 'Kharif Cycle';
  List<String> _userCrops = [
    'Wheat (Plot B - North)',
    'Cotton (Plot A - South)',
    'Rice Paddy (Plot C - East)',
    'Mustard (Plot D)',
    'Sugarcane (Plot E)',
  ];

  static const List<String> availableIndianCrops = [
    'Wheat',
    'Cotton',
    'Rice Paddy',
    'Mustard',
    'Sugarcane',
    'Potato',
    'Tomato',
    'Maize (Corn)',
    'Pearl Millet (Bajra)',
    'Sorghum (Jowar)',
    'Gram (Chana)',
    'Soyabean',
    'Groundnut (Peanut)',
    'Onion',
    'Chili (Mirchi)',
    'Turmeric',
    'Pulses (Arhar/Tur)',
    'Tea / Coffee',
  ];

  bool get isHindi => _isHindi;
  String get userName => _userName;
  String? get profileImagePath => _profileImagePath;
  String get userLocation => _userLocation;
  String get farmingCycle => _farmingCycle;
  List<String> get userCrops => List.unmodifiable(_userCrops);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isHindi = prefs.getBool('isHindi') ?? false;
    _userName = prefs.getString('userName') ?? 'Ramesh Kumar';
    _profileImagePath = prefs.getString('profileImagePath');
    _userLocation = prefs.getString('userLocation') ?? 'Rohtak, Haryana';
    _farmingCycle = prefs.getString('farmingCycle') ?? 'Kharif Cycle';
    final savedCrops = prefs.getStringList('userCrops');
    if (savedCrops != null && savedCrops.isNotEmpty) {
      _userCrops = savedCrops;
    }
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    _isHindi = !_isHindi;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isHindi', _isHindi);
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? imagePath,
    String? location,
    String? cycle,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null && name.trim().isNotEmpty) {
      _userName = name.trim();
      await prefs.setString('userName', _userName);
    }
    if (imagePath != null) {
      _profileImagePath = imagePath;
      await prefs.setString('profileImagePath', imagePath);
    }
    if (location != null && location.trim().isNotEmpty) {
      _userLocation = location.trim();
      await prefs.setString('userLocation', _userLocation);
    }
    if (cycle != null && cycle.trim().isNotEmpty) {
      _farmingCycle = cycle.trim();
      await prefs.setString('farmingCycle', _farmingCycle);
    }
    notifyListeners();
  }

  Future<void> addUserCrop(String cropName) async {
    final trimmed = cropName.trim();
    if (trimmed.isEmpty || _userCrops.contains(trimmed)) return;
    _userCrops.add(trimmed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('userCrops', _userCrops);
    notifyListeners();
  }

  Future<void> removeUserCrop(String cropName) async {
    _userCrops.remove(cropName);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('userCrops', _userCrops);
    notifyListeners();
  }

  Future<void> setUserCrops(List<String> crops) async {
    _userCrops = List.from(crops);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('userCrops', _userCrops);
    notifyListeners();
  }
}

class AppStrings {
  static final Map<String, String> _translations = {
    // Nav & General
    'Home': 'मुख्य पृष्ठ',
    'Scanner': 'स्कैनर',
    'Advisory': 'सलाह',
    'Profile': 'प्रोफ़ाइल',
    'Citadel Farm': 'सिटाडेल फार्म',
    'Online • Synced': 'ऑनलाइन • सिंक किया गया',
    'Edge connection': 'एज कनेक्शन',
    'Zone': 'क्षेत्र',
    'Data status': 'डेटा स्थिति',
    'Language': 'भाषा',
    'Connection & Settings': 'कनेक्शन और सेटिंग्स',
    'Live • Synced just now': 'लाइव • अभी सिंक किया गया',
    'Ask AI': 'AI से पूछें',
    'Real-time Sensors': 'वास्तविक समय सेंसर',
    'Active Crop Track': 'सक्रिय फसल ट्रैक',
    'Scheduled Irrigation': 'निर्धारित सिंचाई',
    'Alerts & Advisory History': 'अलर्ट और सलाह इतिहास',
    'Farm decisions and action log': 'फार्म निर्णय और कार्य लॉग',
    'Active Alerts': 'सक्रिय अलर्ट',
    'Resolved': 'हल किया गया',
    'Protected': 'संरक्षित',
    'Good Morning': 'शुभ प्रभात',
    'Good Afternoon': 'शुभ दोपहर',
    'Good Evening': 'शुभ संध्या',

    // Crops / Plants (Indian Regional Crops)
    'Wheat': 'गेहूं',
    'Cotton': 'कपास',
    'Rice Paddy': 'धान (चावल)',
    'Rice': 'चावल',
    'Paddy': 'धान',
    'Mustard': 'सरसों',
    'Sugarcane': 'गन्ना',
    'Potato': 'आलू',
    'Tomato': 'टमाटर',
    'Maize': 'मक्का',
    'Maize (Corn)': 'मक्का (कॉर्न)',
    'Pearl Millet': 'बाजरा',
    'Bajra': 'बाजरा',
    'Pearl Millet (Bajra)': 'बाजरा',
    'Sorghum (Jowar)': 'ज्वार',
    'Jowar': 'ज्वार',
    'Gram': 'चना',
    'Chana': 'चना',
    'Gram (Chana)': 'चना',
    'Soyabean': 'सोयाबीन',
    'Groundnut': 'मूंगफली',
    'Groundnut (Peanut)': 'मूंगफली',
    'Onion': 'प्याज',
    'Chili': 'मिर्च',
    'Chili (Mirchi)': 'मिर्च',
    'Turmeric': 'हल्दी',
    'Pulses (Arhar/Tur)': 'अरहर (दाल)',
    'Tea / Coffee': 'चाय / कॉफी',
    'Custom Crop': 'अन्य फसल',

    // Plots & Specific Crop Names
    'Wheat (Plot B - North)': 'गेहूं (प्लॉट बी - उत्तर)',
    'Cotton (Plot A - South)': 'कपास (प्लॉट ए - दक्षिण)',
    'Rice Paddy (Plot C - East)': 'धान (प्लॉट सी - पूर्व)',
    'Mustard (Plot D)': 'सरसों (प्लॉट डी - पश्चिम)',
    'Sugarcane (Plot E)': 'गन्ना (प्लॉट ई - मध्य)',
    'Potato (Plot F)': 'आलू (प्लॉट एफ)',
    'Tomato (Plot G)': 'टमाटर (प्लॉट जी)',
    'Maize (Plot H)': 'मक्का (प्लॉट एच)',

    // Profile & Location Edit
    'Rohtak, Haryana': 'रोहतक, हरियाणा',
    'Kharif Cycle': 'खरीफ चक्र',
    'Rabi Cycle': 'रबी चक्र',
    'Zaid Cycle': 'जायद चक्र',
    'Edit Profile': 'प्रोफ़ाइल संपादित करें',
    'Edit Location': 'स्थान संपादित करें',
    'Edit Crops': 'फसलें संपादित करें',
    'Farmer Name': 'किसान का नाम',
    'Location / Place': 'स्थान / जगह',
    'Farming Cycle': 'फसल चक्र',
    'Type of Crops Grown': 'उगाई जाने वाली फसलों के प्रकार',
    'Select Crops': 'फसलें चुनें',
    'Add New Crop': 'नई फसल जोड़ें',
    'Enter crop name': 'फसल का नाम दर्ज करें',
    'Profile Photo': 'प्रोफ़ाइल फोटो',
    'Change Photo': 'फोटो बदलें',
    'Take Photo': 'कैमरे से फोटो लें',
    'Choose from Gallery': 'गैलरी से चुनें',
    'Default Avatar': 'डिफ़ॉल्ट अवतार',
    'Save': 'सहेजें',
    'Cancel': 'रद्द करें',

    // Scanner & Advisory
    'Crop Scanner': 'फसल स्कैनर',
    'Single Leaf': 'एकल पत्ती',
    'Field Spot': 'खेत का धब्बा',
    'ACTIVE CROP:': 'सक्रिय फसल:',
    'Change': 'बदलें',
    'Gallery': 'गैलरी',
    'Tips': 'सुझाव',
    'Spot Found': 'धब्बा मिला',
    'Irrigate now': 'अभी सिंचाई करें',
    'View Treatment Plan': 'उपचार योजना देखें',
    'View Dosage': 'खुराक देखें',
    'WARNING • IRRIGATION ALERT': 'चेतावनी • सिंचाई अलर्ट',
  };

  static String translate(String key, bool isHindi) {
    if (!isHindi) return key;

    if (_translations.containsKey(key)) {
      return _translations[key]!;
    }

    // Dynamic translation for composite text containing English crop names
    String translated = key;
    _translations.forEach((eng, hin) {
      if (eng.length > 2 && translated.contains(eng)) {
        translated = translated.replaceAll(eng, hin);
      }
    });

    return translated;
  }
}

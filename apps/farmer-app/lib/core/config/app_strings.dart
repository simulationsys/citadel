import 'app_language.dart';

class AppStrings {
  /// Multi-language translation map.
  /// Key = English string, Value = { AppLanguage → translated string }.
  /// English is always the key itself, so only non-English entries are stored.
  static final Map<String, Map<AppLanguage, String>> _translations = {
    // ─── Nav & General ───────────────────────────────────────────────
    'Home': {
      AppLanguage.hindi: 'मुख्य पृष्ठ',
      AppLanguage.haryanvi: 'मुख्य पन्ना',
      AppLanguage.punjabi: 'ਮੁੱਖ ਪੰਨਾ',
    },
    'Scanner': {
      AppLanguage.hindi: 'स्कैनर',
      AppLanguage.haryanvi: 'स्कैनर',
      AppLanguage.punjabi: 'ਸਕੈਨਰ',
    },
    'Advisory': {
      AppLanguage.hindi: 'सलाह',
      AppLanguage.haryanvi: 'सलाह',
      AppLanguage.punjabi: 'ਸਲਾਹ',
    },
    'Insights': {
      AppLanguage.hindi: 'समझ',
      AppLanguage.haryanvi: 'जानकारी',
      AppLanguage.punjabi: 'ਜਾਣਕਾਰੀ',
    },
    'Profile': {
      AppLanguage.hindi: 'प्रोफ़ाइल',
      AppLanguage.haryanvi: 'प्रोफ़ाइल',
      AppLanguage.punjabi: 'ਪ੍ਰੋਫਾਈਲ',
    },
    'Citadel Farm': {
      AppLanguage.hindi: 'सिटाडेल फार्म',
      AppLanguage.haryanvi: 'सिटाडेल फार्म',
      AppLanguage.punjabi: 'ਸਿਟਾਡੇਲ ਫਾਰਮ',
    },
    'Online • Synced': {
      AppLanguage.hindi: 'ऑनलाइन • सिंक किया गया',
      AppLanguage.haryanvi: 'ऑनलाइन • सिंक हो ग्या',
      AppLanguage.punjabi: 'ਆਨਲਾਈਨ • ਸਿੰਕ ਹੋ ਗਿਆ',
    },
    'Edge connection': {
      AppLanguage.hindi: 'एज कनेक्शन',
      AppLanguage.haryanvi: 'एज कनेक्शन',
      AppLanguage.punjabi: 'ਐੱਜ ਕਨੈਕਸ਼ਨ',
    },
    'Zone': {
      AppLanguage.hindi: 'क्षेत्र',
      AppLanguage.haryanvi: 'इलाका',
      AppLanguage.punjabi: 'ਖੇਤਰ',
    },
    'Data status': {
      AppLanguage.hindi: 'डेटा स्थिति',
      AppLanguage.haryanvi: 'डेटा की हालत',
      AppLanguage.punjabi: 'ਡੇਟਾ ਸਥਿਤੀ',
    },
    'Language': {
      AppLanguage.hindi: 'भाषा',
      AppLanguage.haryanvi: 'भाषा',
      AppLanguage.punjabi: 'ਭਾਸ਼ਾ',
    },
    'Connection & Settings': {
      AppLanguage.hindi: 'कनेक्शन और सेटिंग्स',
      AppLanguage.haryanvi: 'कनेक्शन अर सेटिंग',
      AppLanguage.punjabi: 'ਕਨੈਕਸ਼ਨ ਅਤੇ ਸੈਟਿੰਗਾਂ',
    },
    'Live • Synced just now': {
      AppLanguage.hindi: 'लाइव • अभी सिंक किया गया',
      AppLanguage.haryanvi: 'लाइव • अभी सिंक हो ग्या',
      AppLanguage.punjabi: 'ਲਾਈਵ • ਹੁਣੇ ਸਿੰਕ ਹੋਇਆ',
    },
    'Real-time Sensors': {
      AppLanguage.hindi: 'वास्तविक समय सेंसर',
      AppLanguage.haryanvi: 'असली टैम के सेंसर',
      AppLanguage.punjabi: 'ਅਸਲ-ਸਮੇਂ ਸੈਂਸਰ',
    },
    'Active Crop Track': {
      AppLanguage.hindi: 'सक्रिय फसल ट्रैक',
      AppLanguage.haryanvi: 'चालू फसल ट्रैक',
      AppLanguage.punjabi: 'ਸਰਗਰਮ ਫ਼ਸਲ ਟ੍ਰੈਕ',
    },
    'Scheduled Irrigation': {
      AppLanguage.hindi: 'निर्धारित सिंचाई',
      AppLanguage.haryanvi: 'तय की गई सिंचाई',
      AppLanguage.punjabi: 'ਤੈਅ ਸਿੰਜਾਈ',
    },
    'Alerts & Advisory History': {
      AppLanguage.hindi: 'अलर्ट और सलाह इतिहास',
      AppLanguage.haryanvi: 'अलर्ट अर सलाह का इतिहास',
      AppLanguage.punjabi: 'ਅਲਰਟ ਅਤੇ ਸਲਾਹ ਇਤਿਹਾਸ',
    },
    'Farm decisions and action log': {
      AppLanguage.hindi: 'फार्म निर्णय और कार्य लॉग',
      AppLanguage.haryanvi: 'खेत के फैसले अर काम का लॉग',
      AppLanguage.punjabi: 'ਖੇਤ ਫ਼ੈਸਲੇ ਅਤੇ ਕੰਮ ਲੌਗ',
    },
    'Active Alerts': {
      AppLanguage.hindi: 'सक्रिय अलर्ट',
      AppLanguage.haryanvi: 'चालू अलर्ट',
      AppLanguage.punjabi: 'ਸਰਗਰਮ ਅਲਰਟ',
    },
    'Resolved': {
      AppLanguage.hindi: 'हल किया गया',
      AppLanguage.haryanvi: 'हल हो ग्या',
      AppLanguage.punjabi: 'ਹੱਲ ਹੋ ਗਿਆ',
    },
    'Protected': {
      AppLanguage.hindi: 'संरक्षित',
      AppLanguage.haryanvi: 'सुरक्षित',
      AppLanguage.punjabi: 'ਸੁਰੱਖਿਅਤ',
    },

    // ─── Greetings ───────────────────────────────────────────────────
    'Good Morning': {
      AppLanguage.hindi: 'शुभ प्रभात',
      AppLanguage.haryanvi: 'राम राम जी',
      AppLanguage.punjabi: 'ਸਤ ਸ੍ਰੀ ਅਕਾਲ',
    },
    'Good Afternoon': {
      AppLanguage.hindi: 'शुभ दोपहर',
      AppLanguage.haryanvi: 'राम राम जी',
      AppLanguage.punjabi: 'ਸਤ ਸ੍ਰੀ ਅਕਾਲ',
    },
    'Good Evening': {
      AppLanguage.hindi: 'शुभ संध्या',
      AppLanguage.haryanvi: 'राम राम जी',
      AppLanguage.punjabi: 'ਸਤ ਸ੍ਰੀ ਅਕਾਲ',
    },

    // ─── Crops / Plants (Indian Regional Crops) ─────────────────────
    'Wheat': {
      AppLanguage.hindi: 'गेहूं',
      AppLanguage.haryanvi: 'गेहूं',
      AppLanguage.punjabi: 'ਕਣਕ',
    },
    'Cotton': {
      AppLanguage.hindi: 'कपास',
      AppLanguage.haryanvi: 'नरमा',
      AppLanguage.punjabi: 'ਕਪਾਹ',
    },
    'Rice Paddy': {
      AppLanguage.hindi: 'धान (चावल)',
      AppLanguage.haryanvi: 'धान',
      AppLanguage.punjabi: 'ਝੋਨਾ',
    },
    'Rice': {
      AppLanguage.hindi: 'चावल',
      AppLanguage.haryanvi: 'चावल',
      AppLanguage.punjabi: 'ਚੌਲ',
    },
    'Paddy': {
      AppLanguage.hindi: 'धान',
      AppLanguage.haryanvi: 'धान',
      AppLanguage.punjabi: 'ਝੋਨਾ',
    },
    'Mustard': {
      AppLanguage.hindi: 'सरसों',
      AppLanguage.haryanvi: 'सरसों',
      AppLanguage.punjabi: 'ਸਰ੍ਹੋਂ',
    },
    'Sugarcane': {
      AppLanguage.hindi: 'गन्ना',
      AppLanguage.haryanvi: 'गन्ना',
      AppLanguage.punjabi: 'ਗੰਨਾ',
    },
    'Potato': {
      AppLanguage.hindi: 'आलू',
      AppLanguage.haryanvi: 'आलू',
      AppLanguage.punjabi: 'ਆਲੂ',
    },
    'Tomato': {
      AppLanguage.hindi: 'टमाटर',
      AppLanguage.haryanvi: 'टमाटर',
      AppLanguage.punjabi: 'ਟਮਾਟਰ',
    },
    'Maize': {
      AppLanguage.hindi: 'मक्का',
      AppLanguage.haryanvi: 'मक्की',
      AppLanguage.punjabi: 'ਮੱਕੀ',
    },
    'Maize (Corn)': {
      AppLanguage.hindi: 'मक्का (कॉर्न)',
      AppLanguage.haryanvi: 'मक्की',
      AppLanguage.punjabi: 'ਮੱਕੀ',
    },
    'Pearl Millet': {
      AppLanguage.hindi: 'बाजरा',
      AppLanguage.haryanvi: 'बाजरा',
      AppLanguage.punjabi: 'ਬਾਜਰਾ',
    },
    'Bajra': {
      AppLanguage.hindi: 'बाजरा',
      AppLanguage.haryanvi: 'बाजरा',
      AppLanguage.punjabi: 'ਬਾਜਰਾ',
    },
    'Pearl Millet (Bajra)': {
      AppLanguage.hindi: 'बाजरा',
      AppLanguage.haryanvi: 'बाजरा',
      AppLanguage.punjabi: 'ਬਾਜਰਾ',
    },
    'Sorghum (Jowar)': {
      AppLanguage.hindi: 'ज्वार',
      AppLanguage.haryanvi: 'ज्वार',
      AppLanguage.punjabi: 'ਜਵਾਰ',
    },
    'Jowar': {
      AppLanguage.hindi: 'ज्वार',
      AppLanguage.haryanvi: 'ज्वार',
      AppLanguage.punjabi: 'ਜਵਾਰ',
    },
    'Gram': {
      AppLanguage.hindi: 'चना',
      AppLanguage.haryanvi: 'चना',
      AppLanguage.punjabi: 'ਛੋਲੇ',
    },
    'Chana': {
      AppLanguage.hindi: 'चना',
      AppLanguage.haryanvi: 'चना',
      AppLanguage.punjabi: 'ਛੋਲੇ',
    },
    'Gram (Chana)': {
      AppLanguage.hindi: 'चना',
      AppLanguage.haryanvi: 'चना',
      AppLanguage.punjabi: 'ਛੋਲੇ',
    },
    'Soyabean': {
      AppLanguage.hindi: 'सोयाबीन',
      AppLanguage.haryanvi: 'सोयाबीन',
      AppLanguage.punjabi: 'ਸੋਇਆਬੀਨ',
    },
    'Groundnut': {
      AppLanguage.hindi: 'मूंगफली',
      AppLanguage.haryanvi: 'मूंगफली',
      AppLanguage.punjabi: 'ਮੂੰਗਫਲੀ',
    },
    'Groundnut (Peanut)': {
      AppLanguage.hindi: 'मूंगफली',
      AppLanguage.haryanvi: 'मूंगफली',
      AppLanguage.punjabi: 'ਮੂੰਗਫਲੀ',
    },
    'Onion': {
      AppLanguage.hindi: 'प्याज',
      AppLanguage.haryanvi: 'प्याज',
      AppLanguage.punjabi: 'ਪਿਆਜ਼',
    },
    'Chili': {
      AppLanguage.hindi: 'मिर्च',
      AppLanguage.haryanvi: 'मिर्च',
      AppLanguage.punjabi: 'ਮਿਰਚ',
    },
    'Chili (Mirchi)': {
      AppLanguage.hindi: 'मिर्च',
      AppLanguage.haryanvi: 'मिर्च',
      AppLanguage.punjabi: 'ਮਿਰਚ',
    },
    'Turmeric': {
      AppLanguage.hindi: 'हल्दी',
      AppLanguage.haryanvi: 'हल्दी',
      AppLanguage.punjabi: 'ਹਲਦੀ',
    },
    'Pulses (Arhar/Tur)': {
      AppLanguage.hindi: 'अरहर (दाल)',
      AppLanguage.haryanvi: 'अरहर (दाल)',
      AppLanguage.punjabi: 'ਅਰਹਰ (ਦਾਲ)',
    },
    'Tea / Coffee': {
      AppLanguage.hindi: 'चाय / कॉफी',
      AppLanguage.haryanvi: 'चाह / कॉफी',
      AppLanguage.punjabi: 'ਚਾਹ / ਕੌਫ਼ੀ',
    },
    'Custom Crop': {
      AppLanguage.hindi: 'अन्य फसल',
      AppLanguage.haryanvi: 'और फसल',
      AppLanguage.punjabi: 'ਹੋਰ ਫ਼ਸਲ',
    },

    // ─── Plots & Specific Crop Names ─────────────────────────────────
    'Wheat (Plot B - North)': {
      AppLanguage.hindi: 'गेहूं (प्लॉट बी - उत्तर)',
      AppLanguage.haryanvi: 'गेहूं (प्लॉट बी - उत्तर)',
      AppLanguage.punjabi: 'ਕਣਕ (ਪਲਾਟ ਬੀ - ਉੱਤਰ)',
    },
    'Cotton (Plot A - South)': {
      AppLanguage.hindi: 'कपास (प्लॉट ए - दक्षिण)',
      AppLanguage.haryanvi: 'नरमा (प्लॉट ए - दक्षिण)',
      AppLanguage.punjabi: 'ਕਪਾਹ (ਪਲਾਟ ਏ - ਦੱਖਣ)',
    },
    'Rice Paddy (Plot C - East)': {
      AppLanguage.hindi: 'धान (प्लॉट सी - पूर्व)',
      AppLanguage.haryanvi: 'धान (प्लॉट सी - पूर्व)',
      AppLanguage.punjabi: 'ਝੋਨਾ (ਪਲਾਟ ਸੀ - ਪੂਰਬ)',
    },
    'Mustard (Plot D)': {
      AppLanguage.hindi: 'सरसों (प्लॉट डी - पश्चिम)',
      AppLanguage.haryanvi: 'सरसों (प्लॉट डी)',
      AppLanguage.punjabi: 'ਸਰ੍ਹੋਂ (ਪਲਾਟ ਡੀ)',
    },
    'Sugarcane (Plot E)': {
      AppLanguage.hindi: 'गन्ना (प्लॉट ई - मध्य)',
      AppLanguage.haryanvi: 'गन्ना (प्लॉट ई)',
      AppLanguage.punjabi: 'ਗੰਨਾ (ਪਲਾਟ ਈ)',
    },
    'Potato (Plot F)': {
      AppLanguage.hindi: 'आलू (प्लॉट एफ)',
      AppLanguage.haryanvi: 'आलू (प्लॉट एफ)',
      AppLanguage.punjabi: 'ਆਲੂ (ਪਲਾਟ ਐੱਫ)',
    },
    'Tomato (Plot G)': {
      AppLanguage.hindi: 'टमाटर (प्लॉट जी)',
      AppLanguage.haryanvi: 'टमाटर (प्लॉट जी)',
      AppLanguage.punjabi: 'ਟਮਾਟਰ (ਪਲਾਟ ਜੀ)',
    },
    'Maize (Plot H)': {
      AppLanguage.hindi: 'मक्का (प्लॉट एच)',
      AppLanguage.haryanvi: 'मक्की (प्लॉट एच)',
      AppLanguage.punjabi: 'ਮੱਕੀ (ਪਲਾਟ ਐੱਚ)',
    },

    // ─── Profile & Location ──────────────────────────────────────────
    'Rohtak, Haryana': {
      AppLanguage.hindi: 'रोहतक, हरियाणा',
      AppLanguage.haryanvi: 'रोहतक, हरियाणा',
      AppLanguage.punjabi: 'ਰੋਹਤਕ, ਹਰਿਆਣਾ',
    },
    'Kharif Cycle': {
      AppLanguage.hindi: 'खरीफ चक्र',
      AppLanguage.haryanvi: 'खरीफ का सीज़न',
      AppLanguage.punjabi: 'ਖ਼ਰੀਫ਼ ਚੱਕਰ',
    },
    'Rabi Cycle': {
      AppLanguage.hindi: 'रबी चक्र',
      AppLanguage.haryanvi: 'रबी का सीज़न',
      AppLanguage.punjabi: 'ਰਬੀ ਚੱਕਰ',
    },
    'Zaid Cycle': {
      AppLanguage.hindi: 'जायद चक्र',
      AppLanguage.haryanvi: 'जायद का सीज़न',
      AppLanguage.punjabi: 'ਜ਼ੈਦ ਚੱਕਰ',
    },
    'Edit Profile': {
      AppLanguage.hindi: 'प्रोफ़ाइल संपादित करें',
      AppLanguage.haryanvi: 'प्रोफ़ाइल बदलो',
      AppLanguage.punjabi: 'ਪ੍ਰੋਫਾਈਲ ਸੋਧੋ',
    },
    'Edit Location': {
      AppLanguage.hindi: 'स्थान संपादित करें',
      AppLanguage.haryanvi: 'जगहा बदलो',
      AppLanguage.punjabi: 'ਟਿਕਾਣਾ ਸੋਧੋ',
    },
    'Edit Crops': {
      AppLanguage.hindi: 'फसलें संपादित करें',
      AppLanguage.haryanvi: 'फसल बदलो',
      AppLanguage.punjabi: 'ਫ਼ਸਲਾਂ ਸੋਧੋ',
    },
    'Farmer Name': {
      AppLanguage.hindi: 'किसान का नाम',
      AppLanguage.haryanvi: 'किसान का नाम',
      AppLanguage.punjabi: 'ਕਿਸਾਨ ਦਾ ਨਾਮ',
    },
    'Location / Place': {
      AppLanguage.hindi: 'स्थान / जगह',
      AppLanguage.haryanvi: 'जगहा / गाम',
      AppLanguage.punjabi: 'ਟਿਕਾਣਾ / ਥਾਂ',
    },
    'Farming Cycle': {
      AppLanguage.hindi: 'फसल चक्र',
      AppLanguage.haryanvi: 'फसल का सीज़न',
      AppLanguage.punjabi: 'ਫ਼ਸਲ ਚੱਕਰ',
    },
    'Type of Crops Grown': {
      AppLanguage.hindi: 'उगाई जाने वाली फसलों के प्रकार',
      AppLanguage.haryanvi: 'बोई जाण आली फसलां',
      AppLanguage.punjabi: 'ਬੀਜੀਆਂ ਜਾਣ ਵਾਲੀਆਂ ਫ਼ਸਲਾਂ',
    },
    'Select Crops': {
      AppLanguage.hindi: 'फसलें चुनें',
      AppLanguage.haryanvi: 'फसल चुणो',
      AppLanguage.punjabi: 'ਫ਼ਸਲਾਂ ਚੁਣੋ',
    },
    'Select Indian Regional Crops': {
      AppLanguage.hindi: 'भारतीय क्षेत्रीय फसलें चुनें',
      AppLanguage.haryanvi: 'देसी फसल चुणो',
      AppLanguage.punjabi: 'ਭਾਰਤੀ ਖੇਤਰੀ ਫ਼ਸਲਾਂ ਚੁਣੋ',
    },
    'Add New Crop': {
      AppLanguage.hindi: 'नई फसल जोड़ें',
      AppLanguage.haryanvi: 'नई फसल जोड़ो',
      AppLanguage.punjabi: 'ਨਵੀਂ ਫ਼ਸਲ ਜੋੜੋ',
    },
    'Add Crop': {
      AppLanguage.hindi: 'फसल जोड़ें',
      AppLanguage.haryanvi: 'फसल जोड़ो',
      AppLanguage.punjabi: 'ਫ਼ਸਲ ਜੋੜੋ',
    },
    'Enter crop name': {
      AppLanguage.hindi: 'फसल का नाम दर्ज करें',
      AppLanguage.haryanvi: 'फसल का नाम लिखो',
      AppLanguage.punjabi: 'ਫ਼ਸਲ ਦਾ ਨਾਮ ਲਿਖੋ',
    },
    'Profile Photo': {
      AppLanguage.hindi: 'प्रोफ़ाइल फोटो',
      AppLanguage.haryanvi: 'प्रोफ़ाइल फोटो',
      AppLanguage.punjabi: 'ਪ੍ਰੋਫਾਈਲ ਫੋਟੋ',
    },
    'Profile Photo Updated': {
      AppLanguage.hindi: 'प्रोफ़ाइल फोटो अपडेट हो गई',
      AppLanguage.haryanvi: 'प्रोफ़ाइल फोटो बदल गई',
      AppLanguage.punjabi: 'ਪ੍ਰੋਫਾਈਲ ਫੋਟੋ ਅੱਪਡੇਟ ਹੋ ਗਈ',
    },
    'Change Photo': {
      AppLanguage.hindi: 'फोटो बदलें',
      AppLanguage.haryanvi: 'फोटो बदलो',
      AppLanguage.punjabi: 'ਫੋਟੋ ਬਦਲੋ',
    },
    'Change Profile Photo': {
      AppLanguage.hindi: 'प्रोफ़ाइल फोटो बदलें',
      AppLanguage.haryanvi: 'प्रोफ़ाइल फोटो बदलो',
      AppLanguage.punjabi: 'ਪ੍ਰੋਫਾਈਲ ਫੋਟੋ ਬਦਲੋ',
    },
    'Take Photo': {
      AppLanguage.hindi: 'कैमरे से फोटो लें',
      AppLanguage.haryanvi: 'कैमरे तै फोटो खींचो',
      AppLanguage.punjabi: 'ਕੈਮਰੇ ਨਾਲ ਫੋਟੋ ਖਿੱਚੋ',
    },
    'Choose from Gallery': {
      AppLanguage.hindi: 'गैलरी से चुनें',
      AppLanguage.haryanvi: 'गैलरी तै चुणो',
      AppLanguage.punjabi: 'ਗੈਲਰੀ ਤੋਂ ਚੁਣੋ',
    },
    'Default Avatar': {
      AppLanguage.hindi: 'डिफ़ॉल्ट अवतार',
      AppLanguage.haryanvi: 'डिफ़ॉल्ट अवतार',
      AppLanguage.punjabi: 'ਡਿਫਾਲਟ ਅਵਤਾਰ',
    },
    'Save': {
      AppLanguage.hindi: 'सहेजें',
      AppLanguage.haryanvi: 'सहेजो',
      AppLanguage.punjabi: 'ਸੰਭਾਲੋ',
    },
    'Cancel': {
      AppLanguage.hindi: 'रद्द करें',
      AppLanguage.haryanvi: 'रद्द करो',
      AppLanguage.punjabi: 'ਰੱਦ ਕਰੋ',
    },

    // ─── Scanner & Advisory ──────────────────────────────────────────
    'Crop Scanner': {
      AppLanguage.hindi: 'फसल स्कैनर',
      AppLanguage.haryanvi: 'फसल स्कैनर',
      AppLanguage.punjabi: 'ਫ਼ਸਲ ਸਕੈਨਰ',
    },
    'Select Active Crop': {
      AppLanguage.hindi: 'सक्रिय फसल चुनें',
      AppLanguage.haryanvi: 'चालू फसल चुणो',
      AppLanguage.punjabi: 'ਸਰਗਰਮ ਫ਼ਸਲ ਚੁਣੋ',
    },
    'Single Leaf': {
      AppLanguage.hindi: 'एकल पत्ती',
      AppLanguage.haryanvi: 'एक पत्ती',
      AppLanguage.punjabi: 'ਇੱਕ ਪੱਤਾ',
    },
    'Field Spot': {
      AppLanguage.hindi: 'खेत का धब्बा',
      AppLanguage.haryanvi: 'खेत का धब्बा',
      AppLanguage.punjabi: 'ਖੇਤ ਦਾ ਧੱਬਾ',
    },
    'ACTIVE CROP:': {
      AppLanguage.hindi: 'सक्रिय फसल:',
      AppLanguage.haryanvi: 'चालू फसल:',
      AppLanguage.punjabi: 'ਸਰਗਰਮ ਫ਼ਸਲ:',
    },
    'Change': {
      AppLanguage.hindi: 'बदलें',
      AppLanguage.haryanvi: 'बदलो',
      AppLanguage.punjabi: 'ਬਦਲੋ',
    },
    'Gallery': {
      AppLanguage.hindi: 'गैलरी',
      AppLanguage.haryanvi: 'गैलरी',
      AppLanguage.punjabi: 'ਗੈਲਰੀ',
    },
    'Tips': {
      AppLanguage.hindi: 'सुझाव',
      AppLanguage.haryanvi: 'सुझाव',
      AppLanguage.punjabi: 'ਸੁਝਾਅ',
    },
    'Spot Found': {
      AppLanguage.hindi: 'धब्बा मिला',
      AppLanguage.haryanvi: 'धब्बा मिल ग्या',
      AppLanguage.punjabi: 'ਧੱਬਾ ਮਿਲਿਆ',
    },
    'Irrigate now': {
      AppLanguage.hindi: 'अभी सिंचाई करें',
      AppLanguage.haryanvi: 'अभी पाणी दो',
      AppLanguage.punjabi: 'ਹੁਣੇ ਸਿੰਜਾਈ ਕਰੋ',
    },
    'View Treatment Plan': {
      AppLanguage.hindi: 'उपचार योजना देखें',
      AppLanguage.haryanvi: 'इलाज का प्लान देखो',
      AppLanguage.punjabi: 'ਇਲਾਜ ਯੋਜਨਾ ਦੇਖੋ',
    },
    'View Dosage': {
      AppLanguage.hindi: 'खुराक देखें',
      AppLanguage.haryanvi: 'खुराक देखो',
      AppLanguage.punjabi: 'ਖ਼ੁਰਾਕ ਦੇਖੋ',
    },
    'WARNING • IRRIGATION ALERT': {
      AppLanguage.hindi: 'चेतावनी • सिंचाई अलर्ट',
      AppLanguage.haryanvi: 'चेतावनी • पाणी का अलर्ट',
      AppLanguage.punjabi: 'ਚੇਤਾਵਨੀ • ਸਿੰਜਾਈ ਅਲਰਟ',
    },
    'Scanning Best Practices': {
      AppLanguage.hindi: 'स्कैनिंग के सर्वोत्तम तरीके',
      AppLanguage.haryanvi: 'स्कैनिंग के बढ़िया तरीके',
      AppLanguage.punjabi: 'ਸਕੈਨਿੰਗ ਦੇ ਵਧੀਆ ਤਰੀਕੇ',
    },
    'Got it!': {
      AppLanguage.hindi: 'समझ गया!',
      AppLanguage.haryanvi: 'समझ ग्या!',
      AppLanguage.punjabi: 'ਸਮਝ ਗਿਆ!',
    },

    // ─── Scanning tips ───────────────────────────────────────────────
    '1. Focus on affected leaves showing discoloration or spots.': {
      AppLanguage.hindi: '1. रंग बदली या धब्बे वाली पत्तियों पर ध्यान दें।',
      AppLanguage.haryanvi: '1. रंग बदली या धब्बे आली पत्तियां पै ध्यान दो।',
      AppLanguage.punjabi: '1. ਰੰਗ ਬਦਲੀਆਂ ਜਾਂ ਧੱਬੇ ਵਾਲੀਆਂ ਪੱਤੀਆਂ \'ਤੇ ਧਿਆਨ ਦਿਓ।',
    },
    '2. Keep distance at 15-20 cm from plant surface.': {
      AppLanguage.hindi: '2. पौधे की सतह से 15-20 सेमी दूरी बनाए रखें।',
      AppLanguage.haryanvi: '2. बूटे तै 15-20 सेमी दूर रहो।',
      AppLanguage.punjabi: '2. ਬੂਟੇ ਤੋਂ 15-20 ਸੈਮੀ ਦੂਰ ਰੱਖੋ।',
    },
    '3. Ensure clear daylight or turn on Flash in low light.': {
      AppLanguage.hindi: '3. साफ धूप सुनिश्चित करें या कम रोशनी में फ्लैश चालू करें।',
      AppLanguage.haryanvi: '3. धूप मैं खींचो या अंधेरे मैं फ्लैश चालू करो।',
      AppLanguage.punjabi: '3. ਧੁੱਪ ਵਿੱਚ ਖਿੱਚੋ ਜਾਂ ਘੱਟ ਰੌਸ਼ਨੀ \'ਚ ਫਲੈਸ਼ ਚਾਲੂ ਕਰੋ।',
    },
    '4. Keep camera steady for accurate AI confidence rating.': {
      AppLanguage.hindi: '4. सटीक AI रेटिंग के लिए कैमरा स्थिर रखें।',
      AppLanguage.haryanvi: '4. सही AI रेटिंग खातर कैमरा टिका कै रखो।',
      AppLanguage.punjabi: '4. ਸਹੀ AI ਰੇਟਿੰਗ ਲਈ ਕੈਮਰਾ ਸਥਿਰ ਰੱਖੋ।',
    },

    // ─── History / Alerts ────────────────────────────────────────────
    'All': {
      AppLanguage.hindi: 'सभी',
      AppLanguage.haryanvi: 'सारे',
      AppLanguage.punjabi: 'ਸਾਰੇ',
    },
    'High Severity': {
      AppLanguage.hindi: 'उच्च गंभीरता',
      AppLanguage.haryanvi: 'बहोत जरूरी',
      AppLanguage.punjabi: 'ਬਹੁਤ ਗੰਭੀਰ',
    },
    'Irrigation': {
      AppLanguage.hindi: 'सिंचाई',
      AppLanguage.haryanvi: 'पाणी/सिंचाई',
      AppLanguage.punjabi: 'ਸਿੰਜਾਈ',
    },
    'Today 8:30 AM': {
      AppLanguage.hindi: 'आज सुबह 8:30 बजे',
      AppLanguage.haryanvi: 'आज सबेरे 8:30 बजे',
      AppLanguage.punjabi: 'ਅੱਜ ਸਵੇਰੇ 8:30 ਵਜੇ',
    },
    'Whitefly Outbreak (North Plot)': {
      AppLanguage.hindi: 'सफेद मक्खी का प्रकोप (उत्तरी प्लॉट)',
      AppLanguage.haryanvi: 'सफेद मक्खी का हमला (उत्तर आला प्लॉट)',
      AppLanguage.punjabi: 'ਚਿੱਟੀ ਮੱਖੀ ਦਾ ਹਮਲਾ (ਉੱਤਰੀ ਪਲਾਟ)',
    },
    'Action Pending': {
      AppLanguage.hindi: 'कार्रवाई बाकी',
      AppLanguage.haryanvi: 'काम बाकी सै',
      AppLanguage.punjabi: 'ਕਾਰਵਾਈ ਬਾਕੀ',
    },

    // ─── Days / Months ───────────────────────────────────────────────
    'Monday': {
      AppLanguage.hindi: 'सोमवार',
      AppLanguage.haryanvi: 'सोमवार',
      AppLanguage.punjabi: 'ਸੋਮਵਾਰ',
    },
    'Tuesday': {
      AppLanguage.hindi: 'मंगलवार',
      AppLanguage.haryanvi: 'मंगलवार',
      AppLanguage.punjabi: 'ਮੰਗਲਵਾਰ',
    },
    'Wednesday': {
      AppLanguage.hindi: 'बुधवार',
      AppLanguage.haryanvi: 'बुधवार',
      AppLanguage.punjabi: 'ਬੁੱਧਵਾਰ',
    },
    'Thursday': {
      AppLanguage.hindi: 'गुरुवार',
      AppLanguage.haryanvi: 'बीरवार',
      AppLanguage.punjabi: 'ਵੀਰਵਾਰ',
    },
    'Friday': {
      AppLanguage.hindi: 'शुक्रवार',
      AppLanguage.haryanvi: 'शुक्रवार',
      AppLanguage.punjabi: 'ਸ਼ੁੱਕਰਵਾਰ',
    },
    'Saturday': {
      AppLanguage.hindi: 'शनिवार',
      AppLanguage.haryanvi: 'शनीवार',
      AppLanguage.punjabi: 'ਸ਼ਨੀਵਾਰ',
    },
    'Sunday': {
      AppLanguage.hindi: 'रविवार',
      AppLanguage.haryanvi: 'इतवार',
      AppLanguage.punjabi: 'ਐਤਵਾਰ',
    },
    'January': {
      AppLanguage.hindi: 'जनवरी',
      AppLanguage.haryanvi: 'जनवरी',
      AppLanguage.punjabi: 'ਜਨਵਰੀ',
    },
    'February': {
      AppLanguage.hindi: 'फरवरी',
      AppLanguage.haryanvi: 'फरवरी',
      AppLanguage.punjabi: 'ਫ਼ਰਵਰੀ',
    },
    'March': {
      AppLanguage.hindi: 'मार्च',
      AppLanguage.haryanvi: 'मार्च',
      AppLanguage.punjabi: 'ਮਾਰਚ',
    },
    'April': {
      AppLanguage.hindi: 'अप्रैल',
      AppLanguage.haryanvi: 'अप्रैल',
      AppLanguage.punjabi: 'ਅਪ੍ਰੈਲ',
    },
    'May': {
      AppLanguage.hindi: 'मई',
      AppLanguage.haryanvi: 'मई',
      AppLanguage.punjabi: 'ਮਈ',
    },
    'June': {
      AppLanguage.hindi: 'जून',
      AppLanguage.haryanvi: 'जून',
      AppLanguage.punjabi: 'ਜੂਨ',
    },
    'July': {
      AppLanguage.hindi: 'जुलाई',
      AppLanguage.haryanvi: 'जुलाई',
      AppLanguage.punjabi: 'ਜੁਲਾਈ',
    },
    'August': {
      AppLanguage.hindi: 'अगस्त',
      AppLanguage.haryanvi: 'अगस्त',
      AppLanguage.punjabi: 'ਅਗਸਤ',
    },
    'September': {
      AppLanguage.hindi: 'सितम्बर',
      AppLanguage.haryanvi: 'सितम्बर',
      AppLanguage.punjabi: 'ਸਤੰਬਰ',
    },
    'October': {
      AppLanguage.hindi: 'अक्टूबर',
      AppLanguage.haryanvi: 'अक्टूबर',
      AppLanguage.punjabi: 'ਅਕਤੂਬਰ',
    },
    'November': {
      AppLanguage.hindi: 'नवम्बर',
      AppLanguage.haryanvi: 'नवम्बर',
      AppLanguage.punjabi: 'ਨਵੰਬਰ',
    },
    'December': {
      AppLanguage.hindi: 'दिसम्बर',
      AppLanguage.haryanvi: 'दिसम्बर',
      AppLanguage.punjabi: 'ਦਸੰਬਰ',
    },

    // ─── Onboarding ──────────────────────────────────────────────────
    'Monitor Your Farm in Real-time': {
      AppLanguage.hindi: 'अपने खेत की लाइव निगरानी करें',
      AppLanguage.haryanvi: 'अपणे खेत की लाइव निगरानी करो',
      AppLanguage.punjabi: 'ਆਪਣੇ ਖੇਤ ਦੀ ਲਾਈਵ ਨਿਗਰਾਨੀ ਕਰੋ',
    },
    'Get live soil moisture, temperature, and humidity readings from IoT sensors placed across your fields.': {
      AppLanguage.hindi: 'अपने खेतों में लगे IoT सेंसर से मिट्टी की नमी, तापमान और आर्द्रता की लाइव रीडिंग पाएं।',
      AppLanguage.haryanvi: 'अपणे खेतां मैं लगे सेंसर तै मिट्टी का पाणी, तापमान अर नमी की लाइव जानकारी पाओ।',
      AppLanguage.punjabi: 'ਆਪਣੇ ਖੇਤਾਂ ਵਿੱਚ ਲੱਗੇ IoT ਸੈਂਸਰਾਂ ਤੋਂ ਮਿੱਟੀ ਦੀ ਨਮੀ, ਤਾਪਮਾਨ ਅਤੇ ਨਮੀ ਦੀ ਲਾਈਵ ਰੀਡਿੰਗ ਲਵੋ।',
    },
    'Scan Crops for Disease': {
      AppLanguage.hindi: 'फसल की बीमारी स्कैन करें',
      AppLanguage.haryanvi: 'फसल की बीमारी स्कैन करो',
      AppLanguage.punjabi: 'ਫ਼ਸਲ ਦੀ ਬਿਮਾਰੀ ਸਕੈਨ ਕਰੋ',
    },
    'Point your camera at any leaf. Our AI detects diseases like blight, whitefly, and rust — with instant treatment advice.': {
      AppLanguage.hindi: 'किसी भी पत्ती पर कैमरा करें। हमारा AI झुलसा, सफेद मक्खी और रतुआ जैसी बीमारियाँ पहचानता है — तुरंत इलाज की सलाह के साथ।',
      AppLanguage.haryanvi: 'किसी भी पत्ती पै कैमरा करो। हमारा AI झुलसा, सफेद मक्खी अर रतुआ जैसी बीमारी पहचाणै — तुरंत इलाज की सलाह कै साथ।',
      AppLanguage.punjabi: 'ਕਿਸੇ ਵੀ ਪੱਤੇ \'ਤੇ ਕੈਮਰਾ ਕਰੋ। ਸਾਡੀ AI ਝੁਲਸ, ਚਿੱਟੀ ਮੱਖੀ ਅਤੇ ਰਤੁਆ ਵਰਗੀਆਂ ਬਿਮਾਰੀਆਂ ਪਛਾਣਦੀ ਹੈ — ਤੁਰੰਤ ਇਲਾਜ ਸਲਾਹ ਨਾਲ।',
    },
    'Never Miss an Irrigation Cycle': {
      AppLanguage.hindi: 'सिंचाई का कोई चक्र न चूकें',
      AppLanguage.haryanvi: 'पाणी का कोई चक्कर ना छूटे',
      AppLanguage.punjabi: 'ਸਿੰਜਾਈ ਦਾ ਕੋਈ ਚੱਕਰ ਨਾ ਖੁੰਝੇ',
    },
    'Receive automated irrigation advisories based on soil data. Approve with one tap — the system controls your drip valves.': {
      AppLanguage.hindi: 'मिट्टी के डेटा पर आधारित स्वचालित सिंचाई सलाह पाएं। एक टैप से अनुमति दें — सिस्टम आपके ड्रिप वाल्व चलाएगा।',
      AppLanguage.haryanvi: 'मिट्टी के डेटा पै आधारित सिंचाई की सलाह पाओ। एक टैप तै इजाजत दो — सिस्टम तेरे ड्रिप वाल्व चलाएगा।',
      AppLanguage.punjabi: 'ਮਿੱਟੀ ਦੇ ਡੇਟਾ \'ਤੇ ਆਧਾਰਿਤ ਆਟੋਮੈਟਿਕ ਸਿੰਜਾਈ ਸਲਾਹ ਪ੍ਰਾਪਤ ਕਰੋ। ਇੱਕ ਟੈਪ ਨਾਲ ਮਨਜ਼ੂਰੀ ਦਿਓ — ਸਿਸਟਮ ਤੁਹਾਡੇ ਡ੍ਰਿਪ ਵਾਲਵ ਚਲਾਏਗਾ।',
    },
    'Your Language, Your Farm': {
      AppLanguage.hindi: 'आपकी भाषा, आपका खेत',
      AppLanguage.haryanvi: 'तेरी भाषा, तेरा खेत',
      AppLanguage.punjabi: 'ਤੁਹਾਡੀ ਭਾਸ਼ਾ, ਤੁਹਾਡਾ ਖੇਤ',
    },
    'Use Citadel in English, Hindi, Haryanvi, or Punjabi — built for Indian farmers.': {
      AppLanguage.hindi: 'सिटाडेल को अंग्रेजी, हिन्दी, हरियाणवी या पंजाबी में इस्तेमाल करें — भारतीय किसानों के लिए बना।',
      AppLanguage.haryanvi: 'सिटाडेल नैं अंग्रेजी, हिन्दी, हरियाणवी या पंजाबी मैं काम लो — देसी किसानां खातर बणा।',
      AppLanguage.punjabi: 'ਸਿਟਾਡੇਲ ਨੂੰ ਅੰਗਰੇਜ਼ੀ, ਹਿੰਦੀ, ਹਰਿਆਣਵੀ ਜਾਂ ਪੰਜਾਬੀ ਵਿੱਚ ਵਰਤੋ — ਭਾਰਤੀ ਕਿਸਾਨਾਂ ਲਈ ਬਣਿਆ।',
    },
    'Skip': {
      AppLanguage.hindi: 'छोड़ें',
      AppLanguage.haryanvi: 'छोड़ दो',
      AppLanguage.punjabi: 'ਛੱਡੋ',
    },
    'Next': {
      AppLanguage.hindi: 'अगला',
      AppLanguage.haryanvi: 'अगला',
      AppLanguage.punjabi: 'ਅਗਲਾ',
    },
    'Get Started': {
      AppLanguage.hindi: 'शुरू करें',
      AppLanguage.haryanvi: 'शुरू करो',
      AppLanguage.punjabi: 'ਸ਼ੁਰੂ ਕਰੋ',
    },
    'Choose your language': {
      AppLanguage.hindi: 'अपनी भाषा चुनें',
      AppLanguage.haryanvi: 'अपणी भाषा चुणो',
      AppLanguage.punjabi: 'ਆਪਣੀ ਭਾਸ਼ਾ ਚੁਣੋ',
    },

    // ─── Home Screen & Sensors ───────────────────────────────────────
    'Field A Live': {
      AppLanguage.hindi: 'फील्ड ए लाइव',
      AppLanguage.haryanvi: 'फील्ड ए लाइव',
      AppLanguage.punjabi: 'ਫੀਲਡ ਏ ਲਾਈਵ',
    },
    'Moisture': {
      AppLanguage.hindi: 'नमी',
      AppLanguage.haryanvi: 'नमी',
      AppLanguage.punjabi: 'ਨਮੀ',
    },
    'Temp': {
      AppLanguage.hindi: 'तापमान',
      AppLanguage.haryanvi: 'तापमान',
      AppLanguage.punjabi: 'ਤਾਪਮਾਨ',
    },
    'Needs Water': {
      AppLanguage.hindi: 'पानी चाहिए',
      AppLanguage.haryanvi: 'पाणी चाहिए',
      AppLanguage.punjabi: 'ਪਾਣੀ ਚਾਹੀਦਾ ਹੈ',
    },
    'Clear Skies': {
      AppLanguage.hindi: 'आसमान साफ',
      AppLanguage.haryanvi: 'आसमान साफ',
      AppLanguage.punjabi: 'ਅਸਮਾਨ ਸਾਫ਼',
    },
    '20 mins ago': {
      AppLanguage.hindi: '20 मिनट पहले',
      AppLanguage.haryanvi: '20 मिनट पहल्या',
      AppLanguage.punjabi: '20 ਮਿੰਟ ਪਹਿਲਾਂ',
    },
    'Whitefly Infestation Detected Nearby': {
      AppLanguage.hindi: 'पास में सफेद मक्खी का प्रकोप',
      AppLanguage.haryanvi: 'धोरे सफेद मक्खी का हमला',
      AppLanguage.punjabi: 'ਨੇੜੇ ਚਿੱਟੀ ਮੱਖੀ ਦਾ ਹਮਲਾ',
    },
    'Active in North Cotton field — apply organic neem spray before 5:00 PM to secure boll formation.': {
      AppLanguage.hindi: 'उत्तरी कपास खेत में सक्रिय — 5:00 बजे से पहले जैविक नीम स्प्रे करें।',
      AppLanguage.haryanvi: 'उत्तर आले नरमे के खेत में — 5 बजे से पहल्या नीम का स्प्रे मारो।',
      AppLanguage.punjabi: 'ਉੱਤਰੀ ਕਪਾਹ ਦੇ ਖੇਤ ਵਿੱਚ — 5 ਵਜੇ ਤੋਂ ਪਹਿਲਾਂ ਨਿੰਮ ਦਾ ਸਪਰੇਅ ਕਰੋ।',
    },
    'HIGH SEVERITY • PEST ALERT': {
      AppLanguage.hindi: 'उच्च गंभीरता • कीट अलर्ट',
      AppLanguage.haryanvi: 'घणा जरूरी • कीड़े का अलर्ट',
      AppLanguage.punjabi: 'ਬਹੁਤ ਗੰਭੀਰ • ਕੀਟ ਅਲਰਟ',
    },
    'Low soil moisture detected. Irrigate this zone for 15 minutes.': {
      AppLanguage.hindi: 'मिट्टी में नमी कम। इस क्षेत्र में 15 मिनट तक सिंचाई करें।',
      AppLanguage.haryanvi: 'माटी में नमी कम। इस धोरे 15 मिनट तांई पाणी देओ।',
      AppLanguage.punjabi: 'ਮਿੱਟੀ ਵਿੱਚ ਨਮੀ ਘੱਟ। ਇਸ ਖੇਤਰ ਵਿੱਚ 15 ਮਿੰਟ ਤੱਕ ਸਿੰਜਾਈ ਕਰੋ।',
    },
    'Root Optimal': {
      AppLanguage.hindi: 'जड़ें अनुकूल',
      AppLanguage.haryanvi: 'जड़ें ठीक',
      AppLanguage.punjabi: 'ਜੜ੍ਹਾਂ ਠੀਕ',
    },
    'Optimal': {
      AppLanguage.hindi: 'अनुकूल',
      AppLanguage.haryanvi: 'बढ़िया',
      AppLanguage.punjabi: 'ਠੀਕ',
    },
    'Deficit': {
      AppLanguage.hindi: 'कमी',
      AppLanguage.haryanvi: 'कमी',
      AppLanguage.punjabi: 'ਕਮੀ',
    },
    'Normal': {
      AppLanguage.hindi: 'सामान्य',
      AppLanguage.haryanvi: 'नॉर्मल',
      AppLanguage.punjabi: 'ਸਧਾਰਨ',
    },
    'Air Temperature': {
      AppLanguage.hindi: 'हवा का तापमान',
      AppLanguage.haryanvi: 'हवा का तापमान',
      AppLanguage.punjabi: 'ਹਵਾ ਦਾ ਤਾਪਮਾਨ',
    },
    'Soil Moisture': {
      AppLanguage.hindi: 'मिट्टी की नमी',
      AppLanguage.haryanvi: 'माटी की नमी',
      AppLanguage.punjabi: 'ਮਿੱਟੀ ਦੀ ਨਮੀ',
    },

    'Humidity': {
      AppLanguage.hindi: 'आर्द्रता',
      AppLanguage.haryanvi: 'नमी',
      AppLanguage.punjabi: 'ਨਮੀ',
    },
    'Good Spray': {
      AppLanguage.hindi: 'स्प्रे के लिए सही',
      AppLanguage.haryanvi: 'स्प्रे खातर ठीक',
      AppLanguage.punjabi: 'ਸਪਰੇਅ ਲਈ ਠੀਕ',
    },
    'Air Humidity': {
      AppLanguage.hindi: 'हवा की आर्द्रता',
      AppLanguage.haryanvi: 'हवा में नमी',
      AppLanguage.punjabi: 'ਹਵਾ ਵਿੱਚ ਨਮੀ',
    },
    'Ideal Spray Conditions': {
      AppLanguage.hindi: 'स्प्रे के लिए आदर्श स्थिति',
      AppLanguage.haryanvi: 'स्प्रे खातर बढ़िया टैम',
      AppLanguage.punjabi: 'ਸਪਰੇਅ ਲਈ ਵਧੀਆ ਸਮਾਂ',
    },
    '6:00 PM': {
      AppLanguage.hindi: 'शाम 6:00 बजे',
      AppLanguage.haryanvi: 'सांझ 6:00 बजे',
      AppLanguage.punjabi: 'ਸ਼ਾਮ 6:00 ਵਜੇ',
    },
    '45m Cycle': {
      AppLanguage.hindi: '45 मिनट चक्र',
      AppLanguage.haryanvi: '45 मिनट चक्कर',
      AppLanguage.punjabi: '45 ਮਿੰਟ ਚੱਕਰ',
    },

    'AI Scanner Ready • Good Lighting': {
      AppLanguage.hindi: 'AI स्कैनर तैयार • अच्छी रोशनी',
      AppLanguage.haryanvi: 'AI स्कैनर तैयार • बढ़िया चानण',
      AppLanguage.punjabi: 'AI ਸਕੈਨਰ ਤਿਆਰ • ਵਧੀਆ ਰੌਸ਼ਨੀ',
    },
    'Field Spot Mode Active': {
      AppLanguage.hindi: 'खेत का हिस्सा मोड सक्रिय',
      AppLanguage.haryanvi: 'खेत का हिस्सा मोड चालू',
      AppLanguage.punjabi: 'ਖੇਤ ਦਾ ਹਿੱਸਾ ਮੋਡ ਸਰਗਰਮ',
    },
    'Align damaged leaf area inside frame': {
      AppLanguage.hindi: 'क्षतिग्रस्त पत्ती को फ्रेम के अंदर रखें',
      AppLanguage.haryanvi: 'खराब पत्ती नै फ्रेम के भीतर राखो',
      AppLanguage.punjabi: 'ਖਰਾਬ ਪੱਤੀ ਨੂੰ ਫਰੇਮ ਦੇ ਅੰਦਰ ਰੱਖੋ',
    },
    'Align field crop section inside frame': {
      AppLanguage.hindi: 'फसल के हिस्से को फ्रेम के अंदर रखें',
      AppLanguage.haryanvi: 'फसल के हिस्से नै फ्रेम के भीतर राखो',
      AppLanguage.punjabi: 'ਫ਼ਸਲ ਦੇ ਹਿੱਸੇ ਨੂੰ ਫਰੇਮ ਦੇ ਅੰਦਰ ਰੱਖੋ',
    },
    'Hold steady for instant diagnosis': {
      AppLanguage.hindi: 'तुरंत पहचान के लिए स्थिर रखें',
      AppLanguage.haryanvi: 'तुरंत पछाण खातर टिका कै राखो',
      AppLanguage.punjabi: 'ਤੁਰੰਤ ਪਛਾਣ ਲਈ ਸਥਿਰ ਰੱਖੋ',
    },
    'Field Tip: Natural Sun Angle': {
      AppLanguage.hindi: 'खेत टिप: सूरज की सही दिशा',
      AppLanguage.haryanvi: 'खेत की सलाह: सूरज की सही दिशा',
      AppLanguage.punjabi: 'ਖੇਤ ਸੁਝਾਅ: ਸੂਰਜ ਦੀ ਸਹੀ ਦਿਸ਼ਾ',
    },
    'Keep the sun behind your phone for optimal clarity.': {
      AppLanguage.hindi: 'बेहतर फोटो के लिए सूरज को फोन के पीछे रखें।',
      AppLanguage.haryanvi: 'बढ़िया फोटो खातर सूरज नै फोन के पाच्छे राखो।',
      AppLanguage.punjabi: 'ਵਧੀਆ ਫੋਟੋ ਲਈ ਸੂਰਜ ਨੂੰ ਫੋਨ ਦੇ ਪਿੱਛੇ ਰੱਖੋ।',
    },
    'Irrigation Required': {
      AppLanguage.hindi: 'सिंचाई आवश्यक',
      AppLanguage.haryanvi: 'पाणी देना जरूरी',
      AppLanguage.punjabi: 'ਸਿੰਜਾਈ ਦੀ ਲੋੜ ਹੈ',
    },
    'Yesterday 6:15 PM': {
      AppLanguage.hindi: 'कल शाम 6:15 बजे',
      AppLanguage.haryanvi: 'काल सांझ 6:15 बजे',
      AppLanguage.punjabi: 'ਕੱਲ੍ਹ ਸ਼ਾਮ 6:15 ਵਜੇ',
    },
    'Low Soil Moisture (Plot A)': {
      AppLanguage.hindi: 'मिट्टी में कम नमी (प्लॉट ए)',
      AppLanguage.haryanvi: 'माटी में कम नमी (प्लॉट ए)',
      AppLanguage.punjabi: 'ਮਿੱਟੀ ਵਿੱਚ ਘੱਟ ਨਮੀ (ਪਲਾਟ ਏ)',
    },
    'Approved & Completed (45m drip)': {
      AppLanguage.hindi: 'स्वीकृत और पूर्ण (45 मिनट ड्रिप)',
      AppLanguage.haryanvi: 'मंजूर अर पूरा (45 मिनट ड्रिप)',
      AppLanguage.punjabi: 'ਮਨਜ਼ੂਰ ਅਤੇ ਪੂਰਾ (45 ਮਿੰਟ ਡ੍ਰਿਪ)',
    },
    'Plot moisture restored to 68%\noptimal': {
      AppLanguage.hindi: 'प्लॉट की नमी 68% तक बहाल\nअनुकूल',
      AppLanguage.haryanvi: 'प्लॉट की नमी 68% हो गी\nबढ़िया',
      AppLanguage.punjabi: 'ਪਲਾਟ ਦੀ ਨਮੀ 68% ਤੱਕ ਬਹਾਲ\nਠੀਕ',
    },
    'Sensor\nLog': {
      AppLanguage.hindi: 'सेंसर\nलॉग',
      AppLanguage.haryanvi: 'सेंसर\nलॉग',
      AppLanguage.punjabi: 'ਸੈਂਸਰ\nਲਾਗ',
    },
    'Weather Alert': {
      AppLanguage.hindi: 'मौसम अलर्ट',
      AppLanguage.haryanvi: 'मौसम अलर्ट',
      AppLanguage.punjabi: 'ਮੌਸਮ ਅਲਰਟ',
    },
    '3 days ago': {
      AppLanguage.hindi: '3 दिन पहले',
      AppLanguage.haryanvi: '3 दिन पहल्या',
      AppLanguage.punjabi: '3 ਦਿਨ ਪਹਿਲਾਂ',
    },
    'Heavy Rain Forecast (40mm)': {
      AppLanguage.hindi: 'भारी बारिश का अनुमान (40 मिमी)',
      AppLanguage.haryanvi: 'घणी बारिश की सम्भावना (40 मिमी)',
      AppLanguage.punjabi: 'ਭਾਰੀ ਮੀਂਹ ਦੀ ਭਵਿੱਖਬਾਣੀ (40mm)',
    },
    'Chemical spray postponed • Saved \$45': {
      AppLanguage.hindi: 'केमिकल स्प्रे स्थगित • \$45 बचाए',
      AppLanguage.haryanvi: 'दवाई का स्प्रे रोक्या • \$45 बचाए',
      AppLanguage.punjabi: 'ਕੈਮੀਕਲ ਸਪਰੇਅ ਮੁਲਤਵੀ • \$45 ਬਚਾਏ',
    },
    'View Weather Radar': {
      AppLanguage.hindi: 'मौसम रडार देखें',
      AppLanguage.haryanvi: 'मौसम रडार देखो',
      AppLanguage.punjabi: 'ਮੌਸਮ ਰਡਾਰ ਦੇਖੋ',
    },
    'Nutrient Management': {
      AppLanguage.hindi: 'पोषक तत्व प्रबंधन',
      AppLanguage.haryanvi: 'खाद का परबंध',
      AppLanguage.punjabi: 'ਪੋਸ਼ਕ ਤੱਤ ਪ੍ਰਬੰਧਨ',
    },
    '5 days ago': {
      AppLanguage.hindi: '5 दिन पहले',
      AppLanguage.haryanvi: '5 दिन पहल्या',
      AppLanguage.punjabi: '5 ਦਿਨ ਪਹਿਲਾਂ',
    },
    'Nitrogen Top Dressing': {
      AppLanguage.hindi: 'नाइट्रोजन टॉप ड्रेसिंग',
      AppLanguage.haryanvi: 'नाइट्रोजन टॉप ड्रेसिंग',
      AppLanguage.punjabi: 'ਨਾਈਟ੍ਰੋਜਨ ਟਾਪ ਡ੍ਰੈਸਿੰ',
    },
    'Completed (Urea applied) • NDVI +8%': {
      AppLanguage.hindi: 'पूर्ण (यूरिया डाला गया) • NDVI +8%',
      AppLanguage.haryanvi: 'पूरा (यूरिया गेरिया) • NDVI +8%',
      AppLanguage.punjabi: 'ਪੂਰਾ (ਯੂਰੀਆ ਪਾਇਆ) • NDVI +8%',
    },

    // ─── Sensor tiles: titles and status chips ───────────────────────
    // These flow through translate() from _buildSensorsGrid. Missing entries
    // here are why some tiles stayed English while others switched.
    'Rainfall': {
      AppLanguage.hindi: 'बारिश',
      AppLanguage.haryanvi: 'बरसात',
      AppLanguage.punjabi: 'ਮੀਂਹ',
    },
    'Water Level': {
      AppLanguage.hindi: 'जल स्तर',
      AppLanguage.haryanvi: 'पाणी का लेवल',
      AppLanguage.punjabi: 'ਪਾਣੀ ਦਾ ਪੱਧਰ',
    },
    'Not reporting': {
      AppLanguage.hindi: 'कोई डेटा नहीं',
      AppLanguage.haryanvi: 'कोई डेटा नीं',
      AppLanguage.punjabi: 'ਕੋਈ ਡਾਟਾ ਨਹੀਂ',
    },
    'Sensor live': {
      AppLanguage.hindi: 'सेंसर चालू',
      AppLanguage.haryanvi: 'सेंसर चालू',
      AppLanguage.punjabi: 'ਸੈਂਸਰ ਚਾਲੂ',
    },
    'Low moisture': {
      AppLanguage.hindi: 'नमी कम',
      AppLanguage.haryanvi: 'नमी कम',
      AppLanguage.punjabi: 'ਨਮੀ ਘੱਟ',
    },
    'High heat': {
      AppLanguage.hindi: 'अधिक गर्मी',
      AppLanguage.haryanvi: 'घणी गर्मी',
      AppLanguage.punjabi: 'ਵੱਧ ਗਰਮੀ',
    },
    'High humidity': {
      AppLanguage.hindi: 'अधिक आर्द्रता',
      AppLanguage.haryanvi: 'घणी नमी',
      AppLanguage.punjabi: 'ਵੱਧ ਨਮੀ',
    },
    'No rain detected': {
      AppLanguage.hindi: 'बारिश नहीं',
      AppLanguage.haryanvi: 'बरसात नीं',
      AppLanguage.punjabi: 'ਮੀਂਹ ਨਹੀਂ',
    },
    'Rain detected': {
      AppLanguage.hindi: 'बारिश हो रही है',
      AppLanguage.haryanvi: 'बरसात हो रही सै',
      AppLanguage.punjabi: 'ਮੀਂਹ ਪੈ ਰਿਹਾ ਹੈ',
    },
    'High water': {
      AppLanguage.hindi: 'जल स्तर अधिक',
      AppLanguage.haryanvi: 'पाणी घणा',
      AppLanguage.punjabi: 'ਪਾਣੀ ਵੱਧ',
    },
    'Waiting for node': {
      AppLanguage.hindi: 'नोड की प्रतीक्षा',
      AppLanguage.haryanvi: 'नोड का इंतजार',
      AppLanguage.punjabi: 'ਨੋਡ ਦੀ ਉਡੀਕ',
    },
    'reporting': {
      AppLanguage.hindi: 'रिपोर्ट कर रहे',
      AppLanguage.haryanvi: 'रिपोर्ट कर रहे',
      AppLanguage.punjabi: 'ਰਿਪੋਰਟ ਕਰ ਰਹੇ',
    },
    'All Plots': {
      AppLanguage.hindi: 'सभी प्लॉट',
      AppLanguage.haryanvi: 'सारे प्लॉट',
      AppLanguage.punjabi: 'ਸਾਰੇ ਪਲਾਟ',
    },
    'Local edge monitoring': {
      AppLanguage.hindi: 'स्थानीय एज निगरानी',
      AppLanguage.haryanvi: 'लोकल एज निगरानी',
      AppLanguage.punjabi: 'ਸਥਾਨਕ ਐੱਜ ਨਿਗਰਾਨੀ',
    },
    'Field Node': {
      AppLanguage.hindi: 'फील्ड नोड',
      AppLanguage.haryanvi: 'फील्ड नोड',
      AppLanguage.punjabi: 'ਫੀਲਡ ਨੋਡ',
    },
    'metrics': {
      AppLanguage.hindi: 'मापदंड',
      AppLanguage.haryanvi: 'मापदंड',
      AppLanguage.punjabi: 'ਮਾਪਦੰਡ',
    },

    // ─── Connection / freshness ──────────────────────────────────────
    'Stale • Synced': {
      AppLanguage.hindi: 'पुराना डेटा • सिंक',
      AppLanguage.haryanvi: 'पुराणा डेटा • सिंक',
      AppLanguage.punjabi: 'ਪੁਰਾਣਾ ਡਾਟਾ • ਸਿੰਕ',
    },
    'Offline Ready • Synced': {
      AppLanguage.hindi: 'ऑफलाइन तैयार • सिंक',
      AppLanguage.haryanvi: 'ऑफलाइन तैयार • सिंक',
      AppLanguage.punjabi: 'ਆਫਲਾਈਨ ਤਿਆਰ • ਸਿੰਕ',
    },
    'never': {
      AppLanguage.hindi: 'कभी नहीं',
      AppLanguage.haryanvi: 'कदे नीं',
      AppLanguage.punjabi: 'ਕਦੇ ਨਹੀਂ',
    },
    'm ago': {
      AppLanguage.hindi: ' मिनट पहले',
      AppLanguage.haryanvi: ' मिनट पहल्या',
      AppLanguage.punjabi: ' ਮਿੰਟ ਪਹਿਲਾਂ',
    },
    'Edge': {
      AppLanguage.hindi: 'एज',
      AppLanguage.haryanvi: 'एज',
      AppLanguage.punjabi: 'ਐੱਜ',
    },
    'freshness.live': {
      AppLanguage.english: 'Live',
      AppLanguage.hindi: 'लाइव',
      AppLanguage.haryanvi: 'लाइव',
      AppLanguage.punjabi: 'ਲਾਈਵ',
    },
    'freshness.stale': {
      AppLanguage.english: 'Stale',
      AppLanguage.hindi: 'पुराना',
      AppLanguage.haryanvi: 'पुराणा',
      AppLanguage.punjabi: 'ਪੁਰਾਣਾ',
    },
    'freshness.offline': {
      AppLanguage.english: 'Offline',
      AppLanguage.hindi: 'ऑफलाइन',
      AppLanguage.haryanvi: 'ऑफलाइन',
      AppLanguage.punjabi: 'ਆਫਲਾਈਨ',
    },

    // ─── Advisory severity / type tags ───────────────────────────────
    // Keyed by the raw backend value so the composed tag never has to be
    // looked up as one interpolated string.
    'severity.critical': {
      AppLanguage.english: 'CRITICAL',
      AppLanguage.hindi: 'अति गंभीर',
      AppLanguage.haryanvi: 'घणा जरूरी',
      AppLanguage.punjabi: 'ਬਹੁਤ ਗੰਭੀਰ',
    },
    'severity.warning': {
      AppLanguage.english: 'WARNING',
      AppLanguage.hindi: 'चेतावनी',
      AppLanguage.haryanvi: 'चेतावनी',
      AppLanguage.punjabi: 'ਚੇਤਾਵਨੀ',
    },
    'severity.info': {
      AppLanguage.english: 'INFO',
      AppLanguage.hindi: 'सूचना',
      AppLanguage.haryanvi: 'जाणकारी',
      AppLanguage.punjabi: 'ਜਾਣਕਾਰੀ',
    },
    'alertType.irrigation': {
      AppLanguage.english: 'IRRIGATION',
      AppLanguage.hindi: 'सिंचाई',
      AppLanguage.haryanvi: 'पाणी',
      AppLanguage.punjabi: 'ਸਿੰਜਾਈ',
    },
    'alertType.pest': {
      AppLanguage.english: 'PEST',
      AppLanguage.hindi: 'कीट',
      AppLanguage.haryanvi: 'कीड़ा',
      AppLanguage.punjabi: 'ਕੀਟ',
    },
    'alertType.crop_health': {
      AppLanguage.english: 'CROP HEALTH',
      AppLanguage.hindi: 'फसल स्वास्थ्य',
      AppLanguage.haryanvi: 'फसल की हालत',
      AppLanguage.punjabi: 'ਫ਼ਸਲ ਸਿਹਤ',
    },
    'alertType.heat': {
      AppLanguage.english: 'HEAT',
      AppLanguage.hindi: 'गर्मी',
      AppLanguage.haryanvi: 'गर्मी',
      AppLanguage.punjabi: 'ਗਰਮੀ',
    },
    'alertType.flood': {
      AppLanguage.english: 'FLOOD',
      AppLanguage.hindi: 'बाढ़',
      AppLanguage.haryanvi: 'बाढ़',
      AppLanguage.punjabi: 'ਹੜ੍ਹ',
    },
    'alertType.disease_risk': {
      AppLanguage.english: 'DISEASE RISK',
      AppLanguage.hindi: 'रोग जोखिम',
      AppLanguage.haryanvi: 'बीमारी का खतरा',
      AppLanguage.punjabi: 'ਬਿਮਾਰੀ ਖ਼ਤਰਾ',
    },
    'ALERT': {
      AppLanguage.hindi: 'अलर्ट',
      AppLanguage.haryanvi: 'अलर्ट',
      AppLanguage.punjabi: 'ਅਲਰਟ',
    },

    // ─── Common actions & units ──────────────────────────────────────
    'Close': {
      AppLanguage.hindi: 'बंद करें',
      AppLanguage.haryanvi: 'बंद करो',
      AppLanguage.punjabi: 'ਬੰਦ ਕਰੋ',
    },
    'OK': {
      AppLanguage.hindi: 'ठीक है',
      AppLanguage.haryanvi: 'ठीक सै',
      AppLanguage.punjabi: 'ਠੀਕ ਹੈ',
    },
    'Done': {
      AppLanguage.hindi: 'पूर्ण',
      AppLanguage.haryanvi: 'हो ग्या',
      AppLanguage.punjabi: 'ਹੋ ਗਿਆ',
    },
    'Dismiss': {
      AppLanguage.hindi: 'हटाएं',
      AppLanguage.haryanvi: 'हटाओ',
      AppLanguage.punjabi: 'ਹਟਾਓ',
    },
    'Adjust': {
      AppLanguage.hindi: 'बदलें',
      AppLanguage.haryanvi: 'बदलो',
      AppLanguage.punjabi: 'ਬਦਲੋ',
    },
    'Settings': {
      AppLanguage.hindi: 'सेटिंग्स',
      AppLanguage.haryanvi: 'सेटिंग',
      AppLanguage.punjabi: 'ਸੈਟਿੰਗਾਂ',
    },
    'Saved': {
      AppLanguage.hindi: 'सहेजा गया',
      AppLanguage.haryanvi: 'सहेज ग्या',
      AppLanguage.punjabi: 'ਸੰਭਾਲਿਆ ਗਿਆ',
    },
    'Day': {
      AppLanguage.hindi: 'दिन',
      AppLanguage.haryanvi: 'दिन',
      AppLanguage.punjabi: 'ਦਿਨ',
    },
    'days': {
      AppLanguage.hindi: 'दिन',
      AppLanguage.haryanvi: 'दिन',
      AppLanguage.punjabi: 'ਦਿਨ',
    },
    'days remaining': {
      AppLanguage.hindi: 'दिन शेष',
      AppLanguage.haryanvi: 'दिन बाकी',
      AppLanguage.punjabi: 'ਦਿਨ ਬਾਕੀ',
    },
    'mins': {
      AppLanguage.hindi: 'मिनट',
      AppLanguage.haryanvi: 'मिनट',
      AppLanguage.punjabi: 'ਮਿੰਟ',
    },
    'min Run': {
      AppLanguage.hindi: 'मिनट चलेगा',
      AppLanguage.haryanvi: 'मिनट चलैगा',
      AppLanguage.punjabi: 'ਮਿੰਟ ਚੱਲੇਗਾ',
    },
    'ha': {
      AppLanguage.hindi: 'हेक्टेयर',
      AppLanguage.haryanvi: 'हेक्टेयर',
      AppLanguage.punjabi: 'ਹੈਕਟੇਅਰ',
    },
    'hectares': {
      AppLanguage.hindi: 'हेक्टेयर',
      AppLanguage.haryanvi: 'हेक्टेयर',
      AppLanguage.punjabi: 'ਹੈਕਟੇਅਰ',
    },
    'Tonnes/ha': {
      AppLanguage.hindi: 'टन/हेक्टेयर',
      AppLanguage.haryanvi: 'टन/हेक्टेयर',
      AppLanguage.punjabi: 'ਟਨ/ਹੈਕਟੇਅਰ',
    },
    'Healthy': {
      AppLanguage.hindi: 'स्वस्थ',
      AppLanguage.haryanvi: 'तंदरुस्त',
      AppLanguage.punjabi: 'ਤੰਦਰੁਸਤ',
    },
    'Critical': {
      AppLanguage.hindi: 'गंभीर',
      AppLanguage.haryanvi: 'घणा जरूरी',
      AppLanguage.punjabi: 'ਗੰਭੀਰ',
    },
    'Off': {
      AppLanguage.hindi: 'छूट',
      AppLanguage.haryanvi: 'छूट',
      AppLanguage.punjabi: 'ਛੋਟ',
    },
    'Rohtak': {
      AppLanguage.hindi: 'रोहतक',
      AppLanguage.haryanvi: 'रोहतक',
      AppLanguage.punjabi: 'ਰੋਹਤਕ',
    },
    'Boll Opening': {
      AppLanguage.hindi: 'गूलर खिलना',
      AppLanguage.haryanvi: 'टींडे खुलणा',
      AppLanguage.punjabi: 'ਗੋਡੇ ਖੁੱਲ੍ਹਣਾ',
    },
    'Harvest window in': {
      AppLanguage.hindi: 'कटाई का समय',
      AppLanguage.haryanvi: 'कटाई का टैम',
      AppLanguage.punjabi: 'ਵਾਢੀ ਦਾ ਸਮਾਂ',
    },
    'Next cycle at': {
      AppLanguage.hindi: 'अगला चक्र',
      AppLanguage.haryanvi: 'अगला चक्कर',
      AppLanguage.punjabi: 'ਅਗਲਾ ਚੱਕਰ',
    },
    'Cotton Field Plot A': {
      AppLanguage.hindi: 'कपास खेत प्लॉट ए',
      AppLanguage.haryanvi: 'नरमे का खेत प्लॉट ए',
      AppLanguage.punjabi: 'ਕਪਾਹ ਖੇਤ ਪਲਾਟ ਏ',
    },

    // ─── Sensor detail dialog ────────────────────────────────────────
    'Sensor Details': {
      AppLanguage.hindi: 'सेंसर विवरण',
      AppLanguage.haryanvi: 'सेंसर की जाणकारी',
      AppLanguage.punjabi: 'ਸੈਂਸਰ ਵੇਰਵਾ',
    },
    'Current Reading': {
      AppLanguage.hindi: 'वर्तमान रीडिंग',
      AppLanguage.haryanvi: 'अबकी रीडिंग',
      AppLanguage.punjabi: 'ਮੌਜੂਦਾ ਰੀਡਿੰਗ',
    },
    'Status': {
      AppLanguage.hindi: 'स्थिति',
      AppLanguage.haryanvi: 'हालत',
      AppLanguage.punjabi: 'ਸਥਿਤੀ',
    },
    'Device': {
      AppLanguage.hindi: 'उपकरण',
      AppLanguage.haryanvi: 'डिवाइस',
      AppLanguage.punjabi: 'ਡਿਵਾਈਸ',
    },
    'Last received': {
      AppLanguage.hindi: 'अंतिम प्राप्त',
      AppLanguage.haryanvi: 'पिछली बार मिल्या',
      AppLanguage.punjabi: 'ਆਖ਼ਰੀ ਵਾਰ ਮਿਲਿਆ',
    },
    'Not connected': {
      AppLanguage.hindi: 'जुड़ा नहीं',
      AppLanguage.haryanvi: 'जुड़्या नीं',
      AppLanguage.punjabi: 'ਜੁੜਿਆ ਨਹੀਂ',
    },
    'Not reported': {
      AppLanguage.hindi: 'रिपोर्ट नहीं',
      AppLanguage.haryanvi: 'रिपोर्ट नीं',
      AppLanguage.punjabi: 'ਰਿਪੋਰਟ ਨਹੀਂ',
    },

    // ─── Weather dialog ──────────────────────────────────────────────
    'Rohtak Weather (5-Day)': {
      AppLanguage.hindi: 'रोहतक मौसम (5 दिन)',
      AppLanguage.haryanvi: 'रोहतक का मौसम (5 दिन)',
      AppLanguage.punjabi: 'ਰੋਹਤਕ ਮੌਸਮ (5 ਦਿਨ)',
    },
    'Today': {
      AppLanguage.hindi: 'आज',
      AppLanguage.haryanvi: 'आज',
      AppLanguage.punjabi: 'ਅੱਜ',
    },
    'Tomorrow': {
      AppLanguage.hindi: 'कल',
      AppLanguage.haryanvi: 'काल',
      AppLanguage.punjabi: 'ਕੱਲ੍ਹ',
    },
    'Humid': {
      AppLanguage.hindi: 'उमस',
      AppLanguage.haryanvi: 'उमस',
      AppLanguage.punjabi: 'ਹੁੰਮਸ',
    },
    'Partly Cloudy': {
      AppLanguage.hindi: 'आंशिक बादल',
      AppLanguage.haryanvi: 'थोड़े बादल',
      AppLanguage.punjabi: 'ਕੁਝ ਬੱਦਲ',
    },
    'Moderate Rain Expected': {
      AppLanguage.hindi: 'मध्यम बारिश की संभावना',
      AppLanguage.haryanvi: 'हल्की बरसात की उम्मीद',
      AppLanguage.punjabi: 'ਦਰਮਿਆਨਾ ਮੀਂਹ ਸੰਭਵ',
    },
    'Heavy Rain Expected': {
      AppLanguage.hindi: 'भारी बारिश की संभावना',
      AppLanguage.haryanvi: 'घणी बरसात की उम्मीद',
      AppLanguage.punjabi: 'ਭਾਰੀ ਮੀਂਹ ਸੰਭਵ',
    },
    'Sunny': {
      AppLanguage.hindi: 'धूप',
      AppLanguage.haryanvi: 'धूप',
      AppLanguage.punjabi: 'ਧੁੱਪ',
    },

    // ─── Crop track dialog ───────────────────────────────────────────
    'Cotton Plot A Details': {
      AppLanguage.hindi: 'कपास प्लॉट ए विवरण',
      AppLanguage.haryanvi: 'नरमा प्लॉट ए की जाणकारी',
      AppLanguage.punjabi: 'ਕਪਾਹ ਪਲਾਟ ਏ ਵੇਰਵਾ',
    },
    'Total Area': {
      AppLanguage.hindi: 'कुल क्षेत्र',
      AppLanguage.haryanvi: 'सारा रकबा',
      AppLanguage.punjabi: 'ਕੁੱਲ ਰਕਬਾ',
    },
    'Crop Stage': {
      AppLanguage.hindi: 'फसल अवस्था',
      AppLanguage.haryanvi: 'फसल की हालत',
      AppLanguage.punjabi: 'ਫ਼ਸਲ ਪੜਾਅ',
    },
    'Health Score': {
      AppLanguage.hindi: 'स्वास्थ्य स्कोर',
      AppLanguage.haryanvi: 'तंदरुस्ती स्कोर',
      AppLanguage.punjabi: 'ਸਿਹਤ ਸਕੋਰ',
    },
    'Estimated Harvest': {
      AppLanguage.hindi: 'अनुमानित कटाई',
      AppLanguage.haryanvi: 'अंदाजन कटाई',
      AppLanguage.punjabi: 'ਅੰਦਾਜ਼ਨ ਵਾਢੀ',
    },
    'Expected Yield': {
      AppLanguage.hindi: 'अपेक्षित उपज',
      AppLanguage.haryanvi: 'उम्मीद की पैदावार',
      AppLanguage.punjabi: 'ਸੰਭਾਵਿਤ ਝਾੜ',
    },

    // ─── History screen dialogs ──────────────────────────────────────
    'Whitefly Dosage Plan': {
      AppLanguage.hindi: 'सफेद मक्खी खुराक योजना',
      AppLanguage.haryanvi: 'सफेद मक्खी की खुराक का प्लान',
      AppLanguage.punjabi: 'ਚਿੱਟੀ ਮੱਖੀ ਖ਼ੁਰਾਕ ਯੋਜਨਾ',
    },
    'Recommended Organic Treatment:': {
      AppLanguage.hindi: 'सुझाया गया जैविक उपचार:',
      AppLanguage.haryanvi: 'सुझाया देसी इलाज:',
      AppLanguage.punjabi: 'ਸੁਝਾਇਆ ਜੈਵਿਕ ਇਲਾਜ:',
    },
    'Neem Oil (10,000 PPM): 5 ml per Liter water': {
      AppLanguage.hindi: 'नीम तेल (10,000 PPM): 5 मिली प्रति लीटर पानी',
      AppLanguage.haryanvi: 'नीम का तेल (10,000 PPM): 5 मिली एक लीटर पाणी मैं',
      AppLanguage.punjabi: 'ਨਿੰਮ ਦਾ ਤੇਲ (10,000 PPM): 5 ਮਿਲੀ ਪ੍ਰਤੀ ਲੀਟਰ ਪਾਣੀ',
    },
    'Spray Schedule: Early morning or post 5:00 PM': {
      AppLanguage.hindi: 'स्प्रे समय: सुबह जल्दी या शाम 5 बजे बाद',
      AppLanguage.haryanvi: 'स्प्रे का टैम: तड़कै या सांझ 5 बजे बाद',
      AppLanguage.punjabi: 'ਸਪਰੇਅ ਸਮਾਂ: ਸਵੇਰੇ ਜਲਦੀ ਜਾਂ ਸ਼ਾਮ 5 ਵਜੇ ਬਾਅਦ',
    },
    'Coverage: Underside of leaves in North Plot': {
      AppLanguage.hindi: 'कवरेज: उत्तरी प्लॉट में पत्तियों के नीचे',
      AppLanguage.haryanvi: 'कवरेज: उत्तर आले प्लॉट मैं पत्तियां कै नीचे',
      AppLanguage.punjabi: 'ਕਵਰੇਜ: ਉੱਤਰੀ ਪਲਾਟ ਵਿੱਚ ਪੱਤਿਆਂ ਦੇ ਹੇਠਾਂ',
    },
    'Status: 100L batch ready for field application.': {
      AppLanguage.hindi: 'स्थिति: 100 लीटर बैच खेत में डालने के लिए तैयार।',
      AppLanguage.haryanvi: 'हालत: 100 लीटर बैच खेत मैं गेरण खातर तैयार।',
      AppLanguage.punjabi: 'ਸਥਿਤੀ: 100 ਲੀਟਰ ਬੈਚ ਖੇਤ ਵਿੱਚ ਪਾਉਣ ਲਈ ਤਿਆਰ।',
    },
    'Dosage applied & logged to farm register!': {
      AppLanguage.hindi: 'खुराक लागू और खेत रजिस्टर में दर्ज!',
      AppLanguage.haryanvi: 'खुराक लगा दी अर खेत रजिस्टर मैं लिख दी!',
      AppLanguage.punjabi: 'ਖ਼ੁਰਾਕ ਲਾਗੂ ਤੇ ਖੇਤ ਰਜਿਸਟਰ ਵਿੱਚ ਦਰਜ!',
    },
    'Apply Dosage': {
      AppLanguage.hindi: 'खुराक लागू करें',
      AppLanguage.haryanvi: 'खुराक लगाओ',
      AppLanguage.punjabi: 'ਖ਼ੁਰਾਕ ਲਾਗੂ ਕਰੋ',
    },
    'Plot A Sensor Log': {
      AppLanguage.hindi: 'प्लॉट ए सेंसर लॉग',
      AppLanguage.haryanvi: 'प्लॉट ए का सेंसर लॉग',
      AppLanguage.punjabi: 'ਪਲਾਟ ਏ ਸੈਂਸਰ ਲਾਗ',
    },
    'Soil Moisture Telemetry (Last 24h):': {
      AppLanguage.hindi: 'मिट्टी नमी टेलीमेट्री (पिछले 24 घंटे):',
      AppLanguage.haryanvi: 'माटी की नमी का रिकॉर्ड (पिछले 24 घंटे):',
      AppLanguage.punjabi: 'ਮਿੱਟੀ ਨਮੀ ਟੈਲੀਮੈਟਰੀ (ਪਿਛਲੇ 24 ਘੰਟੇ):',
    },
    '06:15 PM Yesterday: 42% (Low Moisture Alert)': {
      AppLanguage.hindi: 'कल शाम 6:15: 42% (कम नमी अलर्ट)',
      AppLanguage.haryanvi: 'काल सांझ 6:15: 42% (कम नमी का अलर्ट)',
      AppLanguage.punjabi: 'ਕੱਲ੍ਹ ਸ਼ਾਮ 6:15: 42% (ਘੱਟ ਨਮੀ ਅਲਰਟ)',
    },
    '06:30 PM Yesterday: Drip Irrigation Started (45m)': {
      AppLanguage.hindi: 'कल शाम 6:30: ड्रिप सिंचाई शुरू (45 मिनट)',
      AppLanguage.haryanvi: 'काल सांझ 6:30: ड्रिप सिंचाई चालू (45 मिनट)',
      AppLanguage.punjabi: 'ਕੱਲ੍ਹ ਸ਼ਾਮ 6:30: ਡ੍ਰਿਪ ਸਿੰਜਾਈ ਸ਼ੁਰੂ (45 ਮਿੰਟ)',
    },
    '07:15 PM Yesterday: Drip Cycle Completed': {
      AppLanguage.hindi: 'कल शाम 7:15: ड्रिप चक्र पूर्ण',
      AppLanguage.haryanvi: 'काल सांझ 7:15: ड्रिप चक्कर पूरा',
      AppLanguage.punjabi: 'ਕੱਲ੍ਹ ਸ਼ਾਮ 7:15: ਡ੍ਰਿਪ ਚੱਕਰ ਪੂਰਾ',
    },
    'Current Level: 68% (Optimal Root Zone)': {
      AppLanguage.hindi: 'वर्तमान स्तर: 68% (जड़ क्षेत्र अनुकूल)',
      AppLanguage.haryanvi: 'अबका लेवल: 68% (जड़ां खातर बढ़िया)',
      AppLanguage.punjabi: 'ਮੌਜੂਦਾ ਪੱਧਰ: 68% (ਜੜ੍ਹ ਖੇਤਰ ਠੀਕ)',
    },
    'Weather Radar': {
      AppLanguage.hindi: 'मौसम रडार',
      AppLanguage.haryanvi: 'मौसम रडार',
      AppLanguage.punjabi: 'ਮੌਸਮ ਰਡਾਰ',
    },
    'Rohtak Zone Radar Overview:': {
      AppLanguage.hindi: 'रोहतक क्षेत्र रडार अवलोकन:',
      AppLanguage.haryanvi: 'रोहतक इलाके का रडार:',
      AppLanguage.punjabi: 'ਰੋਹਤਕ ਖੇਤਰ ਰਡਾਰ ਸੰਖੇਪ:',
    },
    'Precipitation: 40mm expected in next 3 days': {
      AppLanguage.hindi: 'वर्षा: अगले 3 दिनों में 40 मिमी अनुमानित',
      AppLanguage.haryanvi: 'बरसात: अगले 3 दिन मैं 40 मिमी',
      AppLanguage.punjabi: 'ਵਰਖਾ: ਅਗਲੇ 3 ਦਿਨਾਂ ਵਿੱਚ 40mm ਸੰਭਵ',
    },
    'Wind: 14 km/h North-East': {
      AppLanguage.hindi: 'हवा: 14 किमी/घंटा उत्तर-पूर्व',
      AppLanguage.haryanvi: 'हवा: 14 किमी/घंटा उत्तर-पूर्व',
      AppLanguage.punjabi: 'ਹਵਾ: 14 ਕਿਮੀ/ਘੰਟਾ ਉੱਤਰ-ਪੂਰਬ',
    },
    'Recommendation: Hold off chemical spray to prevent wash-off': {
      AppLanguage.hindi: 'सलाह: बहाव रोकने के लिए केमिकल स्प्रे टालें',
      AppLanguage.haryanvi: 'सलाह: दवाई धुल ना जावै, स्प्रे रोक दो',
      AppLanguage.punjabi: 'ਸਲਾਹ: ਧੁਲਣ ਤੋਂ ਬਚਾਉਣ ਲਈ ਕੈਮੀਕਲ ਸਪਰੇਅ ਟਾਲੋ',
    },
    'Nutrient Batch': {
      AppLanguage.hindi: 'पोषक बैच',
      AppLanguage.haryanvi: 'खाद का बैच',
      AppLanguage.punjabi: 'ਪੋਸ਼ਕ ਬੈਚ',
    },
    'Batch': {
      AppLanguage.hindi: 'बैच',
      AppLanguage.haryanvi: 'बैच',
      AppLanguage.punjabi: 'ਬੈਚ',
    },
    'applied across': {
      AppLanguage.hindi: 'में लागू',
      AppLanguage.haryanvi: 'मैं लगाया',
      AppLanguage.punjabi: 'ਵਿੱਚ ਲਾਗੂ',
    },
    'Application Summary:': {
      AppLanguage.hindi: 'प्रयोग सारांश:',
      AppLanguage.haryanvi: 'लगाण का सार:',
      AppLanguage.punjabi: 'ਵਰਤੋਂ ਸਾਰ:',
    },
    'Applied: Neem-coated Urea (45 kg/ha)': {
      AppLanguage.hindi: 'लागू: नीम कोटेड यूरिया (45 किग्रा/हेक्टेयर)',
      AppLanguage.haryanvi: 'गेर्या: नीम आला यूरिया (45 किलो/हेक्टेयर)',
      AppLanguage.punjabi: 'ਲਾਗੂ: ਨਿੰਮ-ਕੋਟਿਡ ਯੂਰੀਆ (45 ਕਿਲੋ/ਹੈਕਟੇਅਰ)',
    },
    'Area Covered: 4.2 hectares': {
      AppLanguage.hindi: 'क्षेत्र: 4.2 हेक्टेयर',
      AppLanguage.haryanvi: 'रकबा: 4.2 हेक्टेयर',
      AppLanguage.punjabi: 'ਰਕਬਾ: 4.2 ਹੈਕਟੇਅਰ',
    },
    'Satellite NDVI Response: +8% vigor increase': {
      AppLanguage.hindi: 'सैटेलाइट NDVI: +8% वृद्धि',
      AppLanguage.haryanvi: 'सैटेलाइट NDVI: +8% बढ़ोतरी',
      AppLanguage.punjabi: 'ਸੈਟੇਲਾਈਟ NDVI: +8% ਵਾਧਾ',
    },
    'Log refreshed.': {
      AppLanguage.hindi: 'लॉग ताज़ा किया गया।',
      AppLanguage.haryanvi: 'लॉग ताज़ा हो ग्या।',
      AppLanguage.punjabi: 'ਲਾਗ ਤਾਜ਼ਾ ਹੋ ਗਿਆ।',
    },
    'All past advisories up to date': {
      AppLanguage.hindi: 'सभी पुरानी सलाह अद्यतित',
      AppLanguage.haryanvi: 'सारी पुराणी सलाह अपडेट सै',
      AppLanguage.punjabi: 'ਸਾਰੀਆਂ ਪੁਰਾਣੀਆਂ ਸਲਾਹਾਂ ਅੱਪਡੇਟ',
    },

    // ─── Advisory detail screen ──────────────────────────────────────
    'Telemetry Node': {
      AppLanguage.hindi: 'टेलीमेट्री नोड',
      AppLanguage.haryanvi: 'टेलीमेट्री नोड',
      AppLanguage.punjabi: 'ਟੈਲੀਮੈਟਰੀ ਨੋਡ',
    },
    'Node': {
      AppLanguage.hindi: 'नोड',
      AppLanguage.haryanvi: 'नोड',
      AppLanguage.punjabi: 'ਨੋਡ',
    },
    'Location': {
      AppLanguage.hindi: 'स्थान',
      AppLanguage.haryanvi: 'जगहा',
      AppLanguage.punjabi: 'ਟਿਕਾਣਾ',
    },
    'Field 1: Plot A Cotton': {
      AppLanguage.hindi: 'खेत 1: प्लॉट ए कपास',
      AppLanguage.haryanvi: 'खेत 1: प्लॉट ए नरमा',
      AppLanguage.punjabi: 'ਖੇਤ 1: ਪਲਾਟ ਏ ਕਪਾਹ',
    },
    'Sensor Depth: 15cm Root Zone': {
      AppLanguage.hindi: 'सेंसर गहराई: 15 सेमी जड़ क्षेत्र',
      AppLanguage.haryanvi: 'सेंसर की गहराई: 15 सेमी जड़ां मैं',
      AppLanguage.punjabi: 'ਸੈਂਸਰ ਗਹਿਰਾਈ: 15 ਸੈਮੀ ਜੜ੍ਹ ਖੇਤਰ',
    },
    'Signal Strength: Excellent (-62 dBm)': {
      AppLanguage.hindi: 'सिग्नल: उत्कृष्ट (-62 dBm)',
      AppLanguage.haryanvi: 'सिग्नल: घणा बढ़िया (-62 dBm)',
      AppLanguage.punjabi: 'ਸਿਗਨਲ: ਬਹੁਤ ਵਧੀਆ (-62 dBm)',
    },
    'Valve Controller: Drip Valve #3 Ready': {
      AppLanguage.hindi: 'वाल्व कंट्रोलर: ड्रिप वाल्व #3 तैयार',
      AppLanguage.haryanvi: 'वाल्व कंट्रोलर: ड्रिप वाल्व #3 तैयार',
      AppLanguage.punjabi: 'ਵਾਲਵ ਕੰਟਰੋਲਰ: ਡ੍ਰਿਪ ਵਾਲਵ #3 ਤਿਆਰ',
    },
    'LIVE SOIL TELEMETRY': {
      AppLanguage.hindi: 'लाइव मिट्टी टेलीमेट्री',
      AppLanguage.haryanvi: 'लाइव माटी टेलीमेट्री',
      AppLanguage.punjabi: 'ਲਾਈਵ ਮਿੱਟੀ ਟੈਲੀਮੈਟਰੀ',
    },
    'Irrigation Advisory Detail': {
      AppLanguage.hindi: 'सिंचाई सलाह विवरण',
      AppLanguage.haryanvi: 'पाणी की सलाह की जाणकारी',
      AppLanguage.punjabi: 'ਸਿੰਜਾਈ ਸਲਾਹ ਵੇਰਵਾ',
    },
    'Soil Moisture Profile': {
      AppLanguage.hindi: 'मिट्टी नमी प्रोफ़ाइल',
      AppLanguage.haryanvi: 'माटी की नमी की हालत',
      AppLanguage.punjabi: 'ਮਿੱਟੀ ਨਮੀ ਪ੍ਰੋਫਾਈਲ',
    },
    'Deficit Detected': {
      AppLanguage.hindi: 'कमी पाई गई',
      AppLanguage.haryanvi: 'कमी मिली',
      AppLanguage.punjabi: 'ਕਮੀ ਮਿਲੀ',
    },
    'Current Moisture': {
      AppLanguage.hindi: 'वर्तमान नमी',
      AppLanguage.haryanvi: 'अबकी नमी',
      AppLanguage.punjabi: 'ਮੌਜੂਦਾ ਨਮੀ',
    },
    'Threshold': {
      AppLanguage.hindi: 'सीमा',
      AppLanguage.haryanvi: 'हद',
      AppLanguage.punjabi: 'ਹੱਦ',
    },
    'Target': {
      AppLanguage.hindi: 'लक्ष्य',
      AppLanguage.haryanvi: 'लक्ष्य',
      AppLanguage.punjabi: 'ਟੀਚਾ',
    },
    'High Evaporation Forecast': {
      AppLanguage.hindi: 'अधिक वाष्पीकरण का अनुमान',
      AppLanguage.haryanvi: 'घणा भाप बणण का अंदाजा',
      AppLanguage.punjabi: 'ਵੱਧ ਵਾਸ਼ਪੀਕਰਨ ਦਾ ਅੰਦਾਜ਼ਾ',
    },
    '0% Rain expected in 48h • Soil dries rapidly': {
      AppLanguage.hindi: '48 घंटे में बारिश नहीं • मिट्टी जल्दी सूखेगी',
      AppLanguage.haryanvi: '48 घंटे मैं बरसात नीं • माटी जल्दी सूखैगी',
      AppLanguage.punjabi: '48 ਘੰਟਿਆਂ ਵਿੱਚ ਮੀਂਹ ਨਹੀਂ • ਮਿੱਟੀ ਛੇਤੀ ਸੁੱਕੇਗੀ',
    },
    'Agronomic Reason': {
      AppLanguage.hindi: 'कृषि कारण',
      AppLanguage.haryanvi: 'खेती का कारण',
      AppLanguage.punjabi: 'ਖੇਤੀ ਕਾਰਨ',
    },
    'Moisture level is below the 55% root threshold during flowering stage. Watering today protects bloom retention.': {
      AppLanguage.hindi: 'फूल आने की अवस्था में नमी 55% जड़ सीमा से नीचे है। आज पानी देने से फूल बचे रहेंगे।',
      AppLanguage.haryanvi: 'फूल आण कै टैम नमी 55% तै नीचे सै। आज पाणी देओ तो फूल बचे रहवैंगे।',
      AppLanguage.punjabi: 'ਫੁੱਲ ਆਉਣ ਵੇਲੇ ਨਮੀ 55% ਜੜ੍ਹ ਹੱਦ ਤੋਂ ਹੇਠਾਂ ਹੈ। ਅੱਜ ਪਾਣੀ ਦੇਣ ਨਾਲ ਫੁੱਲ ਬਚੇ ਰਹਿਣਗੇ।',
    },
    'Duration': {
      AppLanguage.hindi: 'अवधि',
      AppLanguage.haryanvi: 'टैम',
      AppLanguage.punjabi: 'ਸਮਾਂ',
    },
    'Drip line': {
      AppLanguage.hindi: 'ड्रिप लाइन',
      AppLanguage.haryanvi: 'ड्रिप लाइन',
      AppLanguage.punjabi: 'ਡ੍ਰਿਪ ਲਾਈਨ',
    },
    'Volume': {
      AppLanguage.hindi: 'मात्रा',
      AppLanguage.haryanvi: 'मात्रा',
      AppLanguage.punjabi: 'ਮਾਤਰਾ',
    },
    'Calculated': {
      AppLanguage.hindi: 'गणना की गई',
      AppLanguage.haryanvi: 'हिसाब लगाया',
      AppLanguage.punjabi: 'ਗਣਨਾ ਕੀਤੀ',
    },
    'Savings': {
      AppLanguage.hindi: 'बचत',
      AppLanguage.haryanvi: 'बचत',
      AppLanguage.punjabi: 'ਬਚਤ',
    },
    'Night rate': {
      AppLanguage.hindi: 'रात की दर',
      AppLanguage.haryanvi: 'रात का रेट',
      AppLanguage.punjabi: 'ਰਾਤ ਦੀ ਦਰ',
    },
    'Irrigation APPROVED': {
      AppLanguage.hindi: 'सिंचाई स्वीकृत',
      AppLanguage.haryanvi: 'पाणी देणा मंजूर',
      AppLanguage.punjabi: 'ਸਿੰਜਾਈ ਮਨਜ਼ੂਰ',
    },
    'Irrigation has NOT started': {
      AppLanguage.hindi: 'सिंचाई शुरू नहीं हुई',
      AppLanguage.haryanvi: 'पाणी अजै चालू नीं होया',
      AppLanguage.punjabi: 'ਸਿੰਜਾਈ ਸ਼ੁਰੂ ਨਹੀਂ ਹੋਈ',
    },
    'Valves will automatically trigger at 05:30 PM.': {
      AppLanguage.hindi: 'वाल्व शाम 5:30 बजे स्वतः चालू होंगे।',
      AppLanguage.haryanvi: 'वाल्व सांझ 5:30 बजे आपै चालू हो जावैंगे।',
      AppLanguage.punjabi: 'ਵਾਲਵ ਸ਼ਾਮ 5:30 ਵਜੇ ਆਪੇ ਚਾਲੂ ਹੋਣਗੇ।',
    },
    'Awaiting manual confirmation before system can open valves.': {
      AppLanguage.hindi: 'वाल्व खोलने से पहले आपकी पुष्टि आवश्यक है।',
      AppLanguage.haryanvi: 'वाल्व खोलण तै पहल्या तेरी मंजूरी चाहिए।',
      AppLanguage.punjabi: 'ਵਾਲਵ ਖੋਲ੍ਹਣ ਤੋਂ ਪਹਿਲਾਂ ਤੁਹਾਡੀ ਪੁਸ਼ਟੀ ਚਾਹੀਦੀ ਹੈ।',
    },
    'Decline': {
      AppLanguage.hindi: 'अस्वीकार',
      AppLanguage.haryanvi: 'ना करो',
      AppLanguage.punjabi: 'ਨਾਂਹ ਕਰੋ',
    },
    'Approve': {
      AppLanguage.hindi: 'स्वीकृत करें',
      AppLanguage.haryanvi: 'मंजूर करो',
      AppLanguage.punjabi: 'ਮਨਜ਼ੂਰ ਕਰੋ',
    },
    'Approved': {
      AppLanguage.hindi: 'स्वीकृत',
      AppLanguage.haryanvi: 'मंजूर',
      AppLanguage.punjabi: 'ਮਨਜ਼ੂਰ',
    },
    'Sending...': {
      AppLanguage.hindi: 'भेज रहे हैं...',
      AppLanguage.haryanvi: 'भेज रहे सां...',
      AppLanguage.punjabi: 'ਭੇਜ ਰਹੇ ਹਾਂ...',
    },
    'Irrigation Approved': {
      AppLanguage.hindi: 'सिंचाई स्वीकृत',
      AppLanguage.haryanvi: 'पाणी देणा मंजूर',
      AppLanguage.punjabi: 'ਸਿੰਜਾਈ ਮਨਜ਼ੂਰ',
    },
    'Approval recorded by the field node.': {
      AppLanguage.hindi: 'फील्ड नोड ने स्वीकृति दर्ज कर ली।',
      AppLanguage.haryanvi: 'फील्ड नोड नै मंजूरी लिख ली।',
      AppLanguage.punjabi: 'ਫੀਲਡ ਨੋਡ ਨੇ ਮਨਜ਼ੂਰੀ ਦਰਜ ਕਰ ਲਈ।',
    },
    'Approval recorded. The field node will start': {
      AppLanguage.hindi: 'स्वीकृति दर्ज। फील्ड नोड शुरू करेगा',
      AppLanguage.haryanvi: 'मंजूरी लिख ली। फील्ड नोड चालू करैगा',
      AppLanguage.punjabi: 'ਮਨਜ਼ੂਰੀ ਦਰਜ। ਫੀਲਡ ਨੋਡ ਸ਼ੁਰੂ ਕਰੇਗਾ',
    },
    'for up to': {
      AppLanguage.hindi: 'अधिकतम',
      AppLanguage.haryanvi: 'ज्यादा तै ज्यादा',
      AppLanguage.punjabi: 'ਵੱਧ ਤੋਂ ਵੱਧ',
    },
    'minutes when it next checks in, and will report back once the relay is on.': {
      AppLanguage.hindi: 'मिनट के लिए, जब वह अगली बार जुड़ेगा, और रिले चालू होने पर सूचित करेगा।',
      AppLanguage.haryanvi: 'मिनट खातर, जद वो अगली बार जुड़ैगा, अर रिले चालू होण पै बता देगा।',
      AppLanguage.punjabi: 'ਮਿੰਟਾਂ ਲਈ, ਜਦੋਂ ਉਹ ਅਗਲੀ ਵਾਰ ਜੁੜੇਗਾ, ਤੇ ਰਿਲੇ ਚਾਲੂ ਹੋਣ ਤੇ ਦੱਸੇਗਾ।',
    },
    'Return to Dashboard': {
      AppLanguage.hindi: 'डैशबोर्ड पर लौटें',
      AppLanguage.haryanvi: 'डैशबोर्ड पै जाओ',
      AppLanguage.punjabi: 'ਡੈਸ਼ਬੋਰਡ ਤੇ ਵਾਪਸ ਜਾਓ',
    },
    'Irrigation was NOT approved — the field node did not confirm.': {
      AppLanguage.hindi: 'सिंचाई स्वीकृत नहीं हुई — फील्ड नोड ने पुष्टि नहीं की।',
      AppLanguage.haryanvi: 'पाणी देणा मंजूर नीं होया — फील्ड नोड नै पुष्टि नीं करी।',
      AppLanguage.punjabi: 'ਸਿੰਜਾਈ ਮਨਜ਼ੂਰ ਨਹੀਂ ਹੋਈ — ਫੀਲਡ ਨੋਡ ਨੇ ਪੁਸ਼ਟੀ ਨਹੀਂ ਕੀਤੀ।',
    },
    'Declined. The pump was not commanded.': {
      AppLanguage.hindi: 'अस्वीकृत। पंप को कोई आदेश नहीं भेजा गया।',
      AppLanguage.haryanvi: 'ना कर दी। पंप नै कोई हुकम नीं गया।',
      AppLanguage.punjabi: 'ਨਾਂਹ ਕਰ ਦਿੱਤੀ। ਪੰਪ ਨੂੰ ਕੋਈ ਹੁਕਮ ਨਹੀਂ ਗਿਆ।',
    },
    'Execution\nSequence': {
      AppLanguage.hindi: 'निष्पादन\nक्रम',
      AppLanguage.haryanvi: 'चलाण का\nक्रम',
      AppLanguage.punjabi: 'ਚਲਾਉਣ ਦਾ\nਕ੍ਰਮ',
    },
    'SCHEDULE\nPREVIEW': {
      AppLanguage.hindi: 'समय-सारणी\nपूर्वावलोकन',
      AppLanguage.haryanvi: 'टैम-सारणी\nझलक',
      AppLanguage.punjabi: 'ਸਮਾਂ-ਸਾਰਣੀ\nਝਲਕ',
    },
    'Drip Valve': {
      AppLanguage.hindi: 'ड्रिप वाल्व',
      AppLanguage.haryanvi: 'ड्रिप वाल्व',
      AppLanguage.punjabi: 'ਡ੍ਰਿਪ ਵਾਲਵ',
    },
    'Armed': {
      AppLanguage.hindi: 'तैयार',
      AppLanguage.haryanvi: 'तैयार',
      AppLanguage.punjabi: 'ਤਿਆਰ',
    },
    'Standby': {
      AppLanguage.hindi: 'प्रतीक्षारत',
      AppLanguage.haryanvi: 'इंतजार मैं',
      AppLanguage.punjabi: 'ਉਡੀਕ ਵਿੱਚ',
    },
    'Scheduled Start': {
      AppLanguage.hindi: 'निर्धारित शुरुआत',
      AppLanguage.haryanvi: 'तय शुरुआत',
      AppLanguage.punjabi: 'ਤੈਅ ਸ਼ੁਰੂਆਤ',
    },
    'Active Duration': {
      AppLanguage.hindi: 'सक्रिय अवधि',
      AppLanguage.haryanvi: 'चालू टैम',
      AppLanguage.punjabi: 'ਸਰਗਰਮ ਸਮਾਂ',
    },
    'Valve Hardware\nState': {
      AppLanguage.hindi: 'वाल्व हार्डवेयर\nस्थिति',
      AppLanguage.haryanvi: 'वाल्व हार्डवेयर\nहालत',
      AppLanguage.punjabi: 'ਵਾਲਵ ਹਾਰਡਵੇਅਰ\nਸਥਿਤੀ',
    },
    'Armed • Ready for 05:30 PM': {
      AppLanguage.hindi: 'तैयार • शाम 5:30 बजे के लिए',
      AppLanguage.haryanvi: 'तैयार • सांझ 5:30 बजे खातर',
      AppLanguage.punjabi: 'ਤਿਆਰ • ਸ਼ਾਮ 5:30 ਵਜੇ ਲਈ',
    },
    'Closed • Awaiting\nCommand': {
      AppLanguage.hindi: 'बंद • आदेश की\nप्रतीक्षा',
      AppLanguage.haryanvi: 'बंद • हुकम का\nइंतजार',
      AppLanguage.punjabi: 'ਬੰਦ • ਹੁਕਮ ਦੀ\nਉਡੀਕ',
    },
    'Water flow is authorized. Valve opens at 05:30 PM.': {
      AppLanguage.hindi: 'पानी की अनुमति है। वाल्व शाम 5:30 बजे खुलेगा।',
      AppLanguage.haryanvi: 'पाणी की इजाजत सै। वाल्व सांझ 5:30 बजे खुलैगा।',
      AppLanguage.punjabi: 'ਪਾਣੀ ਦੀ ਮਨਜ਼ੂਰੀ ਹੈ। ਵਾਲਵ ਸ਼ਾਮ 5:30 ਵਜੇ ਖੁੱਲ੍ਹੇਗਾ।',
    },
    'No water is flowing. Water starts strictly at 05:30 PM when authorized.': {
      AppLanguage.hindi: 'पानी नहीं बह रहा। अनुमति मिलने पर ठीक शाम 5:30 बजे शुरू होगा।',
      AppLanguage.haryanvi: 'पाणी नीं चाल रह्या। इजाजत मिलण पै ठीक सांझ 5:30 बजे चालू होगा।',
      AppLanguage.punjabi: 'ਪਾਣੀ ਨਹੀਂ ਵਗ ਰਿਹਾ। ਮਨਜ਼ੂਰੀ ਮਿਲਣ ਤੇ ਠੀਕ ਸ਼ਾਮ 5:30 ਵਜੇ ਸ਼ੁਰੂ ਹੋਵੇਗਾ।',
    },

    // ─── Scan result screen ──────────────────────────────────────────
    'Crop-health result': {
      AppLanguage.hindi: 'फसल स्वास्थ्य परिणाम',
      AppLanguage.haryanvi: 'फसल की हालत का नतीजा',
      AppLanguage.punjabi: 'ਫ਼ਸਲ ਸਿਹਤ ਨਤੀਜਾ',
    },
    'Retake the photo': {
      AppLanguage.hindi: 'फोटो दोबारा लें',
      AppLanguage.haryanvi: 'फोटो फेर तै खींचो',
      AppLanguage.punjabi: 'ਫੋਟੋ ਦੁਬਾਰਾ ਖਿੱਚੋ',
    },
    'Result inconclusive': {
      AppLanguage.hindi: 'परिणाम अनिर्णायक',
      AppLanguage.haryanvi: 'नतीजा साफ नीं',
      AppLanguage.punjabi: 'ਨਤੀਜਾ ਸਪਸ਼ਟ ਨਹੀਂ',
    },
    'Leaf appears healthy': {
      AppLanguage.hindi: 'पत्ती स्वस्थ दिखती है',
      AppLanguage.haryanvi: 'पत्ती तंदरुस्त लागै',
      AppLanguage.punjabi: 'ਪੱਤਾ ਤੰਦਰੁਸਤ ਲੱਗਦਾ ਹੈ',
    },
    'Possible': {
      AppLanguage.hindi: 'संभावित',
      AppLanguage.haryanvi: 'हो सकै',
      AppLanguage.punjabi: 'ਸੰਭਾਵਿਤ',
    },
    'Crop model': {
      AppLanguage.hindi: 'फसल मॉडल',
      AppLanguage.haryanvi: 'फसल मॉडल',
      AppLanguage.punjabi: 'ਫ਼ਸਲ ਮਾਡਲ',
    },
    'Model label': {
      AppLanguage.hindi: 'मॉडल लेबल',
      AppLanguage.haryanvi: 'मॉडल लेबल',
      AppLanguage.punjabi: 'ਮਾਡਲ ਲੇਬਲ',
    },
    'Confidence': {
      AppLanguage.hindi: 'विश्वास स्तर',
      AppLanguage.haryanvi: 'भरोसा',
      AppLanguage.punjabi: 'ਭਰੋਸਾ',
    },
    'Image quality': {
      AppLanguage.hindi: 'छवि गुणवत्ता',
      AppLanguage.haryanvi: 'फोटो की क्वालिटी',
      AppLanguage.punjabi: 'ਤਸਵੀਰ ਗੁਣਵੱਤਾ',
    },
    'AI runtime': {
      AppLanguage.hindi: 'AI रनटाइम',
      AppLanguage.haryanvi: 'AI रनटाइम',
      AppLanguage.punjabi: 'AI ਰਨਟਾਈਮ',
    },
    'Inference time': {
      AppLanguage.hindi: 'अनुमान समय',
      AppLanguage.haryanvi: 'नतीजे का टैम',
      AppLanguage.punjabi: 'ਅਨੁਮਾਨ ਸਮਾਂ',
    },
    'Recommended next step': {
      AppLanguage.hindi: 'अगला सुझाया कदम',
      AppLanguage.haryanvi: 'अगला सुझाया काम',
      AppLanguage.punjabi: 'ਅਗਲਾ ਸੁਝਾਇਆ ਕਦਮ',
    },
    'Use a clear, well-lit close-up containing one tomato leaf.': {
      AppLanguage.hindi: 'एक टमाटर की पत्ती की साफ, अच्छी रोशनी वाली नज़दीकी फोटो लें।',
      AppLanguage.haryanvi: 'एक टमाटर की पत्ती की साफ, चानण आली धोरे तै फोटो लो।',
      AppLanguage.punjabi: 'ਇੱਕ ਟਮਾਟਰ ਦੇ ਪੱਤੇ ਦੀ ਸਾਫ਼, ਚੰਗੀ ਰੌਸ਼ਨੀ ਵਾਲੀ ਨੇੜਲੀ ਫੋਟੋ ਲਵੋ।',
    },
    'Capture another clear close-up and inspect the plant directly.': {
      AppLanguage.hindi: 'एक और साफ नज़दीकी फोटो लें और पौधे को सीधे देखें।',
      AppLanguage.haryanvi: 'एक और साफ फोटो लो अर बूटे नै सीधा देखो।',
      AppLanguage.punjabi: 'ਇੱਕ ਹੋਰ ਸਾਫ਼ ਨੇੜਲੀ ਫੋਟੋ ਲਵੋ ਤੇ ਬੂਟੇ ਨੂੰ ਸਿੱਧਾ ਦੇਖੋ।',
    },
    'Continue regular monitoring. Scan again if visible symptoms develop.': {
      AppLanguage.hindi: 'नियमित निगरानी जारी रखें। लक्षण दिखें तो फिर स्कैन करें।',
      AppLanguage.haryanvi: 'रोज देखते रहो। लक्षण दिखै तो फेर स्कैन करो।',
      AppLanguage.punjabi: 'ਨਿਯਮਿਤ ਨਿਗਰਾਨੀ ਜਾਰੀ ਰੱਖੋ। ਲੱਛਣ ਦਿਖਣ ਤੇ ਫਿਰ ਸਕੈਨ ਕਰੋ।',
    },
    'Inspect nearby plants and consult a qualified agricultural advisor before applying treatment.': {
      AppLanguage.hindi: 'आस-पास के पौधे देखें और उपचार से पहले योग्य कृषि सलाहकार से पूछें।',
      AppLanguage.haryanvi: 'धोरे के बूटे देखो अर इलाज तै पहल्या कृषि सलाहकार तै पूछो।',
      AppLanguage.punjabi: 'ਨੇੜਲੇ ਬੂਟੇ ਦੇਖੋ ਤੇ ਇਲਾਜ ਤੋਂ ਪਹਿਲਾਂ ਯੋਗ ਖੇਤੀ ਸਲਾਹਕਾਰ ਤੋਂ ਪੁੱਛੋ।',
    },
    'Citadel provides decision support, not a final diagnosis. Confirm visible disease with a qualified agricultural professional before treatment.': {
      AppLanguage.hindi: 'सिटाडेल निर्णय में सहायता देता है, अंतिम निदान नहीं। उपचार से पहले किसी योग्य कृषि विशेषज्ञ से पुष्टि करें।',
      AppLanguage.haryanvi: 'सिटाडेल फैसले मैं मदद करै, आखरी नतीजा नीं। इलाज तै पहल्या कृषि माहिर तै पुष्टि करो।',
      AppLanguage.punjabi: 'ਸਿਟਾਡੇਲ ਫ਼ੈਸਲੇ ਵਿੱਚ ਮਦਦ ਦਿੰਦਾ ਹੈ, ਅੰਤਿਮ ਨਿਦਾਨ ਨਹੀਂ। ਇਲਾਜ ਤੋਂ ਪਹਿਲਾਂ ਯੋਗ ਖੇਤੀ ਮਾਹਿਰ ਤੋਂ ਪੁਸ਼ਟੀ ਕਰੋ।',
    },
    'Scan another tomato leaf': {
      AppLanguage.hindi: 'दूसरी टमाटर पत्ती स्कैन करें',
      AppLanguage.haryanvi: 'दूसरी टमाटर की पत्ती स्कैन करो',
      AppLanguage.punjabi: 'ਹੋਰ ਟਮਾਟਰ ਪੱਤਾ ਸਕੈਨ ਕਰੋ',
    },
    'Back to farm overview': {
      AppLanguage.hindi: 'खेत सारांश पर लौटें',
      AppLanguage.haryanvi: 'खेत के सार पै जाओ',
      AppLanguage.punjabi: 'ਖੇਤ ਸੰਖੇਪ ਤੇ ਵਾਪਸ',
    },
    'The current AI model analyzes a close-up of one tomato leaf.': {
      AppLanguage.hindi: 'वर्तमान AI मॉडल एक टमाटर पत्ती की नज़दीकी फोटो जांचता है।',
      AppLanguage.haryanvi: 'अबका AI मॉडल एक टमाटर की पत्ती की धोरे तै फोटो जांचै।',
      AppLanguage.punjabi: 'ਮੌਜੂਦਾ AI ਮਾਡਲ ਇੱਕ ਟਮਾਟਰ ਪੱਤੇ ਦੀ ਨੇੜਲੀ ਫੋਟੋ ਜਾਂਚਦਾ ਹੈ।',
    },
    'Camera or image access failed': {
      AppLanguage.hindi: 'कैमरा या छवि पहुंच विफल',
      AppLanguage.haryanvi: 'कैमरा या फोटो नीं खुल्या',
      AppLanguage.punjabi: 'ਕੈਮਰਾ ਜਾਂ ਤਸਵੀਰ ਪਹੁੰਚ ਅਸਫਲ',
    },
    'Error updating photo': {
      AppLanguage.hindi: 'फोटो अपडेट करने में त्रुटि',
      AppLanguage.haryanvi: 'फोटो बदलण मैं गलती',
      AppLanguage.punjabi: 'ਫੋਟੋ ਅੱਪਡੇਟ ਕਰਨ ਵਿੱਚ ਗਲਤੀ',
    },
    'Citadel Farmer App': {
      AppLanguage.hindi: 'सिटाडेल किसान ऐप',
      AppLanguage.haryanvi: 'सिटाडेल किसान ऐप',
      AppLanguage.punjabi: 'ਸਿਟਾਡੇਲ ਕਿਸਾਨ ਐਪ',
    },
    'offline-first': {
      AppLanguage.hindi: 'ऑफलाइन-प्रथम',
      AppLanguage.haryanvi: 'ऑफलाइन पहल्या',
      AppLanguage.punjabi: 'ਆਫਲਾਈਨ-ਪਹਿਲ',
    },
  };

  /// Primary translate API — pass the current [AppLanguage].
  ///
  /// For [AppLanguage.english] the [key] is returned unchanged.
  /// For others it looks up the language-specific map, falling back to
  /// Hindi → then the English key if no entry is found.
  static String translate(String key, dynamic langOrBool) {
    // Support both new AppLanguage enum and legacy bool for backward compat.
    final AppLanguage lang;
    if (langOrBool is bool) {
      lang = langOrBool ? AppLanguage.hindi : AppLanguage.english;
    } else {
      lang = langOrBool as AppLanguage;
    }

    // Exact match first — for namespaced keys (severity.*, alertType.*,
    // freshness.*) the English display text lives in the map, so English must
    // consult it before falling through to returning the key verbatim.
    final entry = _translations[key];
    if (entry != null) {
      final value = entry[lang];
      if (value != null) return value;
      if (lang == AppLanguage.english) return key;
      final hindiValue = entry[AppLanguage.hindi];
      if (hindiValue != null) return hindiValue;
    }

    if (lang == AppLanguage.english) return key;

    // Composite fallback: substitute known phrases inside an interpolated
    // string. Longest key first so "Soil Moisture" wins over "Moisture", and
    // word-boundary matched so short keys cannot corrupt longer words.
    final keys = _translations.keys.where((k) => k.length > 3).toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    String translated = key;
    for (final eng in keys) {
      if (!translated.contains(eng)) continue;
      final replacement =
          _translations[eng]![lang] ?? _translations[eng]![AppLanguage.hindi];
      if (replacement == null) continue;
      translated = translated.replaceAllMapped(
        RegExp('(?<![A-Za-z])${RegExp.escape(eng)}(?![A-Za-z])'),
        (_) => replacement,
      );
    }

    return translated;
  }
}

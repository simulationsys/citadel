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

    if (lang == AppLanguage.english) return key;

    // Exact match
    final entry = _translations[key];
    if (entry != null) {
      final value = entry[lang];
      if (value != null) return value;
      // Fallback: Hindi if available
      if (lang != AppLanguage.hindi) {
        final hindiValue = entry[AppLanguage.hindi];
        if (hindiValue != null) return hindiValue;
      }
    }

    // Dynamic translation for composite text containing known keys
    String translated = key;
    _translations.forEach((eng, langMap) {
      if (eng.length > 2 && translated.contains(eng)) {
        final replacement = langMap[lang] ?? langMap[AppLanguage.hindi];
        if (replacement != null) {
          translated = translated.replaceAll(eng, replacement);
        }
      }
    });

    return translated;
  }
}

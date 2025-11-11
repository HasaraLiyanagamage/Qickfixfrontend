import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  // Translations map
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Common
      'app_name': 'QuickFix',
      'welcome': 'Welcome',
      'login': 'Login',
      'register': 'Register',
      'logout': 'Logout',
      'cancel': 'Cancel',
      'save': 'Save',
      'submit': 'Submit',
      'delete': 'Delete',
      'edit': 'Edit',
      'search': 'Search',
      'filter': 'Filter',
      'refresh': 'Refresh',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'confirm': 'Confirm',
      'yes': 'Yes',
      'no': 'No',
      
      // Navigation
      'home': 'Home',
      'bookings': 'Bookings',
      'profile': 'Profile',
      'settings': 'Settings',
      'chat': 'Chat',
      'jobs': 'Jobs',
      'users': 'Users',
      
      // Home Screen
      'how_can_help': 'How can we help you today?',
      'quick_actions': 'Quick Actions',
      'our_services': 'Our Services',
      'recent_bookings': 'Recent Bookings',
      'view_all': 'View All',
      'start_first_service': 'Start by requesting your first service',
      'request_first_service': 'Request Your First Service',
      
      // Settings
      'theme': 'Theme',
      'language': 'Language',
      'dark_mode': 'Dark Mode',
      'light_mode': 'Light Mode',
      'select_language': 'Select Language',
      'appearance': 'Appearance',
      'preferences': 'Preferences',
      'notifications': 'Notifications',
      'account': 'Account',
      
      // Bookings
      'my_bookings': 'My Bookings',
      'request_service': 'Request Service',
      'service_type': 'Service Type',
      'location': 'Location',
      'status': 'Status',
      'all_bookings': 'All Bookings',
      'active': 'Active',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
      'requested': 'Requested',
      'matched': 'Matched',
      'accepted': 'Accepted',
      'in_progress': 'In Progress',
      
      // Services
      'plumbing': 'Plumbing',
      'electrical': 'Electrical',
      'handyman': 'Handyman',
      'appliance': 'Appliance Repair',
      
      // Actions
      'call': 'Call',
      'navigate': 'Navigate',
      'track': 'Track',
      'rate_service': 'Rate Service',
      'rate_customer': 'Rate Customer',
      'accept': 'Accept',
      'decline': 'Decline',
      'start': 'Start',
      'complete': 'Complete',
      
      // Messages
      'no_bookings': 'No bookings yet',
      'no_jobs': 'No jobs available',
      'loading_bookings': 'Loading bookings...',
      'booking_created': 'Booking created successfully',
      'booking_updated': 'Booking updated',
      'error_loading': 'Error loading data',
      'phone_not_available': 'Phone number not available',
      'location_not_available': 'Location not available',
      'thank_you_rating': 'Thank you for your rating!',
      
      // Chat
      'type_message': 'Type a message...',
      'send': 'Send',
      'no_messages': 'No messages yet',
      'start_conversation': 'Start a conversation',
      
      // Profile
      'name': 'Name',
      'email': 'Email',
      'phone': 'Phone',
      'address': 'Address',
      'update_profile': 'Update Profile',
      'profile_updated': 'Profile updated successfully',
      
      // Rating
      'rating': 'Rating',
      'review': 'Review',
      'write_review': 'Write a review (optional)',
      'how_was_experience': 'How was your experience?',
      
      // Technician
      'my_jobs': 'My Jobs',
      'available_jobs': 'Available',
      'skills': 'Skills',
      'availability': 'Availability',
      'available': 'Available',
      'unavailable': 'Unavailable',
      
      // Admin
      'dashboard': 'Dashboard',
      'total_users': 'Total Users',
      'total_technicians': 'Total Technicians',
      'total_bookings': 'Total Bookings',
      'active_bookings': 'Active Bookings',
      'system_stats': 'System Statistics',
    },
    'si': {
      // Common
      'app_name': 'QuickFix',
      'welcome': 'ස්වාගතයි',
      'login': 'ඇතුල් වන්න',
      'register': 'ලියාපදිංචි වන්න',
      'logout': 'ඉවත් වන්න',
      'cancel': 'අවලංගු කරන්න',
      'save': 'සුරකින්න',
      'submit': 'ඉදිරිපත් කරන්න',
      'delete': 'මකන්න',
      'edit': 'සංස්කරණය',
      'search': 'සොයන්න',
      'filter': 'පෙරහන',
      'refresh': 'නැවුම් කරන්න',
      'loading': 'පූරණය වෙමින්...',
      'error': 'දෝෂයකි',
      'success': 'සාර්ථකයි',
      'confirm': 'තහවුරු කරන්න',
      'yes': 'ඔව්',
      'no': 'නැත',
      
      // Navigation
      'home': 'මුල් පිටුව',
      'bookings': 'වෙන්කිරීම්',
      'profile': 'පැතිකඩ',
      'settings': 'සැකසුම්',
      'chat': 'කතාබස්',
      'jobs': 'රැකියා',
      'users': 'පරිශීලකයින්',
      
      // Home Screen
      'how_can_help': 'අද අපට ඔබට කෙසේ උදව් කළ හැකිද?',
      'quick_actions': 'ඉක්මන් ක්‍රියා',
      'our_services': 'අපගේ සේවා',
      'recent_bookings': 'මෑත වෙන්කිරීම්',
      'view_all': 'සියල්ල බලන්න',
      'start_first_service': 'ඔබේ පළමු සේවාව ඉල්ලීමෙන් ආරම්භ කරන්න',
      'request_first_service': 'ඔබේ පළමු සේවාව ඉල්ලන්න',
      
      // Settings
      'theme': 'තේමාව',
      'language': 'භාෂාව',
      'dark_mode': 'අඳුරු මාදිලිය',
      'light_mode': 'ආලෝක මාදිලිය',
      'select_language': 'භාෂාව තෝරන්න',
      'appearance': 'පෙනුම',
      'preferences': 'මනාපයන්',
      'notifications': 'දැනුම්දීම්',
      'account': 'ගිණුම',
      
      // Bookings
      'my_bookings': 'මගේ වෙන්කිරීම්',
      'request_service': 'සේවාව ඉල්ලන්න',
      'service_type': 'සේවා වර්ගය',
      'location': 'ස්ථානය',
      'status': 'තත්ත්වය',
      'all_bookings': 'සියලු වෙන්කිරීම්',
      'active': 'ක්‍රියාකාරී',
      'completed': 'සම්පූර්ණ',
      'cancelled': 'අවලංගු',
      'requested': 'ඉල්ලා ඇත',
      'matched': 'ගැලපේ',
      'accepted': 'පිළිගත්',
      'in_progress': 'ක්‍රියාත්මක',
      
      // Services
      'plumbing': 'ජල නල',
      'electrical': 'විදුලි',
      'handyman': 'අත්කම්කරු',
      'appliance': 'උපකරණ අලුත්වැඩියා',
      
      // Actions
      'call': 'අමතන්න',
      'navigate': 'යොමු කරන්න',
      'track': 'ලුහුබඳින්න',
      'rate_service': 'සේවාව ශ්‍රේණිගත කරන්න',
      'rate_customer': 'පාරිභෝගිකයා ශ්‍රේණිගත කරන්න',
      'accept': 'පිළිගන්න',
      'decline': 'ප්‍රතික්ෂේප කරන්න',
      'start': 'ආරම්භ කරන්න',
      'complete': 'සම්පූර්ණ කරන්න',
      
      // Messages
      'no_bookings': 'තවම වෙන්කිරීම් නැත',
      'no_jobs': 'රැකියා නොමැත',
      'loading_bookings': 'වෙන්කිරීම් පූරණය වෙමින්...',
      'booking_created': 'වෙන්කිරීම සාර්ථකව නිර්මාණය විය',
      'booking_updated': 'වෙන්කිරීම යාවත්කාලීන විය',
      'error_loading': 'දත්ත පූරණයේ දෝෂයකි',
      'phone_not_available': 'දුරකථන අංකය නොමැත',
      'location_not_available': 'ස්ථානය නොමැත',
      'thank_you_rating': 'ඔබේ ශ්‍රේණිගත කිරීමට ස්තූතියි!',
      
      // Chat
      'type_message': 'පණිවිඩයක් ටයිප් කරන්න...',
      'send': 'යවන්න',
      'no_messages': 'තවම පණිවිඩ නැත',
      'start_conversation': 'සංවාදයක් ආරම්භ කරන්න',
      
      // Profile
      'name': 'නම',
      'email': 'විද්‍යුත් තැපෑල',
      'phone': 'දුරකථනය',
      'address': 'ලිපිනය',
      'update_profile': 'පැතිකඩ යාවත්කාලීන කරන්න',
      'profile_updated': 'පැතිකඩ සාර්ථකව යාවත්කාලීන විය',
      
      // Rating
      'rating': 'ශ්‍රේණිගත කිරීම',
      'review': 'සමාලෝචනය',
      'write_review': 'සමාලෝචනයක් ලියන්න (විකල්ප)',
      'how_was_experience': 'ඔබේ අත්දැකීම කෙසේද?',
      
      // Technician
      'my_jobs': 'මගේ රැකියා',
      'available_jobs': 'ලබා ගත හැකි',
      'skills': 'කුසලතා',
      'availability': 'ලබා ගත හැකි බව',
      'available': 'ලබා ගත හැකි',
      'unavailable': 'නොමැත',
      
      // Admin
      'dashboard': 'උපකරණ පුවරුව',
      'total_users': 'මුළු පරිශීලකයින්',
      'total_technicians': 'මුළු කාර්මිකයින්',
      'total_bookings': 'මුළු වෙන්කිරීම්',
      'active_bookings': 'ක්‍රියාකාරී වෙන්කිරීම්',
      'system_stats': 'පද්ධති සංඛ්‍යාලේඛන',
    },
    'ta': {
      // Common
      'app_name': 'QuickFix',
      'welcome': 'வரவேற்கிறோம்',
      'login': 'உள்நுழைய',
      'register': 'பதிவு செய்க',
      'logout': 'வெளியேறு',
      'cancel': 'ரத்து செய்',
      'save': 'சேமி',
      'submit': 'சமர்ப்பி',
      'delete': 'நீக்கு',
      'edit': 'திருத்து',
      'search': 'தேடு',
      'filter': 'வடிகட்டி',
      'refresh': 'புதுப்பி',
      'loading': 'ஏற்றுகிறது...',
      'error': 'பிழை',
      'success': 'வெற்றி',
      'confirm': 'உறுதிப்படுத்து',
      'yes': 'ஆம்',
      'no': 'இல்லை',
      
      // Navigation
      'home': 'முகப்பு',
      'bookings': 'முன்பதிவுகள்',
      'profile': 'சுயவிவரம்',
      'settings': 'அமைப்புகள்',
      'chat': 'அரட்டை',
      'jobs': 'வேலைகள்',
      'users': 'பயனர்கள்',
      
      // Home Screen
      'how_can_help': 'இன்று நாங்கள் உங்களுக்கு எவ்வாறு உதவ முடியும்?',
      'quick_actions': 'விரைவு செயல்கள்',
      'our_services': 'எங்கள் சேவைகள்',
      'recent_bookings': 'சமீபத்திய முன்பதிவுகள்',
      'view_all': 'அனைத்தையும் காண்க',
      'start_first_service': 'உங்கள் முதல் சேவையைக் கோருவதன் மூலம் தொடங்குங்கள்',
      'request_first_service': 'உங்கள் முதல் சேவையைக் கோருங்கள்',
      
      // Settings
      'theme': 'தீம்',
      'language': 'மொழி',
      'dark_mode': 'இருண்ட பயன்முறை',
      'light_mode': 'ஒளி பயன்முறை',
      'select_language': 'மொழியைத் தேர்ந்தெடு',
      'appearance': 'தோற்றம்',
      'preferences': 'விருப்பத்தேர்வுகள்',
      'notifications': 'அறிவிப்புகள்',
      'account': 'கணக்கு',
      
      // Bookings
      'my_bookings': 'எனது முன்பதிவுகள்',
      'request_service': 'சேவையைக் கோரு',
      'service_type': 'சேவை வகை',
      'location': 'இடம்',
      'status': 'நிலை',
      'all_bookings': 'அனைத்து முன்பதிவுகள்',
      'active': 'செயலில்',
      'completed': 'முடிந்தது',
      'cancelled': 'ரத்து செய்யப்பட்டது',
      'requested': 'கோரப்பட்டது',
      'matched': 'பொருந்தியது',
      'accepted': 'ஏற்றுக்கொள்ளப்பட்டது',
      'in_progress': 'முன்னேற்றத்தில்',
      
      // Services
      'plumbing': 'குழாய் பணி',
      'electrical': 'மின்சாரம்',
      'handyman': 'கைவினைஞர்',
      'appliance': 'சாதன பழுதுபார்ப்பு',
      
      // Actions
      'call': 'அழை',
      'navigate': 'வழிகாட்டு',
      'track': 'கண்காணி',
      'rate_service': 'சேவையை மதிப்பிடு',
      'rate_customer': 'வாடிக்கையாளரை மதிப்பிடு',
      'accept': 'ஏற்று',
      'decline': 'நிராகரி',
      'start': 'தொடங்கு',
      'complete': 'முடி',
      
      // Messages
      'no_bookings': 'இன்னும் முன்பதிவுகள் இல்லை',
      'no_jobs': 'வேலைகள் இல்லை',
      'loading_bookings': 'முன்பதிவுகள் ஏற்றப்படுகின்றன...',
      'booking_created': 'முன்பதிவு வெற்றிகரமாக உருவாக்கப்பட்டது',
      'booking_updated': 'முன்பதிவு புதுப்பிக்கப்பட்டது',
      'error_loading': 'தரவு ஏற்றுவதில் பிழை',
      'phone_not_available': 'தொலைபேசி எண் கிடைக்கவில்லை',
      'location_not_available': 'இடம் கிடைக்கவில்லை',
      'thank_you_rating': 'உங்கள் மதிப்பீட்டிற்கு நன்றி!',
      
      // Chat
      'type_message': 'செய்தியை தட்டச்சு செய்க...',
      'send': 'அனுப்பு',
      'no_messages': 'இன்னும் செய்திகள் இல்லை',
      'start_conversation': 'உரையாடலைத் தொடங்கு',
      
      // Profile
      'name': 'பெயர்',
      'email': 'மின்னஞ்சல்',
      'phone': 'தொலைபேசி',
      'address': 'முகவரி',
      'update_profile': 'சுயவிவரத்தைப் புதுப்பி',
      'profile_updated': 'சுயவிவரம் வெற்றிகரமாக புதுப்பிக்கப்பட்டது',
      
      // Rating
      'rating': 'மதிப்பீடு',
      'review': 'விமர்சனம்',
      'write_review': 'விமர்சனம் எழுதுக (விருப்பம்)',
      'how_was_experience': 'உங்கள் அனுபவம் எப்படி இருந்தது?',
      
      // Technician
      'my_jobs': 'எனது வேலைகள்',
      'available_jobs': 'கிடைக்கும்',
      'skills': 'திறன்கள்',
      'availability': 'கிடைக்கும் தன்மை',
      'available': 'கிடைக்கும்',
      'unavailable': 'கிடைக்கவில்லை',
      
      // Admin
      'dashboard': 'டாஷ்போர்டு',
      'total_users': 'மொத்த பயனர்கள்',
      'total_technicians': 'மொத்த தொழில்நுட்பவியலாளர்கள்',
      'total_bookings': 'மொத்த முன்பதிவுகள்',
      'active_bookings': 'செயலில் உள்ள முன்பதிவுகள்',
      'system_stats': 'கணினி புள்ளிவிவரங்கள்',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Convenience getters
  String get appName => translate('app_name');
  String get welcome => translate('welcome');
  String get login => translate('login');
  String get register => translate('register');
  String get logout => translate('logout');
  String get home => translate('home');
  String get bookings => translate('bookings');
  String get profile => translate('profile');
  String get settings => translate('settings');
  String get chat => translate('chat');
  String get theme => translate('theme');
  String get language => translate('language');
  String get darkMode => translate('dark_mode');
  String get lightMode => translate('light_mode');
  String get selectLanguage => translate('select_language');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'si', 'ta'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

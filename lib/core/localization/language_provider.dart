import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/auth/constants/lang_constants.dart';

final languageProvider = StateNotifierProvider<LanguageNotifier, Lang>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<Lang> {
  LanguageNotifier() : super(Lang.en) {
    _load();
  }

  static const _storageKey = 'app_language';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> _load() async {
    final value = await _storage.read(key: _storageKey);
    if (value == 'am') state = Lang.am;
  }

  Future<void> setLanguage(Lang language) async {
    state = language;
    await _storage.write(
      key: _storageKey,
      value: language == Lang.am ? 'am' : 'en',
    );
  }
}

class AppText {
  AppText(this.lang);

  final Lang lang;
  bool get isAmharic => lang == Lang.am;

  String get home => isAmharic ? 'መነሻ' : 'Home';
  String get stock => isAmharic ? 'እቃዎች' : 'Stock';
  String get cashier => isAmharic ? 'ካሺየር' : 'Cashier';
  String get cutter => isAmharic ? 'ቆራጭ' : 'Cutter';
  String get history => isAmharic ? 'ታሪክ' : 'History';
  String get chat => isAmharic ? 'ውይይት' : 'Chat';
  String get profile => isAmharic ? 'መገለጫ' : 'Profile';
  String get dashboard => isAmharic ? 'ዳሽቦርድ' : 'Dashboard';
  String get changePassword => isAmharic ? 'የይለፍ ቃል ቀይር' : 'Change Password';
  String get logout => isAmharic ? 'ውጣ' : 'Logout';
  String get welcomeBack => isAmharic ? 'እንኳን ደህና መጡ' : 'Welcome back';
  String get accountDetails => isAmharic ? 'የመለያ ዝርዝሮች' : 'Account Details';
  String get fullName => isAmharic ? 'ሙሉ ስም' : 'Full Name';
  String get phone => isAmharic ? 'ስልክ' : 'Phone';
  String get role => isAmharic ? 'ሚና' : 'Role';
  String get status => isAmharic ? 'ሁኔታ' : 'Status';
  String get settings => isAmharic ? 'ቅንብሮች' : 'Settings';
  String get alertSettings => isAmharic ? 'የማሳወቂያ ቅንብሮች' : 'Alert Settings';
  String get salesOverview => isAmharic ? 'የሽያጭ አጠቃላይ እይታ' : 'Sales Overview';
  String get totalRevenue => isAmharic ? 'ጠቅላላ ገቢ' : 'Total Revenue';
  String get cashSales => isAmharic ? 'የጥሬ ገንዘብ ሽያጭ' : 'Cash Sales';
  String get cashCollected => isAmharic ? 'የተሰበሰበ ጥሬ ገንዘብ' : 'Cash collected';
  String get creditOverview => isAmharic ? 'የዱቤ አጠቃላይ እይታ' : 'Credit Overview';
  String get creditAccounts => isAmharic ? 'የዱቤ መለያዎች' : 'Credit Accounts';
  String get creditCustomers => isAmharic ? 'የዱቤ ደንበኞች' : 'Credit Customers';
  String get noCreditCustomers => isAmharic ? 'እስካሁን የዱቤ ደንበኛ የለም' : 'No credit customers yet';
}

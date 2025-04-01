import 'package:flutter_dotenv/flutter_dotenv.dart';

/// A utility class to access environment variables from the .env file
class EnvConfig {
  /// Loads the .env file
  static Future<void> load() async {
    await dotenv.load();
  }

  /// Gets a value from the .env file
  /// 
  /// Returns the value or an empty string if not found
  static String get(String key) {
    return dotenv.env[key] ?? '';
  }

  /// Firebase Web Configuration
  static String get firebaseWebApiKey => get('FIREBASE_WEB_API_KEY');
  static String get firebaseWebAppId => get('FIREBASE_WEB_APP_ID');
  static String get firebaseWebMessagingSenderId => get('FIREBASE_WEB_MESSAGING_SENDER_ID');
  static String get firebaseWebProjectId => get('FIREBASE_WEB_PROJECT_ID');
  static String get firebaseWebAuthDomain => get('FIREBASE_WEB_AUTH_DOMAIN');
  static String get firebaseWebStorageBucket => get('FIREBASE_WEB_STORAGE_BUCKET');
  static String get firebaseWebMeasurementId => get('FIREBASE_WEB_MEASUREMENT_ID');
  static String get firebaseWebDatabaseUrl => get('FIREBASE_WEB_DATABASE_URL');

  /// Firebase Android Configuration
  static String get firebaseAndroidApiKey => get('FIREBASE_ANDROID_API_KEY');
  static String get firebaseAndroidAppId => get('FIREBASE_ANDROID_APP_ID');
  static String get firebaseAndroidMessagingSenderId => get('FIREBASE_ANDROID_MESSAGING_SENDER_ID');
  static String get firebaseAndroidProjectId => get('FIREBASE_ANDROID_PROJECT_ID');
  static String get firebaseAndroidStorageBucket => get('FIREBASE_ANDROID_STORAGE_BUCKET');

  /// Firebase iOS Configuration
  static String get firebaseIosApiKey => get('FIREBASE_IOS_API_KEY');
  static String get firebaseIosAppId => get('FIREBASE_IOS_APP_ID');
  static String get firebaseIosMessagingSenderId => get('FIREBASE_IOS_MESSAGING_SENDER_ID');
  static String get firebaseIosProjectId => get('FIREBASE_IOS_PROJECT_ID');
  static String get firebaseIosStorageBucket => get('FIREBASE_IOS_STORAGE_BUCKET');
  static String get firebaseIosClientId => get('FIREBASE_IOS_CLIENT_ID');
  static String get firebaseIosBundleId => get('FIREBASE_IOS_BUNDLE_ID');
}

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:vanishingtictactoe/core/config/env_config.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Web configuration
  static FirebaseOptions get web => FirebaseOptions(
    apiKey: EnvConfig.firebaseWebApiKey,
    appId: EnvConfig.firebaseWebAppId,
    messagingSenderId: EnvConfig.firebaseWebMessagingSenderId,
    projectId: EnvConfig.firebaseWebProjectId,
    authDomain: EnvConfig.firebaseWebAuthDomain,
    storageBucket: EnvConfig.firebaseWebStorageBucket,
    measurementId: EnvConfig.firebaseWebMeasurementId,
    databaseURL: EnvConfig.firebaseWebDatabaseUrl,
  );

  // Android configuration
  static FirebaseOptions get android => FirebaseOptions(
    apiKey: EnvConfig.firebaseAndroidApiKey,
    appId: EnvConfig.firebaseAndroidAppId,
    messagingSenderId: EnvConfig.firebaseAndroidMessagingSenderId,
    projectId: EnvConfig.firebaseAndroidProjectId,
    storageBucket: EnvConfig.firebaseAndroidStorageBucket,
  );

  // iOS configuration
  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: EnvConfig.firebaseIosApiKey,
    appId: EnvConfig.firebaseIosAppId,
    messagingSenderId: EnvConfig.firebaseIosMessagingSenderId,
    projectId: EnvConfig.firebaseIosProjectId,
    storageBucket: EnvConfig.firebaseIosStorageBucket,
    iosClientId: EnvConfig.firebaseIosClientId,
    iosBundleId: EnvConfig.firebaseIosBundleId,
  );
}

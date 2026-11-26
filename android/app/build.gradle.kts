plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Le plugin google-services lit android/app/google-services.json et génère les
// ressources FirebaseOptions. Il ne peut pas être listé dans `plugins { }` :
// ce bloc est évalué avant que l'on puisse tester la présence du fichier, et le
// plugin fait échouer la configuration quand il manque.
//
// L'appliquer conditionnellement laisse le dépôt compilable pour un contributeur
// sans accès au projet Firebase — l'application démarre alors sans push, ce que
// le code Dart gère explicitement (voir FirebasePushService.initialize, qui
// renvoie false quand la configuration manque).
val googleServicesConfig = file("google-services.json")
if (googleServicesConfig.exists()) {
    apply(plugin = "com.google.gms.google-services")
} else {
    logger.lifecycle(
        "google-services.json absent : notifications push désactivées dans ce build."
    )
}

android {
    namespace = "app.tonde"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Exigé par flutter_local_notifications (API java.time sur Android).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "app.tonde"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // flutter_local_notifications exige Android 7.0 (API 24) au minimum.
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Dégazage des API Java récentes utilisées par les notifications locales.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

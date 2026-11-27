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

// Signature de release fournie par l'environnement (CI) : chemin du fichier
// + mots de passe en variables. Absente en développement, on garde alors la
// clé de debug pour que `flutter run --release` continue de fonctionner.
//
// Sans clé stable, chaque build CI génère un nouveau keystore de debug : la
// signature change à chaque version et Android refuse d'installer la mise à
// jour par-dessus l'application existante (« App not installed »).
val releaseKeystorePath: String? = System.getenv("TONDE_KEYSTORE_PATH")

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

    signingConfigs {
        if (!releaseKeystorePath.isNullOrBlank()) {
            val keystorePath = releaseKeystorePath
            create("release") {
                storeFile = file(keystorePath)
                storePassword = System.getenv("TONDE_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("TONDE_KEY_ALIAS")
                keyPassword = System.getenv("TONDE_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (!releaseKeystorePath.isNullOrBlank()) {
                signingConfigs.getByName("release")
            } else {
                // Repli de développement uniquement : signature instable d'une
                // machine à l'autre, donc inutilisable pour distribuer.
                signingConfigs.getByName("debug")
            }
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

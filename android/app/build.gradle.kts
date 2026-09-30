import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Mağaza imzası: android/key.properties (yerel) ya da CI'da ortam değişkenleri. İkisi de yoksa release
// derlemesi debug anahtarıyla imzalanır (yalnızca deneme APK'sı içindir, mağazaya yüklenemez).
val anahtarAyarlari = Properties().apply {
    val dosya = rootProject.file("key.properties")
    if (dosya.exists()) dosya.inputStream().use { load(it) }
}

fun imzaDegeri(ad: String, ortam: String): String? = anahtarAyarlari.getProperty(ad) ?: System.getenv(ortam)

android {
    namespace = "tr.com.ayasyazilim.pusula"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications (zamanlanmış bildirimler) için gerekli.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "tr.com.ayasyazilim.pusula"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("magaza") {
            val depo = imzaDegeri("storeFile", "ANDROID_KEYSTORE_FILE")
            if (depo != null) {
                storeFile = file(depo)
                storePassword = imzaDegeri("storePassword", "ANDROID_KEYSTORE_PASSWORD")
                keyAlias = imzaDegeri("keyAlias", "ANDROID_KEY_ALIAS")
                keyPassword = imzaDegeri("keyPassword", "ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            val magazaImzasiVar = imzaDegeri("storeFile", "ANDROID_KEYSTORE_FILE") != null
            signingConfig = signingConfigs.getByName(if (magazaImzasiVar) "magaza" else "debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}

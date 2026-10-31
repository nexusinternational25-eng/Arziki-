import java.util.Properties

plugins {
    id("com.android.application")
    // Le plugin Flutter doit être appliqué après les plugins Android et Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

// Clé de signature : lue dans android/key.properties, qui n'est JAMAIS dans Git
// (CLAUDE.md, section 16). Sans ce fichier, la version release est signée
// avec la clé de débogage, ce qui suffit pour tester mais pas pour publier.
val proprietesCle = Properties()
val fichierCle = rootProject.file("key.properties")
if (fichierCle.exists()) {
    fichierCle.inputStream().use { proprietesCle.load(it) }
}

android {
    namespace = "tg.nexus.arziki"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "tg.nexus.arziki"
        // Exigences ARZIKI : Android 6 minimum, cible API 36 (Google Play depuis le 31 août 2026).
        minSdk = 23
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (fichierCle.exists()) {
            create("release") {
                keyAlias = proprietesCle["keyAlias"] as String
                keyPassword = proprietesCle["keyPassword"] as String
                storeFile = file(proprietesCle["storeFile"] as String)
                storePassword = proprietesCle["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (fichierCle.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

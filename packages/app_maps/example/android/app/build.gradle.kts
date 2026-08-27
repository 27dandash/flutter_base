import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val mapsProperties = Properties().apply {
    val source = rootProject.file("maps.properties")
    if (source.exists()) source.inputStream().use(::load)
}

fun mapsKey(flavor: String): String =
    mapsProperties.getProperty("MAPS_API_KEY_${flavor.uppercase()}")?.trim().orEmpty()

android {
    namespace = "com.flutter.newproject.maps"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    buildFeatures {
        resValues = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.flutter.newproject.maps"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["MAPS_API_KEY"] = ""
    }

    flavorDimensions += "environment"
    productFlavors {
        create("development") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "Maps Example Dev")
            manifestPlaceholders["MAPS_API_KEY"] = mapsKey("development")
        }
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
            resValue("string", "app_name", "Maps Example Staging")
            manifestPlaceholders["MAPS_API_KEY"] = mapsKey("staging")
        }
        create("production") {
            dimension = "environment"
            resValue("string", "app_name", "Maps Example")
            manifestPlaceholders["MAPS_API_KEY"] = mapsKey("production")
        }
    }

    buildTypes {
        release {
            // Consuming projects must provide release signing.
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

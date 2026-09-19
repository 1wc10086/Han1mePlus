import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.reader(Charsets.UTF_8).use { reader: java.io.Reader ->
        localProperties.load(reader)
    }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode") ?: "20"
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.1.9"

android {
    namespace = "com.liar.han1meplus"
    compileSdk = 37
    ndkVersion = "29.0.14206865"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_25
        targetCompatibility = JavaVersion.VERSION_25
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        applicationId = "com.liar.han1meplus"
        minSdk = 27
        targetSdk = 37
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

androidComponents {
    onVariants { variant ->
        if (variant.buildType != "debug") return@onVariants
        variant.packaging.jniLibs.excludes.addAll(listOf("lib/armeabi-v7a/**", "lib/x86/**", "lib/x86_64/**"))
    }
}

dependencies {
    implementation("androidx.documentfile:documentfile:1.0.1")
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:2.3.10")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("com.squareup.okhttp3:okhttp-dnsoverhttps:4.12.0")
}

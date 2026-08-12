import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val signingKeyAlias = "Matzilonkey"
var signingKeyPassword = ""
var signingKeyFile = ""
var signingKeyStorePassword = ""

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (localPropertiesFile.exists()) {
    localPropertiesFile.reader(Charsets.UTF_8).use { reader ->
        localProperties.load(reader)
    }
}

if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.reader(Charsets.UTF_8).use { reader ->
        keystoreProperties.load(reader)
    }
    signingKeyPassword = keystoreProperties["keyPassword"] as String
    signingKeyFile = keystoreProperties["storeFile"] as String
    signingKeyStorePassword = keystoreProperties["storePassword"] as String
} else {
    signingKeyPassword = System.getenv("APPSIGNINGKEYPASSWORD") ?: " "
    signingKeyFile = System.getenv("KEYSTORE_FILE") ?: " "
    signingKeyStorePassword = System.getenv("APPSIGNINGKEYSTOREPASSWORD") ?: " "
}

if (signingKeyFile.isEmpty() || signingKeyPassword.isEmpty() || signingKeyStorePassword.isEmpty()) {
    throw Exception("Keystore credentials are not properly set in either key.properties or environment variables.")
}

android {
    namespace = "com.example.mezilon"
    ndkVersion = flutter.ndkVersion
    compileSdk = 37

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
            freeCompilerArgs.addAll(listOf("-Xmetadata-version=2.0"))
        }
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.matzilon.mezilon"
        // You can update the following values to match your application needs.
        // For more information, see: https://docs.flutter.dev/deployment/android#reviewing-the-gradle-build-configuration.
        minSdk = flutter.minSdkVersion // 23 is the minimum for firebase_auth
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = signingKeyAlias
            keyPassword = signingKeyPassword
            storeFile = file(signingKeyFile)
            storePassword = signingKeyStorePassword
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }

    applicationVariants.all {
        outputs.all {
            if (this is com.android.build.gradle.internal.api.BaseVariantOutputImpl) {
                outputFileName = "LivingPositively.apk"
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.window:window:1.0.0")
    implementation("androidx.window:window-java:1.0.0")
}

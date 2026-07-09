allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Provide kotlin_version extra property for legacy Groovy scripts/plugins
extra.set("kotlin_version", "1.8.22")

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Force compileSdk for Android library/application subprojects to satisfy
// AAR metadata checks from newer AndroidX artifacts.
subprojects {
    plugins.withId("com.android.library") {
        extensions.findByName("android")?.let { androidExt ->
            (androidExt as? com.android.build.gradle.BaseExtension)?.compileSdkVersion(36)
        }
    }
    plugins.withId("com.android.application") {
        extensions.findByName("android")?.let { androidExt ->
            (androidExt as? com.android.build.gradle.BaseExtension)?.compileSdkVersion(36)
        }
    }
}


tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

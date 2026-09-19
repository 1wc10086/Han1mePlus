buildscript {
    extra.set("kotlin_version", "2.3.10")
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.13.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.3.10")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

allprojects {
    layout.buildDirectory.set(rootDir.resolve("../build/${project.name}"))
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register("clean", Delete::class) {
    delete(rootProject.layout.buildDirectory)
}
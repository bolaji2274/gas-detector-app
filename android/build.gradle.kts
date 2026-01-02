buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0")
        classpath("com.google.gms:google-services:4.4.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = file("../build")

subprojects {
    project.buildDir = file("${rootProject.buildDir}/${project.name}")
}

subprojects {
    project.evaluationDependsOn(":app")
}

// --- FIX START: Safely Inject Namespace AND JVM Target for qr_code_scanner ---
subprojects {
    if (project.name == "qr_code_scanner") {
        
        val fixPlugin = {
            // 1. Fix the Namespace issue
            val android = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
            if (android != null && android.namespace == null) {
                android.namespace = "net.touchcapture.qr.flutterqr"
                println("✅ Fixed namespace for qr_code_scanner") 
            }

            // 2. Fix the Inconsistent JVM Target issue
            project.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                kotlinOptions {
                    jvmTarget = "1.8"
                }
            }
        }

        if (project.state.executed) {
            fixPlugin()
        } else {
            project.afterEvaluate {
                fixPlugin()
            }
        }
    }
}
// --- FIX END ---

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

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

subprojects {
    // Skip :app — it already declares its namespace explicitly.
    // This auto-assigns namespaces to older plugins that lack one (e.g. image_gallery_saver).
    if (project.name != "app") {
        afterEvaluate {
            val androidExtension = extensions.findByName("android")
            if (androidExtension is com.android.build.gradle.BaseExtension) {
                if (androidExtension.namespace.isNullOrEmpty()) {
                    androidExtension.namespace = project.group.toString().ifEmpty {
                        "com.example.${project.name.replace("-", "_").replace(".", "_")}"
                    }
                }
            }

            // Fix JVM target mismatch between Java and Kotlin tasks
            val androidExtension2 = extensions.findByName("android")
            if (androidExtension2 is com.android.build.gradle.BaseExtension) {
                androidExtension2.compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }
            project.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                compilerOptions {
                    jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}


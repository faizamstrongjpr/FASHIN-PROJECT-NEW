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
    val project = this
    val configureNamespace = {
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            if (android.namespace == null) {
                // Determine a fallback namespace based on the project name or old package attribute
                val manifestFile = project.file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val xml = manifestFile.readText()
                    val packageMatch = Regex("package=\"([^\"]+)\"").find(xml)
                    if (packageMatch != null) {
                        android.namespace = packageMatch.groupValues[1]
                        println("Fixed missing namespace for ${project.name} using manifest: ${android.namespace}")
                    } else {
                        android.namespace = "com.fixed.namespace.${project.name.replace("-", "_")}"
                        println("Fixed missing namespace for ${project.name} using fallback: ${android.namespace}")
                    }
                } else {
                    android.namespace = "com.fixed.namespace.${project.name.replace("-", "_")}"
                    println("Fixed missing namespace for ${project.name} using fallback: ${android.namespace}")
                }
            }
        }
    }

    if (project.state.executed) {
        configureNamespace()
    } else {
        project.afterEvaluate {
            configureNamespace()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

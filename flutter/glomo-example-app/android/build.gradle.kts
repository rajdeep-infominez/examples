allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.library") || project.plugins.hasPlugin("com.android.application")) {
            val android = project.extensions.findByName("android")
            if (android != null) {
                try {
                    val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)

                    // Specific overrides for plugins with deprecated package attribute in AndroidManifest.xml
                    val namespaceOverrides = mapOf(
                        "flutter_jailbreak_detection" to "com.example.flutter_jailbreak_detection"
                    )

                    val override = namespaceOverrides[project.name]
                    if (override != null) {
                        println("Overriding namespace for ${project.name} to $override")
                        setNamespace.invoke(android, override)
                    } else {
                        val getNamespace = android.javaClass.getMethod("getNamespace")
                        val currentNamespace = getNamespace.invoke(android)
                        if (currentNamespace == null) {
                            val packageName = "com.example.${project.name.replace("-", "_")}"
                            println("Setting namespace for ${project.name} to $packageName")
                            setNamespace.invoke(android, packageName)
                        }
                    }
                } catch (e: Exception) {
                    println("Failed to set namespace for ${project.name}: $e")
                }
            }
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

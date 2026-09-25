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
    fun bumpCompileSdk() {
        extensions.findByType(com.android.build.api.dsl.CommonExtension::class.java)?.let { ext ->
            if ((ext.compileSdk ?: 0) < 36) {
                try {
                    ext.compileSdk = 36
                } catch (e: Exception) {
                    logger.warn("tripgo: could not raise compileSdk for ${name}: ${e.message}")
                }
            }
        }
    }
    plugins.withId("com.android.library") {
        if (state.executed) bumpCompileSdk() else afterEvaluate { bumpCompileSdk() }
    }
    plugins.withId("com.android.application") {
        if (state.executed) bumpCompileSdk() else afterEvaluate { bumpCompileSdk() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

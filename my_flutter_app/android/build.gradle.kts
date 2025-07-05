allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Set custom build directory for root project
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

// Set custom build directory for each subproject
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Ensure :app is evaluated before other subprojects
    if (rootProject.findProject(":app") != null && project.path != ":app") {
        evaluationDependsOn(":app")
    }
}

// Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

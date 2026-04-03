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

// Fix nobodywho's resolveNativeLibraries task on Windows:
// Gradle's project.exec with commandLine("dart", ...) fails because Windows'
// CreateProcess API doesn't resolve .bat extensions. Override the task to use
// the full "dart.bat" path from local.properties flutter.sdk.
gradle.projectsEvaluated {
    val nobodywhoProject = rootProject.subprojects.find { it.name == "nobodywho" }
    nobodywhoProject?.tasks?.matching { it.name == "resolveNativeLibraries" }?.configureEach {
        actions.clear()
        doLast {
            val localProps = java.util.Properties()
            rootProject.file("local.properties").inputStream().use { localProps.load(it) }
            val flutterSdk = localProps.getProperty("flutter.sdk")
                ?: throw GradleException("flutter.sdk not found in local.properties")
            val isWindows = org.gradle.internal.os.OperatingSystem.current().isWindows
            val dartExe = if (isWindows) "$flutterSdk\\bin\\dart.bat" else "$flutterSdk/bin/dart"

            val toolDir = file("${nobodywhoProject.projectDir}/../tool")
            val workingDir = file("${nobodywhoProject.projectDir}/..")
            val jniLibsDir = nobodywhoProject.layout.buildDirectory.dir("jniLibs").get()
            val cacheDir = nobodywhoProject.layout.buildDirectory.dir("nobodywho-cache").get()

            listOf("arm64-v8a", "x86_64").forEach { abi ->
                val abiOutputDir = jniLibsDir.dir(abi).asFile
                abiOutputDir.mkdirs()

                val stdout = java.io.ByteArrayOutputStream()
                val stderr = java.io.ByteArrayOutputStream()

                val result = nobodywhoProject.exec {
                    commandLine(
                        dartExe, "run", "${toolDir}/resolve_binary.dart",
                        "--platform=android",
                        "--arch=$abi",
                        "--build-type=release",
                        "--cache-dir=${cacheDir.asFile.absolutePath}"
                    )
                    setWorkingDir(workingDir)
                    standardOutput = stdout
                    errorOutput = stderr
                    isIgnoreExitValue = true
                }

                val stderrText = stderr.toString().trim()
                if (stderrText.isNotEmpty()) {
                    logger.lifecycle("[$abi] $stderrText")
                }
                if (result.exitValue != 0) {
                    throw GradleException("Failed to resolve NobodyWho library for $abi:\n$stderrText")
                }

                val resolvedLibPath = stdout.toString().trim()
                logger.lifecycle("[$abi] Resolved library: $resolvedLibPath")

                copy {
                    from(resolvedLibPath)
                    into(abiOutputDir)
                    rename { "libnobodywho_flutter.so" }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

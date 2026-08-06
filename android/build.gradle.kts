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
// Alza il compileSdk dei plugin che ne dichiarano uno inferiore a 31.
//
// Perche serve: isar_flutter_libs 3.1.0+1 dichiara `compileSdkVersion 30`, ma
// le dipendenze AndroidX tirate dentro dagli altri plugin referenziano
// android:attr/lStar, introdotto con API 31. Il task
// :isar_flutter_libs:verifyReleaseResources non lo risolve e la build release
// fallisce con "resource android:attr/lStar not found". In debug quel task non
// viene eseguito, quindi il problema si vede solo in release (US-040).
//
// Alzare il compileSdk NON cambia il comportamento a runtime: minSdk resta
// quello dichiarato dal plugin, e con esso la compatibilita con i dispositivi
// piu vecchi. Cambia solo la piattaforma con cui il codice viene compilato.
//
// Il blocco e condizionale: tocca solo i moduli sotto la soglia. Se un
// aggiornamento futuro di Isar alzasse il proprio compileSdk, diventerebbe
// inerte da solo. Puo essere rimosso quando nessun plugin dichiara piu meno
// di 31 - oggi l'unico e isar_flutter_libs.
subprojects {
    afterEvaluate {
        val android = extensions.findByName("android") ?: return@afterEvaluate
        if (android !is com.android.build.gradle.BaseExtension) return@afterEvaluate

        val current = android.compileSdkVersion
            ?.removePrefix("android-")
            ?.toIntOrNull()

        if (current != null && current < 31) {
            logger.lifecycle(
                "US-040: compileSdk di ${project.name} alzato da $current a 34"
            )
            android.compileSdkVersion(34)
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

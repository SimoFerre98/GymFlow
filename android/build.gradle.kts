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

// Imposta il `namespace` per i plugin che non lo dichiarano nel proprio
// build.gradle (lo davano per scontato dal `package` dell'AndroidManifest,
// come si usava prima di Android Gradle Plugin 8): senza, AGP 8+ rifiuta di
// configurare il modulo con "Namespace not specified" — trovato su
// isar_flutter_libs 3.1.0+1 con AGP 8.11.1, ma il blocco resta generico e non
// nominato a quel plugin solo, per lo stesso motivo del blocco sul compileSdk
// sopra: si applica a chiunque abbia lo stesso problema, oggi o in futuro, e
// diventa inerte da solo se un aggiornamento del plugin aggiunge il suo.
subprojects {
    afterEvaluate {
        val android = extensions.findByName("android") ?: return@afterEvaluate
        if (android !is com.android.build.gradle.BaseExtension) return@afterEvaluate
        if (android.namespace != null) return@afterEvaluate

        val manifest = android.sourceSets.getByName("main").manifest.srcFile
        if (!manifest.exists()) return@afterEvaluate
        val pacchetto = Regex("package=\"([^\"]+)\"")
            .find(manifest.readText())
            ?.groupValues
            ?.get(1)
            ?: return@afterEvaluate

        logger.lifecycle(
            "namespace mancante: ${project.name} lo eredita da AndroidManifest.xml ($pacchetto)"
        )
        android.namespace = pacchetto
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

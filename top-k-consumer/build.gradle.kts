plugins {
    alias(libs.plugins.kotlin.jvm)
    alias(libs.plugins.jib)
    alias(libs.plugins.shadow)
    application
}

group = "org.example"
version = "1.0-SNAPSHOT"

repositories {
    mavenCentral()
}

dependencies {
    implementation(libs.hoplite.core)
    implementation(libs.hoplite.yaml)
    implementation(libs.ktor.client.core)
    implementation(libs.ktor.client.okhttp)
    implementation(libs.ktor.server.core)
    implementation(libs.ktor.server.netty)
    implementation(libs.logback.classic)
    implementation(libs.flink.streaming.java)
    implementation(libs.flink.clients)
    testImplementation(kotlin("test"))
}

tasks.test {
    useJUnitPlatform()
}
kotlin {
    jvmToolchain(21)
}

tasks.build.get().dependsOn(tasks.jib)

application {
    mainClass = "org.example.MainKt"
}

jib {
    to {
        image = "${project.findProperty("dockerRepository")}:app-service-1_0.0.4"
        auth {
            username = project.findProperty("dockerUsername") as String
            password = project.findProperty("dockerPassword") as String
        }
    }
}

tasks.shadowJar {
    archiveBaseName.set("flink-job")
    archiveVersion.set("1.0-SNAPSHOT")
    archiveClassifier.set("") // No classifier, produce a clean JAR name
    mergeServiceFiles() // Merge META-INF/services files
    manifest {
        attributes["Main-Class"] = "org.example.MainKt"
    }
    configurations = listOf(project.configurations.runtimeClasspath.get())
}
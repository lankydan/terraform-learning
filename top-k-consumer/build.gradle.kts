import com.bmuschko.gradle.docker.tasks.image.DockerBuildImage
import com.bmuschko.gradle.docker.tasks.image.DockerPushImage

plugins {
    alias(libs.plugins.kotlin.jvm)
    alias(libs.plugins.shadow)
    alias(libs.plugins.bmuschko.docker)
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
    implementation(libs.jackson.module.kotlin)
    implementation(libs.logback.classic)
    implementation(libs.flink.streaming.java)
    implementation(libs.flink.clients)
    implementation(libs.flink.connector.nats)
    implementation(libs.nats.java)
    implementation(libs.hikaricp)
    implementation(libs.kapper)
    runtimeOnly(libs.postgres.driver)
    testImplementation(kotlin("test"))
}

tasks.test {
    useJUnitPlatform()
}
kotlin {
    jvmToolchain(17)
}

application {
    mainClass = "org.example.MainKt"
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
    // Relocates the driver so that the flink job/task managers can find the driver.
    relocate("org.postgresql", "org.example.shaded.postgresql")
}

val dockerRepo = project.findProperty("dockerRepository") as String? ?: "lankydan/learning"
val imageName = "$dockerRepo:top-k-consumer-flink_${project.version}"

tasks.create<DockerBuildImage>("dockerBuildImage") {
    dependsOn(tasks.shadowJar)
    inputDir.set(project.projectDir)
    images.add(imageName)
}

tasks.create<DockerPushImage>("dockerPushImage") {
    dependsOn(tasks.named("dockerBuildImage"))
    images.add(imageName)
    registryCredentials {
        username.set(project.findProperty("dockerUsername") as String? ?: "")
        password.set(project.findProperty("dockerPassword") as String? ?: "")
        email.set("noreply@example.com") // Required but not used for modern Docker registries
        url.set("docker.io") // Explicitly set Docker Hub URL for credentials
    }
}

tasks.register("buildAndPushFlinkImage") {
    dependsOn(tasks.named("dockerPushImage"))
    group = "docker"
    description = "Builds and pushes the Flink Docker image."
}

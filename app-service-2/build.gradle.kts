plugins {
    alias(libs.plugins.kotlin.jvm)
    alias(libs.plugins.jib)
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
    implementation(libs.ktor.server.core)
    implementation(libs.ktor.server.netty)
    implementation(libs.logback.classic)
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
        image = "${project.findProperty("dockerRepository")}:app-service-2_0.0.3"
        auth {
            username = project.findProperty("dockerUsername") as String
            password = project.findProperty("dockerPassword") as String
        }
    }
}
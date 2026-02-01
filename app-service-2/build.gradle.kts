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
    implementation(libs.hikaricp)
    implementation(libs.hoplite.core)
    implementation(libs.hoplite.yaml)
    implementation(libs.kapper)
    implementation(platform(libs.koin.bom))
    implementation(libs.koin.core)
    implementation(libs.ktor.server.core)
    implementation(libs.ktor.server.netty)
    implementation(libs.logback.classic)
    runtimeOnly(libs.postgres.driver)
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
        image = "${project.findProperty("dockerRepository")}:app-service-2_0.0.4"
        auth {
            username = project.findProperty("dockerUsername") as String
            password = project.findProperty("dockerPassword") as String
        }
    }
}
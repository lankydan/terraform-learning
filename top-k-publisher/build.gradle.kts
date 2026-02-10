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
    implementation(libs.nats.java)
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
//    from {
//        image = "openjdk:21-jre-slim"
//    }
    to {
//        image = "${project.findProperty("dockerRepository")}:top-k-publisher:${project.version}"
        image = "${project.findProperty("dockerRepository")}:top-k-publisher_${project.version}"
        auth {
            username = project.findProperty("dockerUsername") as String
            password = project.findProperty("dockerPassword") as String
        }
    }
//    container {
////        mainClass = "org.example.MainKt"
////        jvmFlags = listOf("-Xms512m", "-Xmx512m")
//        ports = listOf("8080/tcp")
//        args = listOf("/app/config.yaml")
//    }
}


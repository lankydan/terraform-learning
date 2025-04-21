plugins {
    id("org.gradle.toolchains.foojay-resolver-convention") version "0.8.0"
}
rootProject.name = "terraform-learning"

include(
    "app-service-1",
    "app-service-2"
)
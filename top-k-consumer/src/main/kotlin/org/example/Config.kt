package org.example

import com.sksamuel.hoplite.ConfigLoaderBuilder
import com.sksamuel.hoplite.PropertySource
import java.io.File

data class Config(
    val nats: NatsConfig = NatsConfig(),
    val persistence: PersistenceConfig = PersistenceConfig()
)

data class NatsConfig(
    val url: String = "nats://localhost:4222",
    val subject: String = "song.events"
)

data class PersistenceConfig(
    val intervalSeconds: Long = 2
)

fun loadConfig(path: String = "config.yaml"): Config {
    return ConfigLoaderBuilder.default()
        .addSource(PropertySource.file(File(path), optional = true))
        .build()
        .loadConfigOrThrow()
}
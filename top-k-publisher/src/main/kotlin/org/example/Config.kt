package org.example

import com.sksamuel.hoplite.ConfigLoaderBuilder
import com.sksamuel.hoplite.PropertySource
import java.io.File

data class Config(val nats: NatsConfig)

data class NatsConfig(
    val url: String,
    val subject: String
)

fun loadConfig(path: String): Config {
    return ConfigLoaderBuilder.default()
        .addSource(PropertySource.file(File(path), optional = false))
        .build()
        .loadConfigOrThrow()
}

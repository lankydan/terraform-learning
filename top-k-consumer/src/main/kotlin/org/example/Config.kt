package org.example

import com.sksamuel.hoplite.ConfigLoaderBuilder
import com.sksamuel.hoplite.PropertySource
import java.io.File
import java.io.Serializable

data class Config(
    val intervalSeconds: Long,
    val nats: NatsConfig,
    val database: DatabaseConfig
)

data class NatsConfig(
    val url: String,
    val subject: String
)

data class DatabaseConfig(val jdbcUrl: String, val schema: String, val username: String, val password: String) :
    Serializable

fun loadConfig(path: String = "/opt/flink/conf/app-config.yaml"): Config {
    return ConfigLoaderBuilder.default()
        .addSource(PropertySource.file(File(path), optional = false))
        .build()
        .loadConfigOrThrow()
}
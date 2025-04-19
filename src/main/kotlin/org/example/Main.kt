package org.example

import com.sksamuel.hoplite.ConfigLoaderBuilder
import com.sksamuel.hoplite.addFileSource
import io.ktor.server.engine.embeddedServer
import io.ktor.server.netty.Netty
import io.ktor.server.response.respondText
import io.ktor.server.routing.get
import io.ktor.server.routing.routing
import org.slf4j.LoggerFactory

private val logger = LoggerFactory.getLogger("Main")

fun main(args: Array<String>) {
    logger.info("Application starting")
    val config = ConfigLoaderBuilder.default().addFileSource(args.first()).build().loadConfigOrThrow<Config>()
    embeddedServer(Netty, port = config.port) {
        routing {
            get("/") {
                logger.info("Received request")
                call.respondText("Received request")
            }
        }
    }.start(wait = true)
}
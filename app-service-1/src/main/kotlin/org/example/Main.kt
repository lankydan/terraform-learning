package org.example

import com.sksamuel.hoplite.ConfigLoaderBuilder
import com.sksamuel.hoplite.addFileSource
import io.ktor.client.HttpClient
import io.ktor.client.engine.okhttp.OkHttp
import io.ktor.client.request.get
import io.ktor.client.request.post
import io.ktor.client.statement.bodyAsText
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
    val client = HttpClient(OkHttp)
    embeddedServer(Netty, port = config.port) {
        routing {
            get("/{id}") {
                logger.info("Received request")
                call.respondText(
                    client.post("http://${config.appService2Url}/${call.pathParameters["id"]}").bodyAsText()
                )
            }
        }
    }.start(wait = true)
}
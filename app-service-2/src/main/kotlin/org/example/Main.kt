package org.example

import com.sksamuel.hoplite.ConfigLoaderBuilder
import com.sksamuel.hoplite.addFileSource
import io.ktor.server.engine.embeddedServer
import io.ktor.server.netty.Netty
import io.ktor.server.response.respondText
import io.ktor.server.routing.get
import io.ktor.server.routing.post
import io.ktor.server.routing.routing
import org.example.module.applicationModule
import org.example.order.repository.OrderRepository
import org.koin.core.context.startKoin
import org.slf4j.LoggerFactory

private val logger = LoggerFactory.getLogger("Main")

fun main(args: Array<String>) {
    logger.info("Application starting")
    val config = ConfigLoaderBuilder.default().addFileSource(args.first()).build().loadConfigOrThrow<Config>()
    startKoin {
        modules(applicationModule(config))
        val orderRepository = koin.get<OrderRepository>()
        embeddedServer(Netty, port = config.port) {
            routing {
                get("/") {
                    logger.info("Received request")
                    call.respondText("Received request")
                }
                post("/{id}") {
                    when (val id = call.pathParameters["id"]) {
                        null -> logger.warn("Order [failed]: Unknown id")
                        else -> {
                            logger.info("Order [start]: $id")
                            orderRepository.insert(id)
                            logger.info("Order [success]: $id")
                        }
                    }
                }
            }
        }.start(wait = true)
    }
}
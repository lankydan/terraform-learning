package org.example

import io.nats.client.Nats
import java.util.concurrent.TimeUnit
import kotlin.random.Random

data class SongEvent(val songId: String, val eventType: EventType, val timestamp: Long)
enum class EventType { START, STOP }

fun main(args: Array<String>) {
    val config = loadConfig(args.first())
    val nc = Nats.connect(config.nats.url)

    val songIds = (1..5).map { "song-$it" }
    val random = Random(System.currentTimeMillis())

    while (true) {
        val songId = songIds[random.nextInt(songIds.size)]
        val eventType = if (random.nextBoolean()) EventType.START else EventType.STOP
        val event = SongEvent(songId, eventType, System.currentTimeMillis())
        val eventJson = """{"songId":"${event.songId}","eventType":"${event.eventType}","timestamp":${event.timestamp}}"""
        nc.publish(config.nats.subject, eventJson.toByteArray())
        println("Published: $eventJson")
        TimeUnit.MILLISECONDS.sleep(random.nextLong(100, 500))
    }
}

package org.example

import io.synadia.flink.source.NatsSource
import io.synadia.flink.source.NatsSourceBuilder
import org.apache.flink.api.common.eventtime.WatermarkStrategy
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment
import org.example.converters.SongEventSourceConverter
import org.example.events.SongEvent
import org.example.functions.SongActivityPersistProcessFunction
import org.example.functions.SongActivityProcessFunction
import java.util.Properties

fun main() {
    val config = loadConfig()
    val env = StreamExecutionEnvironment.getExecutionEnvironment()

    val natsSource: NatsSource<SongEvent> = NatsSourceBuilder<SongEvent>()
        .subjects(config.nats.subject)
        .connectionProperties(Properties().apply {
            setProperty("url", config.nats.url)
        })
        .sourceConverter(SongEventSourceConverter())
        .build()

    val songEvents = env.fromSource(
        natsSource,
        WatermarkStrategy.forMonotonousTimestamps(), "Nats Source"
    )

    songEvents
        .keyBy { it.songId }
        .process(SongActivityProcessFunction(config.intervalSeconds))
        .process(SongActivityPersistProcessFunction(config.database))

    env.execute("Song Activity Flink Job")
}


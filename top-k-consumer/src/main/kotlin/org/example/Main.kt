package org.example

import io.synadia.flink.source.NatsSource
import io.synadia.flink.source.NatsSourceBuilder
import org.apache.flink.api.common.eventtime.WatermarkStrategy
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment
import org.apache.flink.streaming.api.functions.sink.v2.DiscardingSink
import org.apache.flink.streaming.api.windowing.assigners.TumblingEventTimeWindows
import org.example.converters.SongEventSourceConverter
import org.example.events.SongEvent
import org.example.functions.SongActivityAggregateFunction
import org.example.functions.SongActivityPersistProcessFunction
import org.example.functions.SongActivityPersistWindowedProcessFunction
import org.example.functions.SongActivityProcessFunction
import java.time.Duration
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
        .sinkTo(DiscardingSink())

    songEvents
        .assignTimestampsAndWatermarks(
            WatermarkStrategy.forBoundedOutOfOrderness<SongEvent>(Duration.ofSeconds(2))
                .withTimestampAssigner { event, _ -> event.timestamp }
                .withIdleness(Duration.ofSeconds(5))
        )
        .keyBy { it.songId }
        .window(TumblingEventTimeWindows.of(Duration.ofSeconds(config.intervalSeconds)))
        .aggregate(SongActivityAggregateFunction(), SongActivityPersistWindowedProcessFunction(config.database))
        .sinkTo(DiscardingSink())

    env.execute("Song Activity Flink Job")
}


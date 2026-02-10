package org.example

import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.fasterxml.jackson.module.kotlin.readValue
import io.nats.client.Message
import io.synadia.flink.message.SourceConverter
import io.synadia.flink.source.NatsSource
import io.synadia.flink.source.NatsSourceBuilder
import org.apache.flink.api.common.eventtime.WatermarkStrategy
import org.apache.flink.api.common.functions.OpenContext
import org.apache.flink.api.common.state.ValueState
import org.apache.flink.api.common.state.ValueStateDescriptor
import org.apache.flink.api.common.typeinfo.TypeInformation
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment
import org.apache.flink.streaming.api.functions.KeyedProcessFunction
import org.apache.flink.streaming.api.functions.ProcessFunction
import org.apache.flink.util.Collector
import org.slf4j.LoggerFactory
import java.io.ObjectInputStream
import java.io.Serial
import java.util.Properties
import java.util.concurrent.TimeUnit

// Data classes for song events and song totals
data class SongEvent(val songId: String, val eventType: EventType)
enum class EventType { START, STOP }
data class SongTotal(val songId: String, val activeCount: Int)

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

    val songEvents = env.fromSource(natsSource, WatermarkStrategy.forMonotonousTimestamps(), "Nats Source")

    songEvents
        .keyBy { it.songId }
        .process(SongActivityProcessFunction(config.persistence.intervalSeconds))
        .process(SongActivityPersistProcessFunction(config.persistence.intervalSeconds))

    env.execute("Song Activity Flink Job")
}

class SongEventSourceConverter : SourceConverter<SongEvent> {

    @Transient
    private var objectMapper = jacksonObjectMapper()

    override fun convert(message: Message): SongEvent {
        return objectMapper.readValue<SongEvent>(message.data)
    }

    override fun getProducedType(): TypeInformation<SongEvent> {
        return TypeInformation.of(SongEvent::class.java)
    }

    @Serial
    private fun readObject(ois: ObjectInputStream) {
        ois.defaultReadObject()
        objectMapper = jacksonObjectMapper()
    }
}

class SongActivityProcessFunction(private val intervalSeconds: Long) :
    KeyedProcessFunction<String, SongEvent, SongTotal>() {

    private lateinit var activeSongCountState: ValueState<Int>
    private lateinit var lastTimerTimestampState: ValueState<Long>

    override fun open(context: OpenContext) {
        val countDescriptor = ValueStateDescriptor(
            "active-song-count",
            Int::class.javaObjectType
        )
        val timerDescriptor = ValueStateDescriptor(
            "last-timer-timestamp",
            Long::class.javaObjectType
        )
        activeSongCountState = runtimeContext.getState(countDescriptor)
        lastTimerTimestampState = runtimeContext.getState(timerDescriptor)
    }

    override fun processElement(
        value: SongEvent,
        ctx: KeyedProcessFunction<String, SongEvent, SongTotal>.Context,
        out: Collector<SongTotal>
    ) {
        var currentCount = activeSongCountState.value() ?: 0

        logger.debug("Song total {} => {}", ctx.currentKey, currentCount)

        when (value.eventType) {
            EventType.START -> currentCount++
            EventType.STOP -> currentCount--
        }

        activeSongCountState.update(currentCount)

        // Set a timer to emit the current total periodically
        val isTimerUnset = lastTimerTimestampState.value()?.let { it == 0L } ?: true
        if (isTimerUnset) {
            // No timer set yet, register the first one
            val currentTimestamp = ctx.timerService().currentProcessingTime()
            val nextTimer = currentTimestamp + TimeUnit.SECONDS.toMillis(intervalSeconds)
            ctx.timerService().registerProcessingTimeTimer(nextTimer)
            lastTimerTimestampState.update(nextTimer)
        }
    }

    override fun onTimer(
        timestamp: Long,
        ctx: KeyedProcessFunction<String, SongEvent, SongTotal>.OnTimerContext,
        out: Collector<SongTotal>
    ) {
        // Timer fired, emit the current active count
        val songId = ctx.currentKey
        val currentCount = activeSongCountState.value()
        out.collect(SongTotal(songId, currentCount))
        // Register the next timer
        val nextTimer = timestamp + TimeUnit.SECONDS.toMillis(intervalSeconds)
        ctx.timerService().registerProcessingTimeTimer(nextTimer)
        lastTimerTimestampState.update(nextTimer)
    }

    private companion object {

        // Lazy seemed to remove the serialization issue, but documentation suggests it shouldn't be needed...
        @JvmStatic
        val logger by lazy { LoggerFactory.getLogger(SongActivityProcessFunction::class.java)!! }
    }
}

class SongActivityPersistProcessFunction(private val intervalSeconds: Long) :
    ProcessFunction<SongTotal, Unit>() {

    override fun processElement(
        value: SongTotal,
        ctx: ProcessFunction<SongTotal, Unit>.Context,
        out: Collector<Unit>
    ) {
        logger.info("Persisting song total {} => {}", value.songId, value.activeCount)
    }

    private companion object {

        // Lazy seemed to remove the serialization issue, but documentation suggests it shouldn't be needed...
        @JvmStatic
        val logger by lazy { LoggerFactory.getLogger(SongActivityPersistProcessFunction::class.java)!! }
    }
}

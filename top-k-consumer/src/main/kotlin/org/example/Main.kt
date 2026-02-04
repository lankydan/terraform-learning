package org.example

import org.apache.flink.streaming.api.functions.KeyedProcessFunction
import org.apache.flink.util.Collector

import org.apache.flink.api.common.eventtime.WatermarkStrategy
import org.apache.flink.api.common.state.ValueState
import org.apache.flink.api.common.state.ValueStateDescriptor
import org.apache.flink.configuration.Configuration
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment
import org.apache.flink.streaming.api.functions.source.SourceFunction
import java.util.concurrent.TimeUnit
import kotlin.random.Random

// Data classes for song events and song totals
data class SongEvent(val songId: String, val eventType: EventType)
enum class EventType { START, STOP }
data class SongTotal(val songId: String, val activeCount: Int)

fun main() {
    val config = loadConfig()
    val env = StreamExecutionEnvironment.getExecutionEnvironment()
    env.parallelism = 1 // For easier observation of results

    // For simplicity, using a custom source that generates random song events
    // In a real scenario, this would be a NATS source
    val songEvents = env.addSource(SongEventSource())
        .assignTimestampsAndWatermarks(WatermarkStrategy.forMonotonousTimestamps())

    songEvents
        .keyBy { it.songId }
        .process(SongActivityProcessFunction(config.persistence.intervalSeconds))
        .print() // For now, just print the results to console

    env.execute("Song Activity Flink Job")
}

// Custom Source Function to simulate NATS events
class SongEventSource : SourceFunction<SongEvent> {
    @Volatile private var isRunning = true
    private val songIds = (1..5).map { "song-$it" }
    private val random = Random(System.currentTimeMillis())

    override fun run(ctx: SourceFunction.SourceContext<SongEvent>) {
        while (isRunning) {
            val songId = songIds[random.nextInt(songIds.size)]
            val eventType = if (random.nextBoolean()) EventType.START else EventType.STOP
            ctx.collect(SongEvent(songId, eventType))
            TimeUnit.MILLISECONDS.sleep(random.nextLong(100, 500)) // Simulate event arrival
        }
    }

    override fun cancel() {
        isRunning = false
    }
}

class SongActivityProcessFunction(private val intervalSeconds: Long) :
    KeyedProcessFunction<String, SongEvent, SongTotal>() {

    private lateinit var activeSongCountState: ValueState<Int>
    private lateinit var lastTimerTimestampState: ValueState<Long>

    override fun open(parameters: Configuration) {
        val countDescriptor = ValueStateDescriptor(
            "active-song-count",
            Int::class.javaObjectType,
            0
        )
        activeSongCountState = runtimeContext.getState(countDescriptor)

        val timerDescriptor = ValueStateDescriptor(
            "last-timer-timestamp",
            Long::class.javaObjectType,
            0L
        )
        lastTimerTimestampState = runtimeContext.getState(timerDescriptor)
    }

    override fun processElement(
        value: SongEvent,
        ctx: KeyedProcessFunction<String, SongEvent, SongTotal>.Context,
        out: Collector<SongTotal>
    ) {
        var currentCount = activeSongCountState.value()
        when (value.eventType) {
            EventType.START -> currentCount++
            EventType.STOP -> currentCount--
        }
        activeSongCountState.update(currentCount)

        // Set a timer to emit the current total periodically
        if (lastTimerTimestampState.value() == 0L) {
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
        val songId = ctx.getCurrentKey()
        val currentCount = activeSongCountState.value()
        out.collect(SongTotal(songId, currentCount))

        // Register the next timer
        val nextTimer = timestamp + TimeUnit.SECONDS.toMillis(intervalSeconds)
        ctx.timerService().registerProcessingTimeTimer(nextTimer)
        lastTimerTimestampState.update(nextTimer)
    }
}

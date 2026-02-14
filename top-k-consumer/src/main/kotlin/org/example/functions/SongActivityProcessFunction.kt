package org.example.functions

import org.apache.flink.api.common.functions.OpenContext
import org.apache.flink.api.common.state.ValueState
import org.apache.flink.api.common.state.ValueStateDescriptor
import org.apache.flink.streaming.api.functions.KeyedProcessFunction
import org.apache.flink.util.Collector
import org.example.events.SongEvent.EventType
import org.example.events.SongEvent
import org.example.events.SongTotal
import org.slf4j.LoggerFactory
import java.util.concurrent.TimeUnit

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
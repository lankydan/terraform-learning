package org.example.functions

import org.apache.flink.api.common.accumulators.Accumulator
import org.example.events.SongEvent

class SongActivityAccumulator : Accumulator<SongEvent, Long> {

    private var total = 0L

    override fun add(value: SongEvent) {
        when (value.eventType) {
            SongEvent.EventType.START -> total++
            SongEvent.EventType.STOP -> total--
        }
    }

    override fun getLocalValue(): Long {
        return total
    }

    override fun resetLocal() {
        total = 0L
    }

    override fun merge(other: Accumulator<SongEvent, Long>) {
        this.total += other.localValue
    }

    override fun clone(): Accumulator<SongEvent, Long> {
        return SongActivityAccumulator().also { merge(this) }
    }
}
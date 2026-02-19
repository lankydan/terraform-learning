package org.example.functions

import org.apache.flink.api.common.functions.AggregateFunction
import org.example.events.SongEvent

class SongActivityAggregateFunction : AggregateFunction<SongEvent, SongActivityAccumulator, Long> {
    override fun createAccumulator(): SongActivityAccumulator {
        return SongActivityAccumulator()
    }


    override fun merge(a: SongActivityAccumulator, b: SongActivityAccumulator): SongActivityAccumulator {
        a.merge(b)
        return a
    }

    override fun add(value: SongEvent, acc: SongActivityAccumulator): SongActivityAccumulator {
        acc.add(value)
        return acc
    }

    override fun getResult(acc: SongActivityAccumulator): Long {
        return acc.localValue
    }
}
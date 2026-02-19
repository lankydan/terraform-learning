package org.example.functions

import net.samyn.kapper.execute
import org.apache.flink.api.common.functions.OpenContext
import org.apache.flink.streaming.api.functions.windowing.ProcessWindowFunction
import org.apache.flink.streaming.api.windowing.windows.TimeWindow
import org.apache.flink.util.Collector
import org.example.DatabaseConfig
import org.example.datasource.ApplicationDataSource
import org.example.datasource.getApplicationDataSource
import org.slf4j.LoggerFactory

class SongActivityPersistWindowedProcessFunction(
    private val databaseConfig: DatabaseConfig
) : ProcessWindowFunction<Long, Unit, String, TimeWindow>() {

    @Transient
    private lateinit var applicationDataSource: ApplicationDataSource

    override fun open(context: OpenContext) {
        applicationDataSource = getApplicationDataSource(databaseConfig)
    }

    override fun process(
        key: String?,
        ctx: ProcessWindowFunction<Long, Unit, String, TimeWindow>.Context,
        elements: Iterable<Long?>,
        out: Collector<Unit?>
    ) {
        var processed = 0
        for (count in elements) {
            require(processed == 0) { "Received multiple results into process function instead of aggregate" }
            processed++
            logger.info("Persisting song total {} => {}", key, count)

            applicationDataSource.connection.use { connection ->
                connection.execute(
                    sql = """
                    INSERT INTO song_active_count_2 (song_id, active_count) VALUES (:song_id, :active_count)
                    ON CONFLICT (song_id) DO UPDATE SET active_count = EXCLUDED.active_count
                    """.trimIndent(),
                    "song_id" to key,
                    "active_count" to count
                )
            }
        }
    }

    private companion object {

        // Lazy seemed to remove the serialization issue, but documentation suggests it shouldn't be needed...
        @JvmStatic
        val logger by lazy { LoggerFactory.getLogger(SongActivityPersistWindowedProcessFunction::class.java)!! }
    }
}
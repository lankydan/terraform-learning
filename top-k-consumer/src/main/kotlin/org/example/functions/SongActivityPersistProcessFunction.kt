package org.example.functions

import net.samyn.kapper.execute
import org.apache.flink.api.common.functions.OpenContext
import org.apache.flink.streaming.api.functions.ProcessFunction
import org.apache.flink.util.Collector
import org.example.DatabaseConfig
import org.example.events.SongTotal
import org.example.datasource.ApplicationDataSource
import org.slf4j.LoggerFactory

class SongActivityPersistProcessFunction(
    private val databaseConfig: DatabaseConfig
) : ProcessFunction<SongTotal, Unit>() {

    @Transient
    private lateinit var applicationDataSource: ApplicationDataSource

    override fun open(context: OpenContext) {
        applicationDataSource = ApplicationDataSource(databaseConfig)
    }

    override fun processElement(
        value: SongTotal,
        ctx: ProcessFunction<SongTotal, Unit>.Context,
        out: Collector<Unit>
    ) {
        logger.info("Persisting song total {} => {}", value.songId, value.activeCount)

        applicationDataSource.connection.use { connection ->
            connection.execute(
                sql = """
                    INSERT INTO song_active_count (song_id, active_count) VALUES (:song_id, :active_count)
                    ON CONFLICT (song_id) DO UPDATE SET active_count = EXCLUDED.active_count
                    """.trimIndent(),
                "song_id" to value.songId,
                "active_count" to value.activeCount
            )
        }
    }

    private companion object {

        // Lazy seemed to remove the serialization issue, but documentation suggests it shouldn't be needed...
        @JvmStatic
        val logger by lazy { LoggerFactory.getLogger(SongActivityPersistProcessFunction::class.java)!! }
    }
}
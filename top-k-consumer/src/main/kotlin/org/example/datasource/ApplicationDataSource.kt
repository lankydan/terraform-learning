package org.example.datasource

import com.zaxxer.hikari.HikariConfig
import com.zaxxer.hikari.HikariDataSource
import org.example.DatabaseConfig
import java.sql.ConnectionBuilder
import java.sql.ShardingKeyBuilder
import javax.sql.DataSource

class ApplicationDataSource(config: DatabaseConfig) : DataSource by HikariDataSource(
    HikariConfig().apply {
        // The driver has been shaded to ensure that the job/task managers can properly load and find the driver.
        driverClassName = "org.example.shaded.postgresql.Driver"
        jdbcUrl = config.jdbcUrl
        username = config.username
        password = config.password
        schema = config.schema
    }
) {
    override fun createConnectionBuilder(): ConnectionBuilder? {
        return super.createConnectionBuilder()
    }

    override fun createShardingKeyBuilder(): ShardingKeyBuilder? {
        return super.createShardingKeyBuilder()
    }

}
package org.example.datasource

import com.zaxxer.hikari.HikariConfig
import com.zaxxer.hikari.HikariDataSource
import org.example.DatabaseConfig
import javax.sql.DataSource

class ApplicationDataSource(config: DatabaseConfig) : DataSource by HikariDataSource(
    HikariConfig().apply {
        jdbcUrl = config.jdbcUrl
        username = config.username
        password = config.password
        schema = config.schema
    }
)
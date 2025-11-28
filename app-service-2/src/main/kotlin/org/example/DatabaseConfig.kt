package org.example

data class DatabaseConfig(val jdbcUrl: String, val schema: String, val username: String, val password: String)
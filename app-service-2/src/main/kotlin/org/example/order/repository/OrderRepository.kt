package org.example.order.repository

import net.samyn.kapper.execute
import javax.sql.DataSource

class OrderRepository(private val dataSource: DataSource) {

    fun insert(id: String) {
        dataSource.connection.use { connection ->
            connection.execute(
                sql = "INSERT INTO orders (id) VALUES :id",
                "id" to id
            )
        }
    }
}
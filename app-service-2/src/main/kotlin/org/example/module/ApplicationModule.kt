package org.example.module

import org.example.Config
import org.example.datasource.ApplicationDataSource
import org.example.order.repository.OrderRepository
import org.koin.core.module.dsl.bind
import org.koin.core.module.dsl.singleOf
import org.koin.dsl.module
import javax.sql.DataSource

fun applicationModule(config: Config) = module {
    single { config }
    single { config.database }
    singleOf(::ApplicationDataSource) { bind<DataSource>() }
    singleOf(::OrderRepository)
}
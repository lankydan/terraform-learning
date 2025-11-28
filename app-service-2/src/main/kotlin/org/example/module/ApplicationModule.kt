package org.example.module

import org.example.Config
import org.example.datasource.ApplicationDataSource
import org.example.order.repository.OrderRepository
import org.koin.core.module.dsl.singleOf
import org.koin.dsl.module

fun applicationModule(config: Config) = module {
    single { config }
    single { config.databaseConfig }
    singleOf(::ApplicationDataSource)
    singleOf(::OrderRepository)
}
package org.example

import java.io.File

fun main(args: Array<String>) {
    println("Hello World! - ${args.toList()}")
    println("Running with environment variable - ${System.getenv("MY_VARIABLE")}")
    println("Running with environment variable 2 - ${System.getenv("MY_VARIABLE_2")}")
    val location = args[1]
    val config = File(location).let { file -> if(file.exists()) file.readText() else "" }
    println("Loaded configuration $location - $config")
    var i = 0
    while (true) {
        println("log - ${i++}")
        Thread.sleep(5000)
    }
}
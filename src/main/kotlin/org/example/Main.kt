package org.example

fun main(args: Array<String>) {
    println("Hello World! - ${args.toList()}")
    val myVariable = System.getenv("MY_VARIABLE")
    println("Running with environment variable - ${System.getenv("MY_VARIABLE")}")
    println("Running with environment variable 2 - ${System.getenv("MY_VARIABLE_2")}")
    var i = 0
    while (true) {
        println("log - ${i++}")
        Thread.sleep(5000)
    }
}
package org.example

fun main(args: Array<String>) {
    println("Hello World! - ${args.toList()}")
    val myVariable = System.getenv("MY_VARIABLE")
    println("Running with environment variable - $myVariable")
    var i = 0
    while (true) {
        println("log - ${i++}")
        Thread.sleep(5000)
    }
}
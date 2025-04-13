package org.example

fun main(args: Array<String>) {
    println("Hello World! - ${args.toList()}")
    var i = 0
    while (true) {
        println("log - ${i++}")
        Thread.sleep(5000)
    }
}
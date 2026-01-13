package com.munserv

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.context.properties.ConfigurationPropertiesScan
import org.springframework.boot.runApplication

@SpringBootApplication
@ConfigurationPropertiesScan
class MunServApplication

fun main(args: Array<String>) {
    runApplication<MunServApplication>(*args)
}

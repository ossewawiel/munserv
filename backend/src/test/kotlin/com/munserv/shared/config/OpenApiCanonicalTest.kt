package com.munserv.shared.config

import io.kotest.matchers.shouldBe
import org.junit.jupiter.api.Test

class OpenApiCanonicalTest {
    private fun canonical(json: String): String = canonicalize(openApiMapper.readTree(json)).toString()

    @Test
    fun `should sort keys at every depth`() {
        canonical("""{"b":{"z":1,"a":{"y":2,"x":3}},"a":1}""") shouldBe
            """{"a":1,"b":{"a":{"x":3,"y":2},"z":1}}"""
    }

    @Test
    fun `should drop servers`() {
        canonical("""{"servers":[{"url":"http://localhost:8080"}],"openapi":"3.1.0"}""") shouldBe
            """{"openapi":"3.1.0"}"""
    }

    @Test
    fun `should sort tags by name`() {
        canonical("""{"tags":[{"name":"Pods"},{"name":"Auth"}]}""") shouldBe
            """{"tags":[{"name":"Auth"},{"name":"Pods"}]}"""
    }

    @Test
    fun `should sort required and operation tags`() {
        canonical("""{"s":{"required":["b","a"],"tags":["z","y"]}}""") shouldBe
            """{"s":{"required":["a","b"],"tags":["y","z"]}}"""
    }

    @Test
    fun `should keep enum order`() {
        canonical("""{"s":{"enum":["reported","closed","assigned"]}}""") shouldBe
            """{"s":{"enum":["reported","closed","assigned"]}}"""
    }

    @Test
    fun `should keep parameters order`() {
        canonical("""{"parameters":[{"name":"z"},{"name":"a"}]}""") shouldBe
            """{"parameters":[{"name":"z"},{"name":"a"}]}"""
    }
}

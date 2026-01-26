package com.munserv.bootstrap.config

import io.kotest.matchers.shouldBe
import org.junit.jupiter.api.Test

class BootstrapConfigTest {
    @Test
    fun `isConfigured returns false when disabled`() {
        val config = BootstrapConfig(enabled = false, email = "test@test.com", password = "pass")
        config.isConfigured() shouldBe false
    }

    @Test
    fun `isConfigured returns false when email is null`() {
        val config = BootstrapConfig(enabled = true, email = null, password = "pass")
        config.isConfigured() shouldBe false
    }

    @Test
    fun `isConfigured returns false when email is blank`() {
        val config = BootstrapConfig(enabled = true, email = "  ", password = "pass")
        config.isConfigured() shouldBe false
    }

    @Test
    fun `isConfigured returns false when password is null`() {
        val config = BootstrapConfig(enabled = true, email = "test@test.com", password = null)
        config.isConfigured() shouldBe false
    }

    @Test
    fun `isConfigured returns false when password is blank`() {
        val config = BootstrapConfig(enabled = true, email = "test@test.com", password = "  ")
        config.isConfigured() shouldBe false
    }

    @Test
    fun `isConfigured returns true when enabled and credentials set`() {
        val config = BootstrapConfig(enabled = true, email = "test@test.com", password = "pass")
        config.isConfigured() shouldBe true
    }

    @Test
    fun `default values are secure`() {
        val config = BootstrapConfig()
        config.enabled shouldBe false
        config.email shouldBe null
        config.password shouldBe null
        config.isConfigured() shouldBe false
    }
}

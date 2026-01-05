package com.munserv

import org.junit.jupiter.api.Test
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.test.context.ActiveProfiles

@SpringBootTest
@ActiveProfiles("test")
class MunServApplicationTests {
    @Test
    fun `context loads`() {
        // If this test passes, the Spring context is configured correctly
    }
}

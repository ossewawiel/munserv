package com.munserv.sectors.api

import com.munserv.TestContainersConfig
import io.kotest.matchers.shouldBe
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc
import org.springframework.context.annotation.Import
import org.springframework.http.MediaType
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get

@SpringBootTest
@Import(TestContainersConfig::class)
@AutoConfigureMockMvc
@ActiveProfiles("test")
class SectorControllerTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Test
    fun `GET api-v1-sectors should return list of sectors`() {
        mockMvc
            .get("/api/v1/sectors") {
                accept = MediaType.APPLICATION_JSON
            }.andExpect {
                status { isOk() }
                content { contentType(MediaType.APPLICATION_JSON) }
                jsonPath("$.items") { isArray() }
                jsonPath("$.items.length()") { value(2) }
            }
    }

    @Test
    fun `GET api-v1-sectors should return sectors with correct structure`() {
        mockMvc
            .get("/api/v1/sectors") {
                accept = MediaType.APPLICATION_JSON
            }.andExpect {
                status { isOk() }
                jsonPath("$.items[0].id") { isNotEmpty() }
                jsonPath("$.items[0].name") { isNotEmpty() }
                jsonPath("$.items[0].center.latitude") { isNumber() }
                jsonPath("$.items[0].center.longitude") { isNumber() }
            }
    }

    @Test
    fun `GET api-v1-sectors should match mock API contract`() {
        val result =
            mockMvc
                .get("/api/v1/sectors") {
                    accept = MediaType.APPLICATION_JSON
                }.andExpect {
                    status { isOk() }
                }.andReturn()

        // Verify response matches mock API format
        val content = result.response.contentAsString
        content.contains("\"items\"") shouldBe true
        content.contains("\"id\"") shouldBe true
        content.contains("\"name\"") shouldBe true
        content.contains("\"center\"") shouldBe true
        content.contains("\"latitude\"") shouldBe true
        content.contains("\"longitude\"") shouldBe true
    }

    @Test
    fun `GET api-v1-sectors should not require authentication`() {
        // No auth header provided, should still work
        mockMvc
            .get("/api/v1/sectors") {
                accept = MediaType.APPLICATION_JSON
            }.andExpect {
                status { isOk() }
            }
    }
}

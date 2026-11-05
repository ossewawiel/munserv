package com.munserv.shared.config

import com.munserv.TestContainersConfig
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldNotBeEmpty
import io.kotest.matchers.shouldBe
import io.swagger.v3.oas.annotations.Operation
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.fail
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.beans.factory.annotation.Qualifier
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc
import org.springframework.context.annotation.Import
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get
import org.springframework.web.method.HandlerMethod
import org.springframework.web.servlet.mvc.method.RequestMappingInfo
import org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerMapping
import tools.jackson.databind.JsonNode
import java.nio.file.Files
import java.nio.file.Path

/**
 * Keeps `specs/contracts/openapi.json` equal to what the code serves. The test writes a stale file
 * and fails, so a run can never rewrite the contract and still pass.
 */
@SpringBootTest
@Import(TestContainersConfig::class)
@AutoConfigureMockMvc
@ActiveProfiles("test")
class OpenApiContractTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    @Qualifier("requestMappingHandlerMapping")
    private lateinit var handlerMapping: RequestMappingHandlerMapping

    private val contractFile: Path = Path.of("..", "specs", "contracts", "openapi.json")

    private fun fetchContract(): JsonNode {
        val body =
            mockMvc
                .get("/v3/api-docs")
                .andExpect { status { isOk() } }
                .andReturn()
                .response.contentAsByteArray
        return canonicalize(openApiMapper.readTree(body))
    }

    private fun controllerHandlers(): Map<RequestMappingInfo, HandlerMethod> =
        handlerMapping.handlerMethods.filterValues { it.beanType.packageName.startsWith(APP_PACKAGE) }

    private fun operations(contract: JsonNode): List<Triple<String, String, JsonNode>> =
        contract.path("paths").properties().flatMap { (path, item) ->
            item
                .properties()
                .filter { it.key in HTTP_METHODS }
                .map { (method, operation) -> Triple(method.uppercase(), path, operation) }
        }

    @Test
    fun `should match the committed contract file`() {
        Files.isDirectory(contractFile.parent) shouldBe true

        val generated = openApiMapper.writeValueAsString(fetchContract()) + "\n"
        val committed = if (Files.exists(contractFile)) Files.readString(contractFile) else null

        if (committed != generated) {
            Files.writeString(contractFile, generated)
            fail(STALE_MESSAGE)
        }
    }

    @Test
    fun `should list every controller route`() {
        val routesInCode =
            controllerHandlers().keys.flatMap { info ->
                info.methodsCondition.methods.shouldNotBeEmpty()
                val patterns = requireNotNull(info.pathPatternsCondition).patternValues
                info.methodsCondition.methods.flatMap { method -> patterns.map { method.name to it } }
            }

        val routesInContract = operations(fetchContract()).map { (method, path, _) -> method to path }

        routesInContract.toSet() shouldBe routesInCode.toSet()
    }

    @Test
    fun `should give every route an explicit unique operationId and a tag`() {
        val contract = fetchContract()
        val idsInCode =
            controllerHandlers().map { (info, handler) ->
                val id = handler.getMethodAnnotation(Operation::class.java)?.operationId.orEmpty()
                if (!OPERATION_ID.matches(id)) fail("$info needs an @Operation operationId matching $OPERATION_ID, has '$id'")
                id
            }
        idsInCode
            .groupingBy { it }
            .eachCount()
            .filterValues { it > 1 }
            .keys
            .shouldBeEmpty()

        val inContract = operations(contract)
        inContract.map { (_, _, operation) -> operation.path("operationId").asString() }.toSet() shouldBe idsInCode.toSet()
        inContract
            .filter { (_, _, operation) -> operation.path("tags").isEmpty }
            .map { (method, path, _) -> "$method $path" }
            .shouldBeEmpty()

        val rootTags = contract.path("tags").values().map { it.path("name").asString() }
        rootTags
            .groupingBy { it }
            .eachCount()
            .filterValues { it > 1 }
            .keys
            .shouldBeEmpty()
    }

    @Test
    fun `should name a schema on every success response with a body`() {
        val bare =
            operations(fetchContract()).flatMap { (method, path, operation) ->
                operation
                    .path("responses")
                    .properties()
                    .filter { (status, _) -> status.startsWith("2") && status != NO_CONTENT }
                    .filter { (_, response) -> !namesASchema(response) }
                    .map { (status, _) -> "$method $path $status" }
            }

        bare.shouldBeEmpty()
    }

    private fun namesASchema(response: JsonNode): Boolean {
        val content = response.path("content")
        if (content.isEmpty) return false
        return content.values().none { media ->
            val schema = media.path("schema")
            schema.path("type").asString("") == "object" && !schema.has("properties") && !schema.has("additionalProperties")
        }
    }

    @Test
    fun `should keep is-prefixed names as on the wire`() {
        val schemas = fetchContract().path("components").path("schemas")
        val propertyNames = schemas.values().flatMap { it.path("properties").propertyNames() }.toSet()

        listOf("isComplete", "isOnboarded", "isGroundAdmin", "isRegistered").filterNot { it in propertyNames }.shouldBeEmpty()
        listOf("complete", "onboarded", "groundAdmin", "registered").filter { it in propertyNames }.shouldBeEmpty()
    }

    private companion object {
        const val APP_PACKAGE = "com.munserv"
        const val NO_CONTENT = "204"
        const val STALE_MESSAGE = "openapi.json was stale and has been rewritten. Review it, commit it, run the test again."
        val HTTP_METHODS = setOf("get", "post", "put", "patch", "delete")
        val OPERATION_ID = Regex("^[a-z][a-zA-Z0-9]*$")
    }
}

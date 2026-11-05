package com.munserv.shared.config

import tools.jackson.databind.JsonNode
import tools.jackson.databind.SerializationFeature
import tools.jackson.databind.json.JsonMapper
import tools.jackson.databind.node.ArrayNode
import tools.jackson.databind.node.ObjectNode

/** Writes the committed contract file: indented, so its diffs read line by line. */
val openApiMapper: JsonMapper =
    JsonMapper
        .builder()
        .enable(SerializationFeature.INDENT_OUTPUT)
        .build()

private val SORTED_STRING_ARRAYS = setOf("required", "type", "tags")
private const val SERVERS = "servers"
private const val ROOT_TAGS = "tags"
private const val TAG_NAME = "name"

/**
 * Puts a springdoc document into one stable form: `servers` gone, object keys sorted at every
 * depth, and set-like arrays sorted. `enum` and `parameters` keep their order because it carries
 * meaning for a reader.
 */
fun canonicalize(raw: JsonNode): JsonNode {
    val sorted = sortNode(raw)
    if (sorted !is ObjectNode) return sorted

    val root = openApiMapper.createObjectNode()
    sorted.properties().filter { it.key != SERVERS }.forEach { (key, value) ->
        root.set(key, if (key == ROOT_TAGS) sortTagsByName(value) else value)
    }
    return root
}

private fun sortNode(node: JsonNode): JsonNode =
    when {
        node.isObject -> sortObject(node)
        node.isArray -> mapArray(node)
        else -> node
    }

private fun sortObject(node: JsonNode): ObjectNode {
    val result = openApiMapper.createObjectNode()
    node
        .properties()
        .sortedBy { it.key }
        .forEach { (key, value) ->
            val child = sortNode(value)
            result.set(key, if (key in SORTED_STRING_ARRAYS) sortStringArray(child) else child)
        }
    return result
}

private fun mapArray(node: JsonNode): ArrayNode {
    val result = openApiMapper.createArrayNode()
    node.values().forEach { result.add(sortNode(it)) }
    return result
}

private fun sortStringArray(node: JsonNode): JsonNode {
    if (!node.isArray || !node.values().all { it.isString }) return node
    val result = openApiMapper.createArrayNode()
    node.values().sortedBy { it.asString() }.forEach { result.add(it) }
    return result
}

private fun sortTagsByName(node: JsonNode): JsonNode {
    if (!node.isArray) return node
    val result = openApiMapper.createArrayNode()
    node.values().sortedBy { it.path(TAG_NAME).asString() }.forEach { result.add(it) }
    return result
}

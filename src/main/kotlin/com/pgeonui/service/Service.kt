package com.pgeonui.service

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.module.kotlin.readValue
import com.pgeonui.model.OpenApi
import com.pgeonui.model.Property
import io.micrometer.core.annotation.Timed
import io.micrometer.core.instrument.MeterRegistry
import io.micrometer.core.instrument.Timer
import io.quarkus.logging.Log
import jakarta.enterprise.context.ApplicationScoped
import jakarta.inject.Inject
import org.eclipse.microprofile.config.inject.ConfigProperty
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse

@ApplicationScoped
class Service {

    private val httpClient: HttpClient = HttpClient.newBuilder()
        .version(HttpClient.Version.HTTP_2)
        .build()

    @Inject
    private lateinit var registry: MeterRegistry

    @Inject
    private lateinit var objectMapper: ObjectMapper

    @Inject
    @ConfigProperty(name = "postgrest.url")
    private lateinit var postgrestUrl: String

    private var openApiSpec: OpenApi? = null

    fun fetchTableData(tableName: String, page: Int = 1, pageSize: Int = 10): Map<String, Any> {
        val offset = (page - 1) * pageSize
        val url = "$postgrestUrl/$tableName"

        val requestBuilder = HttpRequest.newBuilder()
            .uri(URI.create(url))
            .header("accept", "application/json")
            .header("Range-Unit", "items")
            .header("Range", "$offset-${offset + pageSize - 1}")
            .header("Prefer", "count=exact")  // For accurate pagination

        println("Sending request to: $url with range: $offset-${offset + pageSize - 1}")

        val timerSample = Timer.start(registry)
        val timerName = "postgrest.table.fetch.time"
        val tags = listOf("tableName", tableName)

        try {
            val response = httpClient.send(requestBuilder.build(), HttpResponse.BodyHandlers.ofString())
            Log.info("Response status: ${response.statusCode()}")

            timerSample.stop(registry.timer(timerName, *tags.toTypedArray(), "status", response.statusCode().toString()))

            if (response.statusCode() >= 400) {
                throw RuntimeException("PostgREST server returned error status: ${response.statusCode()}, body: ${response.body()}")
            }

            val contentRange = response.headers().firstValue("Content-Range").orElse("0-0/0")
            Log.info("Content-Range header: $contentRange")

            val (start, end, total) = parseContentRange(contentRange)
            val totalPages = if (total > 0) (total + pageSize - 1) / pageSize else 1

            val responseBody = response.body()
            if (responseBody.isBlank()) {
                Log.info("Empty response body from PostgREST")
                return mapOf(
                    "data" to emptyList<Map<String, Any>>(),
                    "page" to page,
                    "pageSize" to pageSize,
                    "start" to start,
                    "end" to end,
                    "count" to total,
                    "totalPages" to totalPages
                )
            }

            val data = objectMapper.readValue<List<Map<String, Any>>>(responseBody)

            return mapOf(
                "data" to data,
                "page" to page,
                "pageSize" to pageSize,
                "start" to start,
                "end" to end,
                "count" to total,
                "totalPages" to totalPages
            )
        } catch (e: Exception) {
            timerSample.stop(registry.timer(timerName, *tags.toTypedArray(), "status", "error", "exception", e.javaClass.simpleName))
            e.printStackTrace()
            throw RuntimeException("Error fetching data from PostgREST for table '$tableName': ${e.message}", e)
        }
    }

    private fun parseContentRange(contentRange: String): Triple<Int, Int, Int> {
        try {
            val (range, totalPart) = contentRange.split("/")
            val (start, end) = range.split("-").map { it.toInt() }
            val total = if (totalPart == "*") 0 else totalPart.toInt()
            return Triple(start, end, total)
        } catch (e: Exception) {
            return Triple(0, 0, 0)
        }
    }


    fun getAvailableTables(): List<String> {
        val spec = getOpenApiSpec()
        val tables = spec.definitions?.keys

        if (tables == null) {
            return emptyList()
        }
        return tables
            .filter { !listOf("databasechangelog", "databasechangeloglock").contains(it) }
            .distinct()
    }

    fun getTableColumns(tableName: String): Map<String, Property> {
        val spec = getOpenApiSpec()
        val definitions = spec.definitions
        val tableDefinition = definitions?.get(tableName)
        val properties = tableDefinition?.properties

        if (properties == null) {
            return emptyMap()
        }

        return properties
    }

    @Timed(value = "postgrest.openapi.fetch.time")
    fun getOpenApiSpec(): OpenApi {
        Log.info("Fetching OpenAPI spec ")
        if (openApiSpec == null) {
            val request = HttpRequest.newBuilder()
                .uri(URI.create(postgrestUrl))
                .header("accept", "application/json")
                .build()

            val response = httpClient.send(request, HttpResponse.BodyHandlers.ofString())
            Log.info("Response status: ${response.statusCode()}")

            openApiSpec = objectMapper
                .readValue(response.body(), OpenApi::class.java)
        }

        return openApiSpec!!
    }
}

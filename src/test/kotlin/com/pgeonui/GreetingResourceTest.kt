package com.pgeonui

import com.pgeonui.service.Service
import io.quarkus.test.InjectMock
import io.quarkus.test.junit.QuarkusTest
import io.restassured.RestAssured.given
import org.junit.jupiter.api.Test
import org.mockito.kotlin.whenever

@QuarkusTest
class GreetingResourceTest {

    @InjectMock
    lateinit var service: Service

    // Removed the inner MockService class to rely solely on @InjectMock for 'service'

    @Test
    fun testHelloEndpoint() {

        whenever(service.getAvailableTables()).thenReturn(listOf("table1", "table2"))

        given()
            .`when`().get("/ui")
            .then()
            .statusCode(200)
    }
}

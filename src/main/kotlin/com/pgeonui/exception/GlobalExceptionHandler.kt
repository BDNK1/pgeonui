package com.pgeonui.exception

import jakarta.ws.rs.core.Response
import jakarta.ws.rs.ext.ExceptionMapper
import jakarta.ws.rs.ext.Provider


@Provider // This annotation makes it discoverable by JAX-RS
class GlobalExceptionHandler : ExceptionMapper<Throwable?> {

    override fun toResponse(p0: Throwable?): Response? {
//        println("sadasd")
        println(p0?.message)
        println(p0?.printStackTrace())
        return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
            .entity("An unexpected error occurred on the server.")
            .type("text/plain")
            .build()
    }

}

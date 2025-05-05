package com.pgeonui.controller

import com.pgeonui.service.Service
import io.quarkus.logging.Log
import jakarta.inject.Inject
import jakarta.ws.rs.*
import jakarta.ws.rs.core.MediaType
import jakarta.ws.rs.core.Response

@Path("/ui")
class TableResource {

    @Inject
    lateinit var service: Service

    @GET
    @Produces(MediaType.TEXT_HTML)
    fun index(): Response {
        Log.info("Fetching available tables")
        val tables = service.getAvailableTables()
        Log.info("Tables: $tables")
        val html = Templates.index(tables).render()
        return Response.ok(html).build()
    }

    @GET
    @Path("/{tableName}")
    @Produces(MediaType.TEXT_HTML)
    fun showTable(
        @PathParam("tableName") tableName: String,
        @QueryParam("page") @DefaultValue("1") page: Int,
        @QueryParam("pageSize") @DefaultValue("10") pageSize: Int
    ): Response {
        Log.info("Showing table: $tableName, page: $page, pageSize: $pageSize")
        val result = service.fetchTableData(tableName, page, pageSize)
        val data = result["data"] as List<Map<String, Any>>
        val count = result["count"] as Int
        val totalPages = result["totalPages"] as Int
        val columns = service.getTableColumns(tableName)

        Log.info("Got ${data.size} rows, total count: $count, totalPages: $totalPages")
        Log.info("Columns: ${columns.keys}")

        val prevPage = if (page > 1) page - 1 else 1
        val nextPage = if (page < totalPages) page + 1 else totalPages
        val prevPageUrl = "/ui/$tableName/rows?page=$prevPage&pageSize=$pageSize"
        val nextPageUrl = "/ui/$tableName/rows?page=$nextPage&pageSize=$pageSize"
        val isPrevDisabled = page <= 1
        val isNextDisabled = page >= totalPages
        val offset = (page - 1) * pageSize

        val html = Templates.table(
            tableName,
            columns,
            data,
            page,
            totalPages,
            pageSize,
            count,
            prevPageUrl,
            nextPageUrl,
            isPrevDisabled,
            isNextDisabled,
            offset
        ).render()

        return Response.ok(html).build()
    }

    @GET
    @Path("/{tableName}/rows")
    @Produces(MediaType.TEXT_HTML)
    fun getTableRows(
        @PathParam("tableName") tableName: String,
        @QueryParam("page") @DefaultValue("1") page: Int,
        @QueryParam("pageSize") @DefaultValue("10") pageSize: Int
    ): Response {
        Log.info("Fetching table rows: $tableName, page: $page, pageSize: $pageSize")
        try {
            val result = service.fetchTableData(tableName, page, pageSize)
            val data = result["data"] as List<Map<String, Any>>
            val count = result["count"] as Int
            val totalPages = result["totalPages"] as Int
            val columns = service.getTableColumns(tableName)

            val prevPage = if (page > 1) page - 1 else 1
            val nextPage = if (page < totalPages) page + 1 else totalPages
            val prevPageUrl = "/ui/$tableName/rows?page=$prevPage&pageSize=$pageSize"
            val nextPageUrl = "/ui/$tableName/rows?page=$nextPage&pageSize=$pageSize"
            val isPrevDisabled = page <= 1
            val isNextDisabled = page >= totalPages

            val tableRowsHtml = Templates.tableRows(data, columns).render()
            val paginationHtml =
                Templates.pagination(
                    page,
                    totalPages,
                    count,
                    prevPageUrl,
                    nextPageUrl,
                    isPrevDisabled,
                    isNextDisabled
                ).render()

            return Response.ok(tableRowsHtml + paginationHtml).build()

        } catch (e: Exception) {
            Log.error("Error fetching table rows", e)
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                .entity("<tr><td colspan=\"999\" class=\"px-6 py-4 text-center text-sm text-red-500\">Error loading data: ${e.message ?: "Unknown error"}</td></tr>")
                .type(MediaType.TEXT_HTML)
                .build()
        }
    }

}
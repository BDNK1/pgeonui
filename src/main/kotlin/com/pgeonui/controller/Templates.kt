package com.pgeonui.controller

import com.pgeonui.model.Property
import io.quarkus.qute.CheckedTemplate
import io.quarkus.qute.TemplateInstance

@CheckedTemplate(requireTypeSafeExpressions = false)
object Templates {
    @JvmStatic
    external fun index(tables: List<String>): TemplateInstance

    @JvmStatic
    external fun table(
        tableName: String,
        columns: Map<String, Property>,
        data: List<Map<String, Any>>,
        currentPage: Int,
        totalPages: Int,
        pageSize: Int,
        totalCount: Int,
        prevPageUrl: String,
        nextPageUrl: String,
        isPrevDisabled: Boolean,
        isNextDisabled: Boolean,
        offset: Int

    ): TemplateInstance

    @JvmStatic
    external fun tableRows(
        data: List<Map<String, Any>>,
        columns: Map<String, Property>

    ): TemplateInstance

    @JvmStatic
    external fun pagination(
        tableName: String,
        currentPage: Int,
        pageSize: Int,
        totalPages: Int,
        totalCount: Int,
        prevPageUrl: String,
        nextPageUrl: String,
        isPrevDisabled: Boolean,
        isNextDisabled: Boolean

    ): TemplateInstance
}
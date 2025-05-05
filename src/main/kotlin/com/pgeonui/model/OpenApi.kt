package com.pgeonui.model

data class OpenApi(
    val definitions: Map<String, Definition>?,
    val parameters: Map<String, Parameter>?
)

data class Parameter(
    val name: String?,
    val `in`: String,
    val description: String?,
    val required: Boolean?,
    val schema: Schema?,
    val type: String?,
    val format: String?,
    val enum: List<String>?,
    val items: Items?
)

data class Items(
    val type: String?,
    val format: String?
)

data class Schema(
    val type: String?,
    val format: String?,
    val items: Items?,
    val properties: Map<String, Property>?
)

data class Property(
    val type: String?,
    val format: String?,
    val maxLength: Int?,
    val description: String?
)


data class Definition(
    val type: String?,
    val properties: Map<String, Property>?,
    val required: List<String>?
)


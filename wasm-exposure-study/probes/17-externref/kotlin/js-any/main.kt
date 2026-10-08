@file:OptIn(kotlin.wasm.ExperimentalWasmInterop::class, kotlin.wasm.unsafe.UnsafeWasmMemoryApi::class)

import kotlin.wasm.WasmExport
import kotlin.wasm.WasmImport

import kotlin.js.JsAny

@JsExport
fun identity(x: JsAny?): JsAny? = x

fun main() {}

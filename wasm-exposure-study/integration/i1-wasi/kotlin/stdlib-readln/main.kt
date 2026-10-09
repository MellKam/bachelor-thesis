// The standard library's own text input: Kotlin/Wasm WASI has readln() / readlnOrNull() and println().
fun main() {
    while (true) {
        val line = readlnOrNull() ?: break
        println(line)
    }
}

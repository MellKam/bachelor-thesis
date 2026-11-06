// @JsExport only takes functions, and a function can return only external, primitive, string or function types: the record is a JS
// object built by a js() snippet.
external interface Stats : JsAny {
    val words: Int
    val bytes: Int
    val longest: String
}

fun makeStats(words: Int, bytes: Int, longest: String): Stats = js("({ words: words, bytes: bytes, longest: longest })")

private fun isWs(c: Byte) = c.toInt() == 32 || c.toInt() == 9 || c.toInt() == 10 || c.toInt() == 13

@JsExport
fun analyse(text: String): Stats {
    val b = text.encodeToByteArray()
    var words = 0
    var best = 0
    var bestAt = 0
    var i = 0
    while (i < b.size) {
        while (i < b.size && isWs(b[i])) i++
        val start = i
        while (i < b.size && !isWs(b[i])) i++
        if (i > start) {
            words++
            if (i - start > best) { best = i - start; bestAt = start }
        }
    }
    return makeStats(words, b.size, b.decodeToString(bestAt, bestAt + best))
}

fun main() {}

import JavaScriptKit

func isWs(_ c: UInt8) -> Bool { c == 32 || c == 9 || c == 10 || c == 13 }

let analyse = JSClosure { args in
    let text = args[0].string ?? ""
    let b = Array(text.utf8)
    var words = 0, best = 0, bestAt = 0, i = 0
    while i < b.count {
        while i < b.count && isWs(b[i]) { i += 1 }
        let start = i
        while i < b.count && !isWs(b[i]) { i += 1 }
        if i > start {
            words += 1
            if i - start > best { best = i - start; bestAt = start }
        }
    }
    let r = JSObject()
    r.words = .number(Double(words))
    r.bytes = .number(Double(b.count))
    r.longest = .string(String(decoding: b[bestAt..<(bestAt + best)], as: UTF8.self))
    return .object(r)
}

JSObject.global.analyse = .object(analyse)

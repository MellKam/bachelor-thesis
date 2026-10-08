
import * as d2FzbTpqcy1zdHJpbmc from './app.js-builtins.mjs';

const wasmJsTag = WebAssembly.JSTag;
const wasmTag = wasmJsTag ?? new WebAssembly.Tag({ parameters: ['externref'] });

// Placed here to give access to it from externals (js_code)
let wasmExports;

if (typeof process !== 'undefined' && process.release.name === 'node') {
    function doNotUseRequire() {
        throw new Error("Do not use top-level require. Prefer to use JS import or define your own require instead. Read more: https://kotl.in/r9txlt")
    }

    var require = new Proxy((function() {}), {
        apply(target, thisArg, argumentsList) {
            if (globalThis.require != null) {
                return globalThis.require.apply(thisArg, argumentsList);
            } else {
                doNotUseRequire();
            }
        },
        get(target, prop, receiver) {
            if (globalThis.require != null) {
                return Reflect.get(globalThis.require, prop);
            } else {
                doNotUseRequire();
            }
        },
    });
}

export function setWasmExports(exports) {
    wasmExports = exports;
}

const cachedJsObjects = new WeakMap();
function getCachedJsObject(ref, ifNotCached) {
    if (typeof ref !== 'object' && typeof ref !== 'function') return ifNotCached;
    const cached = cachedJsObjects.get(ref);
    if (cached !== void 0) return cached;
    cachedJsObjects.set(ref, ifNotCached);
    return ifNotCached;
}

const js_code = {
    'kotlin.createJsError' : (message, cause) => new Error(message, { cause }),
    'kotlin.wasm.internal.jsThrow' : wasmTag === wasmJsTag ? (e) => { throw e; } : () => {},
    'kotlin.wasm.internal.getJsEmptyString' : () => '',
    'kotlin.wasm.internal.externrefToString' : (ref) => String(ref),
    'kotlin.wasm.internal.externrefEquals' : (lhs, rhs) => lhs === rhs,
    'kotlin.wasm.internal.externrefHashCode' : 
    (() => {
    const dataView = new DataView(new ArrayBuffer(8));
    function numberHashCode(obj) {
        if ((obj | 0) === obj) {
            return obj | 0;
        } else {
            dataView.setFloat64(0, obj, true);
            return (dataView.getInt32(0, true) * 31 | 0) + dataView.getInt32(4, true) | 0;
        }
    }

    const hashCodes = new WeakMap();
    function getObjectHashCode(obj) {
        const res = hashCodes.get(obj);
        if (res === undefined) {
            const POW_2_32 = 4294967296;
            const hash = (Math.random() * POW_2_32) | 0;
            hashCodes.set(obj, hash);
            return hash;
        }
        return res;
    }

    function getStringHashCode(str) {
        var hash = 0;
        for (var i = 0; i < str.length; i++) {
            var code  = str.charCodeAt(i);
            hash  = (hash * 31 + code) | 0;
        }
        return hash;
    }

    return (obj) => {
        if (obj == null) {
            return 0;
        }
        switch (typeof obj) {
            case "object":
            case "function":
                return getObjectHashCode(obj);
            case "number":
                return numberHashCode(obj);
            case "boolean":
                return obj ? 1231 : 1237;
            default:
                return getStringHashCode(String(obj)); 
        }
    }
    })(),
    'kotlin.wasm.internal.isNullish' : (ref) => ref == null,
    'kotlin.wasm.internal.externrefToInt' : (ref) => Number(ref),
    'kotlin.wasm.internal.externrefToBoolean' : (ref) => Boolean(ref),
    'kotlin.wasm.internal.externrefToLong' : (ref) => BigInt(ref),
    'kotlin.wasm.internal.externrefToFloat' : (ref) => Number(ref),
    'kotlin.wasm.internal.externrefToDouble' : (ref) => Number(ref),
    'kotlin.wasm.internal.externrefToUByte' : (ref) => Number(ref),
    'kotlin.wasm.internal.externrefToUShort' : (ref) => Number(ref),
    'kotlin.wasm.internal.externrefToUInt' : (ref) => Number(ref),
    'kotlin.wasm.internal.externrefToULong' : (ref) => BigInt(ref),
    'kotlin.wasm.internal.intToExternref' : (x) => x,
    'kotlin.wasm.internal.getJsTrue' : () => true,
    'kotlin.wasm.internal.getJsFalse' : () => false,
    'kotlin.wasm.internal.longToExternref' : (x) => x,
    'kotlin.wasm.internal.floatToExternref' : (x) => x,
    'kotlin.wasm.internal.doubleToExternref' : (x) => x,
    'kotlin.wasm.internal.kotlinUByteToJsNumberUnsafe' : (x) => x & 0xFF,
    'kotlin.wasm.internal.kotlinUShortToJsNumberUnsafe' : (x) => x & 0xFFFF,
    'kotlin.wasm.internal.kotlinUIntToJsNumberUnsafe' : (x) => x >>> 0,
    'kotlin.wasm.internal.kotlinULongToJsBigIntUnsafe' : (x) => x & 0xFFFFFFFFFFFFFFFFn,
    'kotlin.wasm.internal.newJsArray' : () => [],
    'kotlin.wasm.internal.jsArrayPush' : (array, element) => { array.push(element); },
    'kotlin.wasm.internal.getCachedJsObject_$external_fun' : (p0, p1) => getCachedJsObject(p0, p1),
    'kotlin.wasm.internal.utoa32_$external_fun' : (p0) => String(p0),
    'kotlin.wasm.internal.utoa64_$external_fun' : (p0) => String(p0),
    'kotlin.wasm.internal.itoa32_$external_fun' : (p0) => String(p0),
    'kotlin.wasm.internal.itoa64_$external_fun' : (p0) => String(p0),
    'kotlin.js.JsArray_$external_fun' : () => new Array(),
    'kotlin.js.length_$external_prop_getter' : (_this) => _this.length,
    'kotlin.js.JsArray_$external_class_instanceof' : (x) => x instanceof Array,
    'kotlin.js.JsArray_$external_class_get' : () => Array,
    'kotlin.js.JsBigInt_$external_fun' : () => new JsBigInt(),
    'kotlin.js.JsBigInt_$external_class_instanceof' : (x) => typeof x === 'bigint',
    'kotlin.js.JsBigInt_$external_class_get' : () => JsBigInt,
    'kotlin.js.JsBoolean_$external_fun' : () => new JsBoolean(),
    'kotlin.js.JsBoolean_$external_class_instanceof' : (x) => typeof x === 'boolean',
    'kotlin.js.JsBoolean_$external_class_get' : () => JsBoolean,
    'kotlin.js.stackPlaceHolder_js_code' : () => (''),
    'kotlin.js.JsError_$external_fun' : () => new Error(),
    'kotlin.js.message_$external_prop_getter' : (_this) => _this.message,
    'kotlin.js.name_$external_prop_getter' : (_this) => _this.name,
    'kotlin.js.name_$external_prop_setter' : (_this, v) => _this.name = v,
    'kotlin.js.stack_$external_prop_getter' : (_this) => _this.stack,
    'kotlin.js.cause_$external_prop_getter' : (_this) => _this.cause,
    'kotlin.js.kotlinException_$external_prop_getter' : (_this) => _this.kotlinException,
    'kotlin.js.kotlinException_$external_prop_setter' : (_this, v) => _this.kotlinException = v,
    'kotlin.js.JsError_$external_class_instanceof' : (x) => x instanceof Error,
    'kotlin.js.JsError_$external_class_get' : () => Error,
    'kotlin.js.JsNumber_$external_fun' : () => new JsNumber(),
    'kotlin.js.JsNumber_$external_class_instanceof' : (x) => typeof x === 'number',
    'kotlin.js.JsNumber_$external_class_get' : () => JsNumber,
    'kotlin.js.JsString_$external_fun' : () => new JsString(),
    'kotlin.js.JsString_$external_class_instanceof' : (x) => typeof x === 'string',
    'kotlin.js.JsString_$external_class_get' : () => JsString,
    'kotlin.js.Promise_$external_fun' : (p0) => new Promise(p0),
    'kotlin.js.__callJsClosure_((Js?)->Unit)' : (f, p0) => f(p0),
    'kotlin.js.__callJsClosure_((Js)->Unit)' : (f, p0) => f(p0),
    'kotlin.js.__convertKotlinClosureToJsClosure_2' : (f, trampoline) => getCachedJsObject(f, (p0, p1) => trampoline(f, p0, p1)),
    'kotlin.js.then_$external_fun' : (_this, p0) => _this.then(p0),
    'kotlin.js.__convertKotlinClosureToJsClosure_1' : (f, trampoline) => getCachedJsObject(f, (p0) => trampoline(f, p0)),
    'kotlin.js.then_$external_fun_1' : (_this, p0, p1) => _this.then(p0, p1),
    'kotlin.js.catch_$external_fun' : (_this, p0) => _this.catch(p0),
    'kotlin.js.finally_$external_fun' : (_this, p0) => _this.finally(p0),
    'kotlin.js.__convertKotlinClosureToJsClosure_0' : (f, trampoline) => getCachedJsObject(f, () => trampoline(f, )),
    'kotlin.js.Companion_$external_fun' : () => new Promise(),
    'kotlin.js.all_$external_fun' : (_this, p0) => _this.all(p0),
    'kotlin.js.race_$external_fun' : (_this, p0) => _this.race(p0),
    'kotlin.js.reject_$external_fun' : (_this, p0) => _this.reject(p0),
    'kotlin.js.resolve_$external_fun' : (_this, p0) => _this.resolve(p0),
    'kotlin.js.resolve_$external_fun_1' : (_this, p0) => _this.resolve(p0),
    'kotlin.js.Companion_$external_object_getInstance' : () => Promise,
    'kotlin.js.Companion_$external_class_instanceof' : (x) => x instanceof Promise,
    'kotlin.js.Companion_$external_class_get' : () => Promise,
    'kotlin.js.Promise_$external_class_instanceof' : (x) => x instanceof Promise,
    'kotlin.js.Promise_$external_class_get' : () => Promise,
    'kotlin.random.initialSeed' : () => ((Math.random() * Math.pow(2, 32)) | 0),
    'kotlin.wasm.internal.getJsClassName' : (jsKlass) => jsKlass.name,
    'kotlin.wasm.internal.instanceOf' : (ref, jsKlass) => ref instanceof jsKlass,
    'kotlin.wasm.internal.getConstructor' : (obj) => obj.constructor,
    'kotlin.wasm.unsafe.WebAssembly_$external_fun' : () => new WebAssembly(),
    'kotlin.wasm.unsafe.WebAssembly_$external_object_getInstance' : () => WebAssembly,
    'kotlin.wasm.unsafe.WebAssembly_$external_class_instanceof' : (x) => x instanceof WebAssembly,
    'kotlin.wasm.unsafe.WebAssembly_$external_class_get' : () => WebAssembly
}

const StringConstantsProxy = new Proxy({}, {
  get(_, prop) { return prop; }
});

export { wasmTag as __TAG };

export const importObject = {
    js_code,
    intrinsics: {
        memory: new WebAssembly.Memory({ initial: 0 }),
        tag: wasmTag
    },
    "'": StringConstantsProxy,
    'wasm:js-string': d2FzbTpqcy1zdHJpbmc,
};
    
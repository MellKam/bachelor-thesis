/** Exported memory */
export declare const memory: WebAssembly.Memory;
// Exported runtime interface
export declare function __new(size: number, id: number): number;
export declare function __pin(ptr: number): number;
export declare function __unpin(ptr: number): void;
export declare function __collect(): void;
export declare const __rtti_base: number;
/**
 * main/analyse
 * @param text `~lib/string/String`
 * @returns `main/Stats`
 */
export declare function analyse(text: string): __Record4<never>;
/** main/Stats */
declare interface __Record4<TOmittable> {
  /** @type `u32` */
  words: number | TOmittable;
  /** @type `u32` */
  bytes: number | TOmittable;
  /** @type `~lib/string/String` */
  longest: string;
}

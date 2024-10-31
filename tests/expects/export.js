//// [tests/cases/export.ts] ////

//// [export.ts]
export * from '.';
export { a } from '.';
export { a as b } from '.';
export { a as b, c } from '.';
export const a = 1;
export let b = 1;
export var c = 1;
export function a() {}
export async function b() {}


//// [export.js]
export * from '.';
export {a} from '.';
export {a} from '.';
export {a, c} from '.';
export const a = 1;
export let b = 1;
export var c = 1;
export function a () {}
export async function b () {}


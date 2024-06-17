//// [tests/cases/compiler/logicals.ts] ////

//// [logicals.ts]
const a = 1 && 2;
const b = 1 || 2;
const c = b == a || b != a;
const d = b == a && b != a;
const e = b == a || b != a && b == a;
const f = b == a && b != a || b == a;
const g = b == a && b != a || b == a && b != a;
const h = b == a && b != a || b == a && b != a || b == a;
const i = b == a && b != a || b == a && b != a || b == a && b != a;
const j = b == a && b != a || b == a && b != a || b == a && b != a || b == a;
const k = b == a && b != a || b == a && b != a || b == a && b != a || b == a && b != a;
const l = b == a && b != a || b == a && b != a || b == a && b != a || b == a && b != a || b == a;
const m = a > b;
const n = a < b;
const o = a >= b;
const p = a <= b;
const q = a >= b && a <= b;
const r = a >= b || a <= b;
const s = a >= b && a <= b || a >= b || a <= b;
const t = !a;
const u = a && !b;
const v = !(a || b);

//// [logicals.js]
const a = 1 && 2;
const b = 1 || 2;
const c = b == a || b != a;
const d = b == a && b != a;
const e = b == a || b != a && b == a;
const f = b == a && b != a || b == a;
const g = b == a && b != a || b == a && b != a;
const h = b == a && b != a || b == a && b != a || b == a;
const i = b == a && b != a || b == a && b != a || b == a && b != a;
const j = b == a && b != a || b == a && b != a || b == a && b != a || b == a;
const k = b == a && b != a || b == a && b != a || b == a && b != a || b == a && b != a;
const l = b == a && b != a || b == a && b != a || b == a && b != a || b == a && b != a || b == a;
const m = a > b;
const n = a < b;
const o = a >= b;
const p = a <= b;
const q = a >= b && a <= b;
const r = a >= b || a <= b;
const s = a >= b && a <= b || a >= b || a <= b;
const t = !a;
const u = a && !b;
const v = !(a || b);

//// [tests/cases/assignments.ts] ////

//// [assignments.ts]
const x = 123;
const y = 1_23_23;
const z = "string";
const w = 'another string';
const a = true;
const b = false;
const c = null;
const d = undefined;
const e = {
    a: 1,
    b: 2,
};
const f = [1, 2, 3];

const aa: number = 1;
const bb: string = "string";
const cc: boolean = true;
const dd: null = null;
const ee: undefined = undefined;

let aaa = aa;
let bbb = bb;
let ccc = cc;
let ddd = dd;
let eee = ee;

aaa = 123;
bbb = "string";
ccc = true;
ddd = null;
eee = undefined;

aaa += 1;
aaa -= 1;
aaa *= 1;
aaa /= 1;
aaa %= 1;
aaa **= 1;
aaa <<= 1;
aaa >>= 1;
aaa >>>= 1;

bbb += "string";
bbb -= "string";
bbb *= "string";
bbb /= "string";
bbb %= "string";

ccc += true;
ccc -= true;
ccc *= true;
ccc /= true;
ccc %= true;

ddd += null;
ddd -= null;
ddd *= null;
ddd /= null;
ddd %= null;

eee += undefined;
eee -= undefined;
eee *= undefined;
eee /= undefined;
eee %= undefined;

//// [assignments.js]
const x = 123;
const y = 1_23_23;
const z = "string";
const w = 'another string';
const a = true;
const b = false;
const c = null;
const d = undefined;
const e = {
    a:1,
    b:2
};
const f = [1, 2, 3];
const aa = 1;
const bb = "string";
const cc = true;
const dd = null;
const ee = undefined;
let aaa = aa;
let bbb = bb;
let ccc = cc;
let ddd = dd;
let eee = ee;
aaa=123;
bbb="string";
ccc=true;
ddd=null;
eee=undefined;
aaa+=1;
aaa-=1;
aaa*=1;
aaa/=1;
aaa%=1;
aaa**=1;
aaa<<=1;
aaa>>=1;
aaa>>>=1;
bbb+="string";
bbb-="string";
bbb*="string";
bbb/="string";
bbb%="string";
ccc+=true;
ccc-=true;
ccc*=true;
ccc/=true;
ccc%=true;
ddd+=null;
ddd-=null;
ddd*=null;
ddd/=null;
ddd%=null;
eee+=undefined;
eee-=undefined;
eee*=undefined;
eee/=undefined;
eee%=undefined;


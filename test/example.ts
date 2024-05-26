import fs, {writeFile} from 'fs';

"use strict";
// comment
const n = 123_456_789;
const s = 'hello world';

const x: 123 = 1, y: bigint = 2;

const z: Number = x + y;
const zz: Array<number> = [1,2,23];

const c: number;

console.log(n, s);

if (n == 123_456_789) {
    console.log('true');
} else {
    console.log('false');
}

switch (n) {
    case 123_456_789:
        console.log('case 1');
        break;
    case 123_456_789:
        console.log('case 2');
        break;
    default:
        console.log('default');
}

for (let i = 0; i < 10; i++) {
    console.log(i);
}

while (true) {
    console.log('while');
}

do {
    console.log('do');
} while (true);

try {
    console.log('try');
} catch (e) {
    console.log('catch');
} finally {
    console.log('finally');
}

function fn(param1, param2) {
    const hello = 'hello world'; // comment2
    const x = /*multilineinside*/{a: 1, b: 2};
    {a: 1};
    [1,2,3];
    const y = [1,2][0];
    y = 1 == 2;
    x.a = 1;
    console.log(hello + ' 123');

    const obj = {
        true: 1,
        false: 2,
        null: 3,
        undefined: 4,
        123: 5,
        'hello': 6,
    };
}

fn(2, 3);
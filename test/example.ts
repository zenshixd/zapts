import * as fs from 'fs';

const n = 123_456_789;
const s = 'hello world';

console.log(n, s);

function fn(param1, param2) {
    const hello = 'hello world';
    const x = {a: 1, b: 2};
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
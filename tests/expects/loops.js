//// [tests/cases/loops.ts] ////

//// [loops.ts]
for(var i = 0; i < 10; i++) {
    i;
}

for(let i = 0; i < 10; i++) {
    i;
}

for (const i = 0; i < 10; i++) {
    i;
}

let x = 0;
for (x = 0; x < 10; x++) {
    x;
}

for (const x of [1, 2, 3]) {
    x;
}

for (let x of [1, 2, 3]) {
    x;
}

for (var xx of [1, 2, 3]) {
    xx;
}

for (let y in [1, 2, 3]) {
    y;
}

for (var yy in [1, 2, 3]) {
    yy;
}

for (const y in [1, 2, 3]) {
    y;
}

while (x > 0) {
    x;
}

while (true) {
    x;
}

while (x > 0) x = 1;

do console.log(x); while (x > 0);

do {
    x;
} while (x > 0);


//// [loops.js]
for (var i = 0; i<10; i++) {
    i;
}
for (let i = 0; i<10; i++) {
    i;
}
for (const i = 0; i<10; i++) {
    i;
}
let x = 0;
for (x=0; x<10; x++) {
    x;
}
for (const x of [1, 2, 3]) {
    x;
}
for (let x of [1, 2, 3]) {
    x;
}
for (var xx of [1, 2, 3]) {
    xx;
}
for (let y in [1, 2, 3]) {
    y;
}
for (var yy in [1, 2, 3]) {
    yy;
}
for (const y in [1, 2, 3]) {
    y;
}
while (x>0) {
    x;
}
while (true) {
    x;
}
while (x>0) x=1
do console.log(x); while (x>0);
do {
    x;
} while (x>0);


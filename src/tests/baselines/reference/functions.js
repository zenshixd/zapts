//// [tests/cases/compiler/functions.ts] ////

//// [functions.ts]
async function foo() {
    console.log("foo");
}

function bar() {
    console.log("bar");
}

function foo(𝑚, 𝑀) {
    console.log(𝑀 + 𝑚);
}

function baz(x: string, y: number): void {
    console.log(x + y);
}


//// [functions.js]
async function foo() {
    console.log("foo");
}
function bar() {
    console.log("bar");
}
function foo(𝑚, 𝑀) {
    console.log(𝑀 + 𝑚);
}
function baz(x, y) {
    console.log(x + y);
}

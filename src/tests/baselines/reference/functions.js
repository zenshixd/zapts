//// [tests/compiler/cases/functions.ts] ////

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

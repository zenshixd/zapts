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

// const z: (string | undefined)[] = [];
declare const z: string[] = ['123'];

const zz = z.filter(x => true);

const x = () => console.log("x");
const y = (a: number, b: string) => console.log(a + b);
const z = name => console.log(name);
const xx = function (a: number, b: string) {
    type T = number;
    interface I {
        a: number;
        b: string;
    }
    console.log(a + b);
};

type T = {
    new(): void,
    abstract(),
    a(): void,
};
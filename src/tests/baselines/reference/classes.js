//// [tests/cases/compiler/classes.ts] ////

//// [classes.ts]
class A {
    a: number;
    b: string = "asd";

    // constructor(a: number, b: string) {
    //     this.a = a;
    //     this.b = b;
    // }

    get c() {
        console.log(1);
        // return this.a;
    }

    set d(a: number) {
        console.log(2);
        // this.a = a;
    }

    test() {
        console.log(3);
    }
}

class B {
    foo() {
        console.log(4);
    }

    async bar() {
        console.log(5);
    }

    *baz() {
        console.log(7);
    }

    async* qux() {
        console.log(6);
    }
}

//// [classes.js]
class A {
    a;
    b = "asd";
    get c() {
        console.log(1);
    }
    set d(a) {
        console.log(2);
    }
    test() {
        console.log(3);
    }

}
class B {
    foo() {
        console.log(4);
    }
    async bar() {
        console.log(5);
    }
    *baz() {
        console.log(7);
    }
    async *qux() {
        console.log(6);
    }

}

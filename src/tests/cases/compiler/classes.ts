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
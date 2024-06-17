//// [tests/cases/compiler/unary.ts] ////

//// [unary.ts]
let x = 0;
x++;
++x;
x--;
--x;
!x;
!!x;
~x;
~~x;
typeof x;
typeof typeof x;
typeof !x;
x instanceof Number;
x in [1, 2, 3];
delete x;
void x;

//// [unary.js]
let x = 0;
x++;
++x;
x--;
--x;
!x;
!!x;
~x;
~~x;
typeof x;
typeof typeof x;
typeof !x;
x instanceof Number;
x in [1, 2, 3];
delete x;
void x;

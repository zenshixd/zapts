//// [tests/compiler/cases/imports.ts] ////

//// [imports.ts]
import * as fs from "fs";
import fs from "fs";
import "node:fs";
import {readFile, writeFile} from "fs";
import fs, {readFileSync, writeFileSync} from "fs";
import fsd, * as fs from "fs";


//// [imports.js]
import * as fs from "fs";
import fs from "fs";
import "node:fs";
import {readFile, writeFile} from "fs";
import fs, {readFileSync, writeFileSync} from "fs";
import fsd, * as fs from "fs";

import { assertEquals } from "@std/assert";
import { dirname } from "node:path";
import {
  findFormatFunc,
  type FormatFunc,
  type FormatFuncResolver,
} from "./formatting.ts";

Deno.test("findFormatFunc checks resolvers in order for each directory", async () => {
  const checked: string[] = [];
  const expected: FormatFunc = async (_filePath, text) => text;
  const first: FormatFuncResolver = async (directoryPath) => {
    checked.push(`first:${directoryPath}`);
    return null;
  };
  const second: FormatFuncResolver = async (directoryPath) => {
    checked.push(`second:${directoryPath}`);
    return directoryPath === "/project" ? expected : null;
  };

  const actual = await findFormatFunc("/project/src/main.ts", [first, second]);

  assertEquals(actual, expected);
  assertEquals(checked, [
    "first:/project/src",
    "second:/project/src",
    "first:/project",
    "second:/project",
  ]);
  assertEquals(dirname("/project"), "/");
});

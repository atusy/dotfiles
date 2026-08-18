import { assertEquals, assertExists } from "@std/assert";
import { dirname, join } from "node:path";
import {
  findFormatFunc,
  type FormatFunc,
  type FormatFuncResolver,
  resolveFlakeTreefmt,
  resolveTreefmtToml,
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

Deno.test("resolveTreefmtToml selects a directory containing treefmt.toml", async () => {
  const directory = await Deno.makeTempDir();
  try {
    await Deno.writeTextFile(join(directory, "treefmt.toml"), "");

    assertExists(await resolveTreefmtToml(directory));
  } finally {
    await Deno.remove(directory, { recursive: true });
  }
});

Deno.test("resolveFlakeTreefmt selects a flake containing treefmt", async () => {
  const directory = await Deno.makeTempDir();
  try {
    await Deno.writeTextFile(
      join(directory, "flake.nix"),
      '{ inputs.treefmt-nix.url = "github:numtide/treefmt-nix"; }',
    );

    assertExists(await resolveFlakeTreefmt(directory));
  } finally {
    await Deno.remove(directory, { recursive: true });
  }
});

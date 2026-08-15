import { assertEquals } from "jsr:@std/assert@~1.0.14";
import type { ConfigArguments } from "jsr:@shougo/ddc-vim@~10.2.0/config";
import { cmdlineSources, Config } from "./init.ts";

Deno.test("every command type retains its isolated source order", () => {
  assertEquals(cmdlineSources, {
    ":": ["nvim-cmdline", "nvim-lsp-cmdline", "nvim-ex-command-history"],
    "@": ["nvim-input", "nvim-cmdline-history", "nvim-lsp-cmdline"],
    ">": ["nvim-input", "nvim-cmdline-history", "nvim-lsp-cmdline"],
    "/": ["nvim-lsp-cmdline"],
    "?": ["nvim-lsp-cmdline"],
    "-": ["nvim-lsp-cmdline"],
    "=": ["nvim-input"],
  });
});

Deno.test("gitcommit completion preserves tsudoi candidate priority", async () => {
  const filetypePatches: Array<[string, unknown]> = [];
  const args = {
    setAlias: () => {},
    contextBuilder: {
      patchGlobal: () => {},
      patchFiletype: (filetype: string, options: unknown) => {
        filetypePatches.push([filetype, options]);
      },
    },
  } as unknown as ConfigArguments;

  await new Config().config(args);

  assertEquals(filetypePatches, [[
    "gitcommit",
    {
      sourceOptions: {
        "nvim-lsp": { sorters: [] },
      },
    },
  ]]);
});

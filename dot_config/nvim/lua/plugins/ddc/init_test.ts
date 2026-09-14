import { assertEquals } from "jsr:@std/assert@~1.0.14";
import type { ConfigArguments } from "jsr:@shougo/ddc-vim@~10.2.0/config";
import { cmdlineSources, Config, skkeluaCompletePosition } from "./init.ts";

Deno.test("every command type retains its isolated source order", () => {
  assertEquals(cmdlineSources, {
    ":": ["nvim-lsp-cmdline", "nvim-cmdline", "nvim-ex-command-history"],
    "@": ["nvim-input", "nvim-cmdline-history", "nvim-lsp-cmdline"],
    ">": ["nvim-input", "nvim-cmdline-history", "nvim-lsp-cmdline"],
    "/": ["nvim-lsp-cmdline"],
    "?": ["nvim-lsp-cmdline"],
    "-": ["nvim-lsp-cmdline"],
    "=": ["nvim-input"],
  });
});

Deno.test("command-line LSP completion remains visible for its request timeout", async () => {
  const globalPatches: unknown[] = [];
  const args = {
    setAlias: () => {},
    contextBuilder: {
      patchGlobal: (options: unknown) => globalPatches.push(options),
      patchFiletype: () => {},
    },
  } as unknown as ConfigArguments;

  await new Config().config(args);

  const global = globalPatches[0] as {
    sourceOptions: Record<string, { hideTimeout?: number }>;
  };
  assertEquals(global.sourceOptions["nvim-lsp-cmdline"].hideTimeout, 1000);
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

  assertEquals(filetypePatches, [
    [
      "gitcommit",
      {
        sourceOptions: {
          "nvim-lsp": { sorters: [] },
        },
      },
    ],
  ]);
});

Deno.test("SKK sources keep kana-to-kanji candidates out of fuzzy filters", async () => {
  let global = {} as {
    sources: Array<
      {
        options: {
          matchers: string[];
          sorters: string[];
          converters: string[];
          hideTimeout: number;
        };
      }
    >;
    cmdlineSources: Record<string, typeof global.sources>;
    sourceParams: Record<string, { deniedServers: string[] }>;
  };
  const aliases: string[][] = [];
  await new Config().config({
    setAlias: (...args: string[]) => aliases.push(args),
    contextBuilder: {
      patchGlobal: (options: Record<string, unknown>) =>
        global = options as typeof global,
      patchFiletype: () => {},
    },
  } as unknown as ConfigArguments);
  assertEquals(aliases.slice(0, 2), [
    ["source", "skkelua", "nvim-lsp"],
    ["source", "skkelua-cmdline", "nvim-lsp-cmdline"],
  ]);
  for (
    const sources of [global.sources, ...Object.values(global.cmdlineSources)]
  ) {
    const skk = sources[0];
    assertEquals(skk.options.matchers, []);
    assertEquals(skk.options.sorters, []);
    assertEquals(skk.options.converters, []);
    assertEquals(skk.options.hideTimeout, 1000);
  }
  assertEquals(global.sourceParams["nvim-lsp"].deniedServers, ["skkelua"]);
});

Deno.test("SKK position follows pre-edit after Japanese text in either mode", async () => {
  for (const mode of ["i", "c"]) {
    for (
      const [prefix, preEdit] of [
        ["# たとえばこういう", "にほんご"],
        ["😀日本語", "▽かんじ"],
        ["echo ", "a.b"],
        ["", "😀かな"],
      ]
    ) {
      const denops = {
        call: () => Promise.resolve(preEdit),
      } as unknown as Parameters<typeof skkeluaCompletePosition>[0];
      const context = { input: prefix + preEdit, mode } as Parameters<
        typeof skkeluaCompletePosition
      >[1]["context"];
      assertEquals(
        await skkeluaCompletePosition(denops, { context }),
        prefix.length,
      );
      context.input = "stale";
      assertEquals(await skkeluaCompletePosition(denops, { context }), -1);
    }
  }
  assertEquals(
    await skkeluaCompletePosition(
      { call: () => Promise.resolve("") } as unknown as Parameters<
        typeof skkeluaCompletePosition
      >[0],
      {
        context: { input: "日本語" } as Parameters<
          typeof skkeluaCompletePosition
        >[1]["context"],
      },
    ),
    -1,
  );
});

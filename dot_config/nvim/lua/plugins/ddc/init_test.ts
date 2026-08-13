import { assertEquals } from "jsr:@std/assert@~1.0.14";
import { cmdlineSources } from "./init.ts";

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

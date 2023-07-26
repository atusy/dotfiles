import { BaseConfig } from "https://deno.land/x/ddc_vim@v3.9.0/types.ts";
import { ConfigArguments } from "https://deno.land/x/ddc_vim@v3.9.0/base/config.ts";

async function get_fpath() {
  const cmd = new Deno.Command("zsh", {
    args: ["-c", 'echo -n "$FPATH"'],
  });
  const output = await cmd.output();
  return (new TextDecoder()).decode(output.stdout);
}

export class Config extends BaseConfig {
  override async config(args: ConfigArguments): Promise<void> {

    args.contextBuilder.patchGlobal({
      ui: "pum",
      autoCompleteEvents: [
        "InsertEnter",
        "TextChangedI",
        "TextChangedP",
        "CmdlineEnter",
        "CmdlineChanged",
        // "TextChangedT",
      ],
      sources: ["nvim-lsp", "around", "file", "buffer", "skkeleton"],
      cmdlineSources: {
        ":": ["zsh", "cmdline", "cmdline-history", "around"],
        "@": ["input", "cmdline-history", "file", "around"],
        ">": ["input", "cmdline-history", "file", "around"],
        "/": ["around", "line"],
        "?": ["around", "line"],
        "-": ["around", "line"],
        "=": ["input"],
      },
      sourceOptions: {
        _: {
          ignoreCase: true,
          matchers: ["matcher_fuzzy"],
          sorters: ["sorter_fuzzy"],
          converters: ["converter_fuzzy"],
          timeout: 1000,
        },
        around: {
          mark: "A",
        },
        buffer: {
          mark: "B",
        },
        cmdline: {
          mark: "C",
          forceCompletionPattern: "\\S/\\S*|\\.\\w*",
        },
        "cmdline-history": {
          mark: "H",
          maxItems: 5,
          minAutoCompleteLength: 0,
          minKeywordLength: 2,
          sorters: [],
        },
        input: {
          mark: "input",
          forceCompletionPattern: "\\S/\\S*",
          isVolatile: true,
        },
        line: {
          mark: "line",
          matchers: ["matcher_vimregexp"],
          sorters: [],
        },
        "nvim-lsp": {
          mark: "L",
          forceCompletionPattern: "\\.\\w*|::\\w*|->\\w*",
          dup: "force",
        },
        file: {
          mark: "F",
          isVolatile: true,
          forceCompletionPattern: "\\S/\\S*",
        },
        zsh: {
          mark: "Z",
          isVolatile: true,
          minAutoCompleteLength: 0,
          minKeywordLength: 2,
        },
        skkeleton: {
          mark: "skk",
          matchers: ["skkeleton"],
          sorters: [],
          minAutoCompleteLength: 2,
          isVolatile: true,
        },
      },
      sourceParams: {
        around: { maxSize: 500 },
        buffer: {
          requireSameFiletype: false,
          limitBytes: 50000,
          fromAltBuf: true,
          forceCollect: true,
        },
        file: {
          filenameChars: "[:keyword:].",
        },
        "nvim-lsp": {
          enableResolveItem: true,
          enableAdditionalTextEdit: true,
        },
        zsh: { envs: { FPATH: await get_fpath() } },
      },
    });

    for (
      const filetype of ["sh", "bash", "zsh"]
    ) {
      args.contextBuilder.patchFiletype(filetype, {
        sources: ["nvim-lsp", "zsh", "around", "file", "buffer", "skkeleton"],
      });
    }
  }
}

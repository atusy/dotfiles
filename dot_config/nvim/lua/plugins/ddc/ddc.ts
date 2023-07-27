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
    ["zsh", "fish", "xonsh"].map((x) =>
      args.setAlias("source", x, "shell-native")
    );

    args.setAlias("filter", "converter_first_char", "converter_truncate_abbr");

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
      sources: [
        "nvim-lsp",
        "around",
        "file",
        "buffer",
        "skkeleton",
      ],
      cmdlineSources: {
        ":": ["fish", "zsh", "cmdline", "cmdline-history", "around"],
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
        around: { mark: "A" },
        buffer: { mark: "B" },
        cmdline: {
          mark: "CMD",
          forceCompletionPattern: "\\S/\\S*|\\.\\w*",
        },
        "cmdline-history": {
          mark: "HIST",
          maxItems: 5,
          minAutoCompleteLength: 0,
          minKeywordLength: 2,
          sorters: [],
        },
        input: {
          mark: "INPUT",
          forceCompletionPattern: "\\S/\\S*",
          isVolatile: true,
        },
        line: {
          mark: "LINE",
          matchers: ["matcher_vimregexp"],
          sorters: [],
          converters: ["converter_remove_overlap"],
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
        xonsh: {
          mark: "XONSH",
          isVolatile: true,
          minAutoCompleteLength: 0,
          minKeywordLength: 2,
        },
        fish: {
          mark: "FISH",
          isVolatile: true,
          minAutoCompleteLength: 0,
          minKeywordLength: 2,
        },
        zsh: {
          mark: "ZSH",
          isVolatile: true,
          minAutoCompleteLength: 0,
          minKeywordLength: 2,
        },
        skkeleton: {
          mark: "SKK",
          matchers: ["skkeleton"],
          sorters: [],
          converters: [],
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
        fish: {
          shell: "fish",
          envs: {
            COLUMNS: "200", // to get more preview info
          },
        },
        zsh: {
          shell: "zsh",
          envs: {
            FPATH: await get_fpath(),
            COLUMNS: "200", // to get more preview info
          },
        },
        xonsh: {
          shell: "xonsh",
          envs: {
            COLUMNS: "200", // to get more preview info
          },
        },
      },
    });

    [["sh", "zsh"], ["bash", "zsh"], ["zsh"], ["fish"], ["xonsh"]].map(
      (x) =>
        args.contextBuilder.patchFiletype(x[0], {
          sources: [
            "nvim-lsp",
            x[1] ?? x[0],
            "around",
            "file",
            "buffer",
            "skkeleton",
          ],
        }),
    );
  }
}

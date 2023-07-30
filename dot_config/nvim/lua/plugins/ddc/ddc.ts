import { BaseConfig } from "https://deno.land/x/ddc_vim@v3.9.0/types.ts";
import { ConfigArguments } from "https://deno.land/x/ddc_vim@v3.9.0/base/config.ts";
import { join } from "https://deno.land/std@0.196.0/path/mod.ts";

async function get_fpath() {
  const cmd = new Deno.Command("zsh", {
    args: ["-c", 'echo -n "$FPATH"'],
  });
  const output = await cmd.output();
  return (new TextDecoder()).decode(output.stdout);
}

export class Config extends BaseConfig {
  override async config(args: ConfigArguments): Promise<void> {
    const lazyroot = await args.denops.call(
      "luaeval",
      `require("lazy.core.config").options.root`,
    ) as string;

    const sources = [
      "nvim-lsp",
      "around",
      "file",
      "buffer",
      "skkeleton",
      "dictionary",
    ];

    ["zsh", "fish", "xonsh"].map((x) =>
      args.setAlias("source", x, "shell-native")
    );
    args.setAlias("filter", "matcher_head_dictionary", "matcher_head");

    args.contextBuilder.patchGlobal({
      ui: "pum",
      backspaceCompletion: true, // NOTE: manual mentions occasional flickers
      autoCompleteEvents: [
        "InsertEnter",
        "TextChangedI",
        "TextChangedP",
        "CmdlineEnter",
        "CmdlineChanged",
        // "TextChangedT",
      ],
      sources: sources,
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
        dictionary: {
          mark: "Dict",
          matchers: ["matcher_head_dictionary", "matcher_editdistance"],
          sorters: [], // sorted by matcher_editdistance
          converters: ["converter_fuzzy", "converter_dictionary"],
          isVolatile: true,
          maxItems: 30,
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
          matchers: ["matcher_head"],
          sorters: [],
          converters: [],
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
          // forceCompletionPattern: "\\.\\w*|::\\w*|->\\w*", // NOTE: some LSPs (denols) fails to suggest methods/fields
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
        dictionary: {
          showMenu: false,
          smartCase: false,
          dictPaths: [join(lazyroot, "english-words/words_alpha.txt")],
        },
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
      filterParams: {
        matcher_head_dictionary: {
          maxMatchLength: 1,
        },
        converter_dictionary: {
          dicts: [
            "kantan-ej-dictionary/kantan-ej-dictionary.json",
            "WebstersEnglishDictionary/dictionary.json",
          ].map((x) => join(lazyroot, x)),
        },
      },
    });

    const shellSources = ["fish", "zsh", "xonsh", ...sources];
    ["sh", "bash", "fish", "xonsh", "zsh"].map(
      (x) => args.contextBuilder.patchFiletype(x[0], { sources: shellSources }),
    );
  }
}

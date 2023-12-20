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
      "lsp",
      "file",
      "around",
      "buffer",
      "skkeleton",
      "dictionary",
    ];

    ["zsh", "fish", "xonsh"].map((x) =>
      args.setAlias("source", x, "shell-native")
    );
    args.setAlias("source", "shell_history", "dictionary");
    args.setAlias("source", "ex_command_history", "cmdline-history");
    args.setAlias("source", "ex_command_history_cmd", "cmdline-history");
    args.setAlias("filter", "matcher_head_dictionary", "matcher_head");
    args.setAlias("filter", "matcher_head_shell_history", "matcher_head");
    args.setAlias("filter", "converter_ex_command", "converter_string_match");

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
        ":": [
          "ex_command_history_cmd",
          "fish",
          "zsh",
          "xonsh",
          "cmdline",
          "ex_command_history",
          "shell_history",
          "around",
        ],
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
          converters: ["converter_fuzzy", "converter_dictionary"],
        },
        buffer: {
          mark: "B",
          converters: ["converter_fuzzy", "converter_dictionary"],
        },
        cmdline: {
          mark: "CMD",
          forceCompletionPattern: "\\S/\\S*|\\.\\w*",
        },
        dictionary: {
          mark: "Dict",
          matchers: ["matcher_head_dictionary", "matcher_fuzzy"],
          converters: ["converter_fuzzy", "converter_dictionary"],
          isVolatile: true,
          keywordPattern: "[a-zA-Z]+",
          maxItems: 30,
        },
        file: {
          mark: "F",
          isVolatile: true,
          forceCompletionPattern: "\\S/\\S*",
        },
        "cmdline-history": {
          mark: "HIST",
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
        "lsp": {
          mark: "L",
          forceCompletionPattern: "\\.\\w*|::\\w*|->\\w*",
          dup: "force",
        },
        "shell_history": {
          mark: "HIST_SH",
          matchers: ["matcher_head_dictionary", "matcher_fuzzy"],
          keywordPattern: "[^! ].*",
        },
        skkeleton: {
          mark: "SKK",
          matchers: ["skkeleton"],
          sorters: [],
          converters: [],
          minAutoCompleteLength: 2,
          isVolatile: true,
        },

        // aliases
        "ex_command_history_cmd": {
          mark: "RECENT",
          minAutoCompleteLength: 0,
          matchers: ["matcher_head"],
          sorters: [],
          converters: ["converter_ex_command"],
          enabledIf: "getcmdline() =~# ' ' ? v:false : v:true",
        },
        "ex_command_history": {
          mark: "HIST",
          minAutoCompleteLength: 0,
          matchers: ["matcher_head"],
          sorters: [],
          converters: [],
        },
        xonsh: {
          mark: "XONSH",
          isVolatile: true,
          minAutoCompleteLength: 0,
          minKeywordLength: 0,
        },
        fish: {
          mark: "FISH",
          isVolatile: true,
          minAutoCompleteLength: 0,
          minKeywordLength: 0,
        },
        zsh: {
          mark: "ZSH",
          isVolatile: true,
          minAutoCompleteLength: 0,
          minKeywordLength: 0,
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
        dictionary: {
          showMenu: false,
          smartCase: false,
          dictPaths: [join(lazyroot, "english-words/words_alpha.txt")],
        },
        file: {
          filenameChars: "[:keyword:].",
        },
        "lsp": {
          enableResolveItem: true,
          enableAdditionalTextEdit: true,
          confirmBehavior: "replace",
        },
        "shell_history": {
          showMenu: false,
          smartCase: false,
          dictPaths: ["/home/atusy/.zsh_history"],
        },

        // aliases
        fish: {
          shell: "fish",
          envs: {
            DDCVIM: "1",
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
        // matcher
        matcher_head_dictionary: {
          maxMatchLength: 1,
        },
        matcher_head_shell_history: {
          maxMatchLength: 2,
        },
        // converter
        converter_dictionary: {
          dicts: [
            "kantan-ej-dictionary/kantan-ej-dictionary.json",
            "WebstersEnglishDictionary/dictionary.json",
          ].map((x) => join(lazyroot, x)),
        },
        converter_ex_command: {
          regexp: "[^ ]*[^ !]",
          convertAbbr: true,
        },
      },
    });

    const shellSources = ["fish", "zsh", "xonsh"]; // avoid shell_history as it can be too noisy
    ["sh", "bash", "fish", "xonsh", "zsh"].map(
      (x) => args.contextBuilder.patchFiletype(x, { sources: shellSources }),
    );
  }
}

import {
  BaseConfig,
  type ConfigArguments,
} from "jsr:@shougo/ddc-vim@~9.4.0/config";
import { join } from "jsr:@std/path@~1.0.0/join";

async function get_fpath() {
  const cmd = new Deno.Command("zsh", {
    args: ["-c", 'echo -n "$FPATH"'],
  });
  const output = await cmd.output();
  return new TextDecoder().decode(output.stdout);
}

const makeSources = (sources: string[]) => {
  return [
    "denippet",
    "copilot",
    "lsp",
    ...sources,
    "file",
    "around",
    "buffer",
    "dictionary",
  ];
};

export class Config extends BaseConfig {
  override async config(args: ConfigArguments): Promise<void> {
    const lazyroot = (await args.denops.call(
      "luaeval",
      `require("lazy.core.config").options.root`,
    )) as string;
    const stddata = (await args.denops.call("stdpath", "data")) as string;

    const sources = makeSources([]);
    ["sh", "bash", "zsh"].map((x) =>
      args.contextBuilder.patchFiletype(x, { sources: makeSources(["zsh"]) })
    );
    args.contextBuilder.patchFiletype("fish", {
      sources: makeSources(["fish"]),
    });
    args.contextBuilder.patchFiletype("xonsh", {
      sources: makeSources(["xonsh"]),
    });

    ["zsh", "fish", "xonsh"].map((x) =>
      args.setAlias("source", x, "shell_native")
    );
    args.setAlias("source", "shell_history", "dictionary");
    args.setAlias("source", "ex_command_history", "cmdline_history");
    args.setAlias("source", "ex_command_history_cmd", "cmdline_history");
    args.setAlias("filter", "matcher_head_dictionary", "matcher_head");
    args.setAlias("filter", "matcher_head_shell_history", "matcher_head");
    args.setAlias("filter", "matcher_word", "matcher_string_match");
    args.setAlias("filter", "converter_ex_command", "converter_string_match");
    args.setAlias("filter", "converter_word", "converter_string_match");

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
          // "xonsh",
          "cmdline",
          "ex_command_history",
          // "shell_history",
          "around",
        ],
        "@": ["input", "cmdline_history", "file", "around"],
        ">": ["input", "cmdline_history", "file", "around"],
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
          converters: [
            "converter_fuzzy",
            "converter_dictionary",
            "converter_truncate_abbr",
          ],
        },
        buffer: {
          mark: "B",
          converters: [
            "converter_fuzzy",
            "converter_dictionary",
            "converter_truncate_abbr",
          ],
        },
        cmdline: {
          mark: "CMD",
          forceCompletionPattern: "\\S/\\S*|\\.\\w*",
          isVolatile: true,
          minAutoCompleteLength: 0,
        },
        copilot: {
          mark: "AI",
          isVolatile: true,
          minAutoCompleteLength: 0,
          matchers: ["matcher_word"],
          converters: ["converter_word"],
        },
        denippet: {
          mark: "S",
          matchers: ["matcher_head"],
          // matchers: ["matcher_head_dictionary", "matcher_fuzzy"],
          // matchers: ["matcher_fuzzy"],
          minKeywordLength: 1,
          minAutoCompleteLength: 1,
          keywordPattern: ";[a-zA-Z0-9]*",
        },
        dictionary: {
          mark: "Dict",
          matchers: ["matcher_fuzzy"],
          converters: ["converter_fuzzy", "converter_dictionary"],
          keywordPattern: "[a-zA-Z]+",
        },
        file: {
          mark: "F",
          isVolatile: true,
          forceCompletionPattern: "\\S/\\S*",
        },
        cmdline_history: {
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
          replaceSourceInputPattern: "[^/]*$", // do not remove slash so that file completion works
        },
        line: {
          mark: "LINE",
          matchers: ["matcher_vimregexp"],
          sorters: [],
          converters: ["converter_remove_overlap", "converter_truncate_abbr"],
        },
        lsp: {
          mark: "L",
          forceCompletionPattern: "\\.\\w*|::\\w*|->\\w*",
          dup: "force",
        },
        shell_history: {
          mark: "HIST_SH",
          matchers: ["matcher_head"],
          keywordPattern: "[^! ].*",
        },
        skkeleton: {
          mark: "SKK",
          matchers: [],
          sorters: [],
          converters: [],
          minAutoCompleteLength: 2,
          isVolatile: true,
        },

        // aliases
        ex_command_history_cmd: {
          mark: "RECENT",
          minAutoCompleteLength: 0,
          matchers: ["matcher_head"],
          sorters: [],
          converters: ["converter_ex_command"],
          enabledIf: "getcmdline() =~# ' ' ? v:false : v:true",
        },
        ex_command_history: {
          mark: "HIST",
          minAutoCompleteLength: 0,
          matchers: ["matcher_head"],
          sorters: [],
          converters: ["converter_truncate_abbr"],
        },
        xonsh: {
          mark: "XONSH",
          isVolatile: true,
          minAutoCompleteLength: 1,
          minKeywordLength: 0,
        },
        fish: {
          mark: "FISH",
          isVolatile: true,
          minAutoCompleteLength: 1,
          minKeywordLength: 0,
        },
        zsh: {
          mark: "ZSH",
          isVolatile: true,
          minAutoCompleteLength: 1,
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
        copilot: { copilot: "lua" },
        dictionary: {
          exactLength: 2,
          firstCaseInsensitive: true,
          paths: [join(lazyroot, "english-words/words_alpha.txt")],
          databasePath: join(stddata, "ddc", "dictionary", "base.sqlite3"),
        },
        file: {
          filenameChars: "[:keyword:].",
        },
        lsp: {
          enableResolveItem: true,
          enableAdditionalTextEdit: true,
          confirmBehavior: "replace",
        },
        shell_history: {
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
        converter_word: {
          regexp: "^[a-zA-Z0-9_]+",
          convertAbbr: true,
        },
        matcher_word: {
          regexp: "^[a-zA-Z0-9_]+",
        },
      },
    });
  }
}

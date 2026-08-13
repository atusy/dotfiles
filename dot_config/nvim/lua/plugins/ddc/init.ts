import {
  BaseConfig,
  type ConfigArguments,
} from "jsr:@shougo/ddc-vim@~10.2.0/config";
import { join } from "jsr:@std/path@~1.0.0/join";

async function get_fpath() {
  const cmd = new Deno.Command("zsh", {
    args: ["-c", 'echo -n "$FPATH"'],
  });
  const output = await cmd.output();
  return new TextDecoder().decode(output.stdout);
}

const makeSources = (sources: string[]) => {
  return ["lsp", ...sources, "dictionary"];
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
      args.contextBuilder.patchFiletype(x, { sources: makeSources(["zsh"]) }),
    );
    args.contextBuilder.patchFiletype("fish", {
      sources: makeSources(["fish"]),
    });

    ["zsh", "fish"].map((x) => args.setAlias("source", x, "shell_native"));
    args.setAlias("source", "shell_history", "dictionary");
    args.setAlias("source", "ex_command_history", "cmdline_history");
    args.setAlias("filter", "matcher_head_initial", "matcher_head");
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
          "fish",
          "zsh",
          "cmdline",
          "ex_command_history",
          // "shell_history",
          "around",
        ],
        "@": ["input", "cmdline_history", "file", "around"],
        ">": ["input", "cmdline_history", "file", "around"],
        "/": ["around"],
        "?": ["around"],
        "-": ["around"],
        "=": ["input"],
      },
      sourceOptions: {
        _: {
          ignoreCase: true,
          keywordPattern:
            "[[:keyword:]\\u3040-\\u309f\\u30a0-\\u30ff\\u4e00-\\u9fff\\uff66-\\uff9f]*",
          matchers: ["matcher_fuzzy"],
          sorters: ["sorter_fuzzy"],
          converters: ["converter_fuzzy"],
          timeout: 1000,
        },
        cmdline: {
          mark: "CMD",
          forceCompletionPattern: "\\S/\\S*|\\.\\w*",
          isVolatile: true,
          minAutoCompleteLength: 0,
        },
        dictionary: {
          mark: "Dict",
          matchers: ["matcher_head_initial", "matcher_fuzzy"],
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
        "lsp-cmdline": {
          mark: "L",
          forceCompletionPattern: "(\\.|::|->|/)\\w*",
          dup: "force",
          isVolatile: true,
          volatilePattern: "[p{P}p{S}]",
        },
        lsp: {
          mark: "L",
          forceCompletionPattern: "(\\.|::|->|/)\\w*",
          dup: "force",
          isVolatile: true,
          volatilePattern: "[p{P}p{S}]",
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
        ex_command_history: {
          mark: "HIST",
          minAutoCompleteLength: 0,
          matchers: ["matcher_head"],
          sorters: [],
          converters: ["converter_truncate_abbr"],
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
        dictionary: {
          exactLength: 2,
          firstCaseInsensitive: true,
          paths: [join(lazyroot, "english-words/words_alpha.txt")],
          databasePath: join(stddata, "ddc", "dictionary", "base.sqlite3"),
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
      },
      filterParams: {
        // matcher
        matcher_head_initial: {
          maxMatchLength: 1,
        },
        // converter
        converter_dictionary: {
          dicts: [
            "kantan-ej-dictionary/kantan-ej-dictionary.json",
            "WebstersEnglishDictionary/dictionary.json",
          ].map((x) => join(lazyroot, x)),
        },
      },
    });
  }
}

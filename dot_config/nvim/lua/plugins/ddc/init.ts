import {
  BaseConfig,
  type ConfigArguments,
} from "jsr:@shougo/ddc-vim@~10.2.0/config";

export class Config extends BaseConfig {
  override config(args: ConfigArguments): Promise<void> {
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
      sources: ["nvim-lsp"],
      cmdlineSources: {
        ":": ["cmdline", "lsp-cmdline", "ex_command_history"],
        "@": ["input", "cmdline_history", "lsp-cmdline"],
        ">": ["input", "cmdline_history", "lsp-cmdline"],
        "/": ["lsp-cmdline"],
        "?": ["lsp-cmdline"],
        "-": ["lsp-cmdline"],
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
        "nvim-lsp": {
          mark: "L",
          forceCompletionPattern: "(\\.|::|->|/)\\w*",
          dup: "force",
          isVolatile: true,
          volatilePattern: "[p{P}p{S}]",
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
      },
      sourceParams: {
        "nvim-lsp": {
          enableResolveItem: true,
          enableAdditionalTextEdit: true,
          confirmBehavior: "replace",
        },
      },
      filterParams: {
        // matcher
        matcher_head_initial: {
          maxMatchLength: 1,
        },
      },
    });
    return Promise.resolve();
  }
}

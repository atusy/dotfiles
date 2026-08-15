import {
  BaseConfig,
  type ConfigArguments,
} from "jsr:@shougo/ddc-vim@~10.2.0/config";

export const cmdlineSources = {
  ":": ["nvim-cmdline", "nvim-lsp-cmdline", "nvim-ex-command-history"],
  "@": ["nvim-input", "nvim-cmdline-history", "nvim-lsp-cmdline"],
  ">": ["nvim-input", "nvim-cmdline-history", "nvim-lsp-cmdline"],
  "/": ["nvim-lsp-cmdline"],
  "?": ["nvim-lsp-cmdline"],
  "-": ["nvim-lsp-cmdline"],
  "=": ["nvim-input"],
};

export class Config extends BaseConfig {
  override config(args: ConfigArguments): Promise<void> {
    args.setAlias("source", "nvim-input", "nvim-lsp-cmdline");
    args.setAlias("source", "nvim-cmdline-history", "nvim-lsp-cmdline");
    args.setAlias("source", "nvim-ex-command-history", "nvim-lsp-cmdline");
    args.setAlias("source", "nvim-cmdline", "nvim-lsp-cmdline");
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
      cmdlineSources,
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
        "nvim-cmdline": {
          mark: "CMD",
          forceCompletionPattern: "\\S/\\S*|\\.\\w*",
          isVolatile: true,
          minAutoCompleteLength: 0,
        },
        "nvim-cmdline-history": {
          mark: "HIST",
          minAutoCompleteLength: 0,
          minKeywordLength: 2,
          matchers: ["matcher_head"],
          sorters: [],
          converters: [],
        },
        "nvim-input": {
          mark: "INPUT",
          forceCompletionPattern: "\\S/\\S*",
          isVolatile: true,
          replaceSourceInputPattern: "[^/]*$", // do not remove slash so that file completion works
        },
        "nvim-lsp-cmdline": {
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
        "nvim-ex-command-history": {
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
        "nvim-lsp-cmdline": {
          allowedServers: ["kakehashi"],
        },
        "nvim-input": {
          languageId: "ddc_input",
          allowedServers: ["nvim-input"],
          completePosition: "head",
        },
        "nvim-cmdline-history": {
          languageId: "ddc_cmdline_history",
          allowedServers: ["nvim-cmdline-history"],
        },
        "nvim-cmdline": {
          languageId: "ddc_cmdline",
          allowedServers: ["nvim-cmdline"],
          enableHelpPreview: true,
        },
        "nvim-ex-command-history": {
          languageId: "ddc_cmdline_history",
          allowedServers: ["nvim-cmdline-history"],
        },
      },
      filterParams: {
        // matcher
        matcher_head_initial: {
          maxMatchLength: 1,
        },
      },
    });
    args.contextBuilder.patchFiletype("gitcommit", {
      sourceOptions: {
        "nvim-lsp": {
          sorters: [],
        },
      },
    });
    return Promise.resolve();
  }
}

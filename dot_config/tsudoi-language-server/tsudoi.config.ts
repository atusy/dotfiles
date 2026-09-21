// Tsudoi configuration to be run on Deno
// Unpublished packages are resolved through deno.json's import map.

import { useDictionaryCompletion } from "@atusy/tsudoi-completion-dictionary";
import {
  completeAround,
  completeCorpus,
  segmentScanner,
} from "@atusy/tsudoi-completion-document";
import { completePath, resolvePathStat } from "@atusy/tsudoi-completion-path";
import { hoverWordnet } from "@atusy/tsudoi-hover-wordnet";
import type { TsudoiConfigFactory } from "@atusy/tsudoi-language-server/types";
import { useMyShellCompletion } from "./completion-my-shell.ts";
import { formatDocument } from "./formatting.ts";
import { completeEmoji } from "./completion-emoji.ts";
import { completeGitCommit } from "./completion-git.ts";
import {
  handleKakehashiBridgeRouting,
  initalizeKakehashiBridgeRouting,
} from "./kakehashi-bridge-routing.ts";

const minQueryLengths = {
  shell: 0,
  path: 1,
  around: 0,
  corpus: 0,
  dictionary: 2,
} as const;
const maxMinQueryLength = Math.max(...Object.values(minQueryLengths));

const config: TsudoiConfigFactory = async () => {
  const scanner = segmentScanner("ja"); // build outside handler for memoization
  const completeMyShell = useMyShellCompletion();
  const completeDictionary = await useDictionaryCompletion({
    files: [
      "/Users/atusy/.local/share/nvim/lazy/english-words/words_alpha.txt",
    ],
  });

  return {
    methods: {
      initialize: (context) => {
        return Promise.resolve(
          initalizeKakehashiBridgeRouting(context.preparedResult),
        );
      },
      "textDocument/completion": async function* (context, params) {
        const document = context.tsudoi.documents.get(params.textDocument.uri);
        yield* completeMyShell(context, params, {
          maxItems: 2000,
          minQueryLength: minQueryLengths.shell,
        });
        if (document?.languageId === "gitcommit") {
          yield* completeGitCommit(context, params);
        }
        yield* completeEmoji(context, params);
        yield* completePath(context, params, {
          minQueryLength: minQueryLengths.path,
        });
        yield* completeAround(context, params, {
          maxLines: 500,
          scanner,
          minQueryLength: minQueryLengths.around,
        });
        yield* completeCorpus(context, params, {
          scanner,
          maxItems: 2000,
          minQueryLength: minQueryLengths.corpus,
        });
        yield* completeDictionary(context, params, {
          maxItems: 2000,
          minQueryLength: minQueryLengths.dictionary,
        });

        const line = document?.getText().split(/\r?\n/)[params.position.line] ??
          "";
        const beforeCursor = line.slice(0, params.position.character);
        const query = /\S*$/u.exec(beforeCursor)?.[0] ?? "";
        return { items: [], isIncomplete: query.length < maxMinQueryLength };
      },
      "textDocument/hover": hoverWordnet,
      "textDocument/formatting": formatDocument,
      "completionItem/resolve": resolvePathStat,
    },
    customMethods: {
      "kakehashi/bridge/routing": handleKakehashiBridgeRouting,
    },
  };
};

export default config;

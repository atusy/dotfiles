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
import { useMyShellCompletion } from "./complete-my-shell.ts";
import { formatDocument } from "./formatting.ts";
import { completeGitCommit } from "./completion-git.ts";
import {
  advertiseHandleKakehashiBridgeRoutingCapability,
  handleKakehashiBridgeRouting,
} from "./kakehashi-bridge-routing.ts";

const config: TsudoiConfigFactory = async () => {
  const scanner = segmentScanner("ja"); // build outside handler for memoization
  const completeMyShell = useMyShellCompletion();
  const completeDictionary = await useDictionaryCompletion({
    files: ["/Users/atusy/.local/share/nvim/lazy/english-words/words_alpha.txt"],
  });

  return {
    methods: {
      initialize: (context) => {
        return Promise.resolve(
          advertiseHandleKakehashiBridgeRoutingCapability(
            context.preparedResult,
          ),
        );
      },
      "textDocument/completion": async function* (context, params) {
        const document = context.tsudoi.documents.get(params.textDocument.uri);
        yield* completeMyShell(context, params);
        if (document?.languageId === "gitcommit") {
          yield* completeGitCommit(context, params);
        }
        yield* completePath(context, params);
        yield* completeAround(context, params, { maxLines: 500, scanner });
        yield* completeCorpus(context, params, { scanner, maxItems: 2000 });
        yield* completeDictionary(context, params, { maxItems: 2000 });
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

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
import type {
  CustomRequestHandler,
  TsudoiConfigFactory,
} from "@atusy/tsudoi-language-server/types";
import { useMyShellCompletion } from "./complete-my-shell.ts";
import { formatDocument } from "./formatting.ts";
import { completeGitCommit } from "./completion-git.ts";
import { isRoutingParams, routeTypeScript } from "./routing.ts";

function record(value: unknown): Readonly<Record<string, unknown>> {
  return typeof value === "object" && value !== null
    ? (value as Readonly<Record<string, unknown>>)
    : {};
}

const bridgeRouting: CustomRequestHandler = async (_context, params) => ({
  result: isRoutingParams(params) ? await routeTypeScript(params) : null,
});

const completeMyShell = useMyShellCompletion();

const completeDictionary = await useDictionaryCompletion({
  files: ["/Users/atusy/.local/share/nvim/lazy/english-words/words_alpha.txt"],
});

const config: TsudoiConfigFactory = () => {
  const scanner = segmentScanner("ja"); // build outside handler to stabilize memoization of complete functions
  return Promise.resolve({
    methods: {
      initialize: (context) => {
        const experimental = record(
          context.preparedResult.capabilities.experimental,
        );
        return Promise.resolve({
          ...context.preparedResult,
          capabilities: {
            ...context.preparedResult.capabilities,
            experimental: {
              ...experimental,
              kakehashi: {
                ...record(experimental.kakehashi),
                bridgeRouting: true,
              },
            },
          },
        });
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
      "kakehashi/bridge/routing": bridgeRouting,
    },
  });
};

export default config;

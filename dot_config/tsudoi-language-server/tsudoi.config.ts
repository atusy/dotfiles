// Tsudoi configuration to be run on Deno
// Unpublished packages are resolved through deno.json's import map.
import {
  completeAround,
  completeCorpus,
  segmentScanner,
} from "@atusy/tsudoi-completion-document";
import { completePath, resolvePathStat } from "@atusy/tsudoi-completion-path";
import { hoverWordnet } from "@atusy/tsudoi-hover-wordnet";
import type { TsudoiConfigFactory } from "@atusy/tsudoi-language-server/types";
import { formatDocument } from "./formatting.ts";

const config: TsudoiConfigFactory = () => {
  const scanner = segmentScanner("ja"); // build outside handler to stabilize memoization of complete functions
  return Promise.resolve({
    methods: {
      "textDocument/completion": async function* (context, params) {
        yield* completePath(context, params);
        yield* completeAround(context, params, { maxLines: 500, scanner });
        yield* completeCorpus(context, params, { scanner, maxItems: 2000 });
      },
      "textDocument/hover": hoverWordnet,
      "textDocument/formatting": formatDocument,
      "completionItem/resolve": resolvePathStat,
    },
  });
};

export default config;

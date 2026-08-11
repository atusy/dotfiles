// Deno equivalent of tsudoi's examples/tsudoi.config.ts. tsudoi is not
// published to npm/JSR, so every @atusy/tsudoi-* specifier here is resolved
// through deno.json's import map (raw GitHub URLs, since the repo went
// public) rather than through node_modules.
import { aroundCompletion } from "@atusy/tsudoi-completion-around";
import { pathCompletion, resolvePathStat } from "@atusy/tsudoi-completion-path";
import { hoverWordnet } from "@atusy/tsudoi-hover-wordnet";
import type { TsudoiConfigFactory } from "@atusy/tsudoi-language-server/types";

const config: TsudoiConfigFactory = () =>
  Promise.resolve({
    methods: {
      "textDocument/completion": async function* (context, params) {
        yield* pathCompletion(context, params);
        yield* aroundCompletion(context, params, { maxSize: 500 });
      },
      "textDocument/hover": hoverWordnet,
      "completionItem/resolve": resolvePathStat,
    },
  });

export default config;

import { assertEquals } from "@std/assert";
import type {
  CustomRequestHandler,
  MethodHandler,
} from "@atusy/tsudoi-language-server/types";
import { join } from "node:path";
import { pathToFileURL } from "node:url";
import configFactory from "./tsudoi.config.ts";

async function completionLabels(
  languageId: string,
  text: string,
  uri = pathToFileURL("/tmp/COMMIT_EDITMSG").href,
): Promise<string[]> {
  const config = await configFactory();
  const complete = config.methods?.["textDocument/completion"] as
    | MethodHandler<"textDocument/completion">
    | undefined;
  const document = {
    uri,
    languageId,
    version: 1,
    lineCount: text.split(/\r?\n/).length,
    getText: () => text,
    positionAt: () => ({ line: 0, character: 0 }),
    offsetAt: () => 0,
  };
  const labels: string[] = [];

  for await (
    const batch of complete!(
      {
        signal: new AbortController().signal,
        tsudoi: {
          documents: {
            get: (documentUri: string) =>
              documentUri === uri ? document : undefined,
            values: () => [document],
          },
          workspaceFolders: { get: () => [], values: () => [] },
          rootUri: null,
          rootPath: null,
          clientCapabilities: {},
          notify: () => Promise.resolve(),
        },
      },
      {
        textDocument: { uri },
        position: { line: 0, character: text.length },
      },
    )
  ) {
    labels.push(...batch.map((item) => item.label));
  }
  return labels;
}

Deno.test("the server advertises and serves bridge routing", async () => {
  const config = await configFactory();
  const initialize = config.methods?.initialize as
    | MethodHandler<"initialize">
    | undefined;
  const route = config.customMethod?.["kakehashi/bridge/routing"] as
    | CustomRequestHandler
    | undefined;

  assertEquals(typeof initialize, "function");
  assertEquals(typeof route, "function");

  const result = await initialize!(
    {
      preparedResult: {
        capabilities: {
          hoverProvider: true,
          experimental: {
            anotherExtension: true,
            kakehashi: { anotherCapability: true },
          },
        },
        serverInfo: { name: "tsudoi-language-server" },
      },
      signal: AbortSignal.abort(),
      tsudoi: {},
    } as never,
    {} as never,
  );
  assertEquals(result, {
    capabilities: {
      hoverProvider: true,
      experimental: {
        anotherExtension: true,
        kakehashi: {
          anotherCapability: true,
          bridgeRouting: true,
        },
      },
    },
    serverInfo: { name: "tsudoi-language-server" },
  });
});

Deno.test("gitcommit completion offers conventional commit types", async () => {
  const labels = await completionLabels("gitcommit", "");
  assertEquals(labels.includes("feat"), true);
});

Deno.test("gitcommit completion uses emoji entries from the commit template", async () => {
  const root = await Deno.makeTempDir();
  try {
    await Deno.mkdir(join(root, ".git"));
    await Deno.writeTextFile(join(root, ".gitmessage"), "✨ feat:\nplain\n");
    const uri = pathToFileURL(join(root, ".git", "COMMIT_EDITMSG")).href;

    const labels = await completionLabels("gitcommit", "", uri);

    assertEquals(labels.includes("✨ feat:"), true);
  } finally {
    await Deno.remove(root, { recursive: true });
  }
});

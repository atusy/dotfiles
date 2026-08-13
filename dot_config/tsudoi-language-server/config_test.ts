import { assertEquals } from "@std/assert";
import type {
  CustomRequestHandler,
  MethodHandler,
} from "@atusy/tsudoi-language-server/types";
import { pathToFileURL } from "node:url";
import configFactory from "./tsudoi.config.ts";

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
  const config = await configFactory();
  const complete = config.methods?.["textDocument/completion"] as
    | MethodHandler<"textDocument/completion">
    | undefined;
  const uri = pathToFileURL("/tmp/COMMIT_EDITMSG").href;
  const document = {
    uri,
    languageId: "gitcommit",
    version: 1,
    lineCount: 1,
    getText: () => "",
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
      { textDocument: { uri }, position: { line: 0, character: 0 } },
    )
  ) {
    labels.push(...batch.map((item) => item.label));
  }

  assertEquals(labels.includes("feat"), true);
});

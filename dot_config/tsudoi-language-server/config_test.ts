import { assertEquals } from "@std/assert";
import type {
  CustomRequestHandler,
  MethodHandler,
} from "@atusy/tsudoi-language-server/types";
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

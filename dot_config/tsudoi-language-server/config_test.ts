import { assertEquals } from "@std/assert";
import type {
  CustomRequestHandler,
  MethodHandler,
} from "@atusy/tsudoi-language-server/types";
import { join } from "node:path";
import { pathToFileURL } from "node:url";
import configFactory from "./tsudoi.config.ts";

async function completionBatches(
  languageId: string,
  text: string,
  uri = pathToFileURL("/tmp/COMMIT_EDITMSG").href,
): Promise<string[][]> {
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
  const batches: string[][] = [];

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
    batches.push(batch.map((item) => item.label));
  }
  return batches;
}

async function completionLabels(
  languageId: string,
  text: string,
  uri = pathToFileURL("/tmp/COMMIT_EDITMSG").href,
): Promise<string[]> {
  return (await completionBatches(languageId, text, uri)).flat();
}

async function initializeRepository(root: string, subjects: readonly string[]) {
  const init = await new Deno.Command("git", {
    args: ["init", "--quiet"],
    cwd: root,
  }).output();
  assertEquals(init.success, true);
  for (const subject of subjects) {
    const commit = await new Deno.Command("git", {
      args: [
        "-c",
        "user.name=Test",
        "-c",
        "user.email=test@example.com",
        "commit",
        "--quiet",
        "--allow-empty",
        "-m",
        subject,
      ],
      cwd: root,
    }).output();
    assertEquals(commit.success, true);
  }
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

Deno.test("gitcommit completion ignores other language ids", async () => {
  const labels = await completionLabels("markdown", "");
  assertEquals(labels.includes("feat"), false);
});

Deno.test("gitcommit completion precedes path completion", async () => {
  const root = await Deno.makeTempDir();
  try {
    await Deno.mkdir(join(root, ".git"));
    await Deno.writeTextFile(join(root, ".git", "fixture"), "");
    const uri = pathToFileURL(join(root, ".git", "COMMIT_EDITMSG")).href;

    const batches = await completionBatches("gitcommit", "f", uri);
    const pathBatch = batches.findIndex((labels) => labels.includes("fixture"));

    assertEquals(batches[0]?.includes("feat"), true);
    assertEquals(pathBatch > 0, true);
  } finally {
    await Deno.remove(root, { recursive: true });
  }
});

Deno.test("gitcommit completion uses emoji entries from the commit template", async () => {
  const root = await Deno.makeTempDir();
  try {
    await Deno.mkdir(join(root, ".git"));
    await Deno.writeTextFile(
      join(root, ".gitmessage"),
      "✨ feat:\n─ chore:\nplain\n",
    );
    const uri = pathToFileURL(join(root, ".git", "COMMIT_EDITMSG")).href;

    const labels = await completionLabels("gitcommit", "", uri);

    assertEquals(labels.includes("✨ feat:"), true);
    assertEquals(labels.includes("─ chore:"), true);
  } finally {
    await Deno.remove(root, { recursive: true });
  }
});

Deno.test("gitcommit completion continues matching recent subjects", async () => {
  const root = await Deno.makeTempDir();
  try {
    await initializeRepository(root, ["feat: support input"]);
    const uri = pathToFileURL(join(root, ".git", "COMMIT_EDITMSG")).href;

    const labels = await completionLabels("gitcommit", "feat: ", uri);

    assertEquals(labels.includes("support input"), true);
  } finally {
    await Deno.remove(root, { recursive: true });
  }
});

Deno.test("gitcommit completion resolves a root-local transient buffer", async () => {
  const root = await Deno.makeTempDir();
  try {
    await initializeRepository(root, ["feat: repository-local completion"]);
    const uri = pathToFileURL(join(root, ".nvim-commit.gitcommit")).href;

    const labels = await completionLabels("gitcommit", "feat: ", uri);

    assertEquals(labels.includes("repository-local completion"), true);
  } finally {
    await Deno.remove(root, { recursive: true });
  }
});

Deno.test("gitcommit completion reuses scopes from recent subjects", async () => {
  const root = await Deno.makeTempDir();
  try {
    await initializeRepository(root, ["feat(parser): support input"]);
    const uri = pathToFileURL(join(root, ".git", "COMMIT_EDITMSG")).href;

    const labels = await completionLabels("gitcommit", "feat(", uri);

    assertEquals(labels.includes("parser"), true);
  } finally {
    await Deno.remove(root, { recursive: true });
  }
});

Deno.test("gitcommit completion reuses conventional prefixes from recent subjects", async () => {
  const root = await Deno.makeTempDir();
  try {
    await initializeRepository(root, ["feat(parser): support input"]);
    const uri = pathToFileURL(join(root, ".git", "COMMIT_EDITMSG")).href;

    const labels = await completionLabels("gitcommit", "", uri);

    assertEquals(labels.includes("feat(parser):"), true);
  } finally {
    await Deno.remove(root, { recursive: true });
  }
});

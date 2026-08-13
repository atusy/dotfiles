import { assertEquals } from "jsr:@std/assert@^1.0.14";
import { join } from "node:path";
import { pathToFileURL } from "node:url";
import { routeTypeScript, type RoutingParams } from "./routing.ts";

Deno.test("a nested Deno config selects denols over a parent Node project", async () => {
  const root = await Deno.makeTempDir();
  try {
    await Deno.writeTextFile(join(root, "package.json"), "{}");
    const denoRoot = join(root, "deno-project");
    await Deno.mkdir(join(denoRoot, "src"), { recursive: true });
    await Deno.writeTextFile(join(denoRoot, "deno.json"), "{}");
    const params: RoutingParams = {
      textDocument: {
        uri: pathToFileURL(join(denoRoot, "src", "main.ts")).href,
        languageId: "typescript",
      },
      languageServers: {
        denols: {
          languages: ["typescript"],
          workspaceMarkers: [],
          preferSharedInstance: true,
        },
        tsgo: {
          languages: ["typescript"],
          workspaceMarkers: [],
          preferSharedInstance: true,
        },
      },
    };

    assertEquals(await routeTypeScript(params), {
      routing: {
        denols: {
          enabled: true,
          workspaceFolders: [pathToFileURL(denoRoot).href],
        },
        tsgo: { enabled: false },
      },
    });
  } finally {
    await Deno.remove(root, { recursive: true });
  }
});

Deno.test("a package project selects tsgo at the package root", async () => {
  const root = await Deno.makeTempDir();
  try {
    await Deno.writeTextFile(join(root, "package.json"), "{}");
    await Deno.mkdir(join(root, "src"));
    const params: RoutingParams = {
      textDocument: {
        uri: pathToFileURL(join(root, "src", "main.ts")).href,
        languageId: "typescript",
      },
      languageServers: {
        denols: {
          languages: ["typescript"],
          workspaceMarkers: [],
          preferSharedInstance: true,
        },
        tsgo: {
          languages: ["typescript"],
          workspaceMarkers: [],
          preferSharedInstance: true,
        },
      },
    };

    assertEquals(await routeTypeScript(params), {
      routing: {
        denols: { enabled: false },
        tsgo: { enabled: true, workspaceFolders: [pathToFileURL(root).href] },
      },
    });
  } finally {
    await Deno.remove(root, { recursive: true });
  }
});

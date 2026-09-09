import type { InitializeResult } from "@atusy/tsudoi-language-server/deps/protocol";
import type { CustomRequestHandler, DeepReadonly } from "@atusy/tsudoi-language-server/types";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

function record(value: unknown): Readonly<Record<string, unknown>> {
  return typeof value === "object" && value !== null
    ? (value as Readonly<Record<string, unknown>>)
    : {};
}

export function initalizeKakehashiBridgeRouting(
  preparedResult: DeepReadonly<InitializeResult>,
): DeepReadonly<InitializeResult> {
  const experimental = record(preparedResult.capabilities.experimental);
  return {
    ...preparedResult,
    capabilities: {
      ...preparedResult.capabilities,
      experimental: {
        ...experimental,
        kakehashi: {
          ...record(experimental.kakehashi),
          bridgeRouting: true,
        },
      },
    },
  };
}

export interface RoutingParams {
  readonly textDocument: {
    readonly uri: string;
    readonly languageId: string;
    readonly host?: { readonly uri: string; readonly languageId: string };
  };
  readonly languageServers: Readonly<
    Record<
      string,
      {
        readonly languages: readonly string[];
        readonly workspaceMarkers: readonly (string | readonly string[])[];
        readonly preferSharedInstance: boolean;
      }
    >
  >;
}

export interface RoutingResult {
  readonly routing: Readonly<
    Record<
      string,
      {
        readonly enabled?: boolean;
        readonly workspaceFolders?: readonly string[];
      }
    >
  >;
}

export function isRoutingParams(value: unknown): value is RoutingParams {
  if (typeof value !== "object" || value === null) {
    return false;
  }
  const { textDocument, languageServers } = value as {
    readonly textDocument?: unknown;
    readonly languageServers?: unknown;
  };
  if (
    typeof textDocument !== "object" ||
    textDocument === null ||
    typeof (textDocument as { readonly uri?: unknown }).uri !== "string" ||
    typeof (textDocument as { readonly languageId?: unknown }).languageId !== "string"
  ) {
    return false;
  }
  const host = (textDocument as { readonly host?: unknown }).host;
  if (
    host !== undefined &&
    (typeof host !== "object" ||
      host === null ||
      typeof (host as { readonly uri?: unknown }).uri !== "string" ||
      typeof (host as { readonly languageId?: unknown }).languageId !== "string")
  ) {
    return false;
  }
  return typeof languageServers === "object" && languageServers !== null;
}

const nodeLocks = ["package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock"];

async function findRoot(filePath: string, markers: readonly string[]): Promise<string | null> {
  let directory = dirname(filePath);
  while (true) {
    for (const marker of markers) {
      try {
        await Deno.stat(join(directory, marker));
        return directory;
      } catch (error) {
        if (!(error instanceof Deno.errors.NotFound)) {
          throw error;
        }
      }
    }
    const parent = dirname(directory);
    if (parent === directory) {
      return null;
    }
    directory = parent;
  }
}

function isDeeper(root: string | null, than: string): boolean {
  return root !== null && root.length > than.length;
}

export async function routeTypeScript(params: RoutingParams): Promise<RoutingResult | null> {
  const documentUri = params.textDocument.host?.uri ?? params.textDocument.uri;
  let filePath: string;
  try {
    filePath = fileURLToPath(documentUri);
  } catch {
    return null;
  }

  const [denolsNodeRoot, tscNodeRoot, denoLockRoot, denoConfigRoot] = await Promise.all([
    findRoot(filePath, nodeLocks),
    findRoot(filePath, [...nodeLocks, "package.json"]),
    findRoot(filePath, ["deno.lock"]),
    findRoot(filePath, ["deno.json", "deno.jsonc"]),
  ]);
  const denoRoot =
    denolsNodeRoot === null ||
    isDeeper(denoLockRoot, denolsNodeRoot) ||
    isDeeper(denoConfigRoot, denolsNodeRoot)
      ? (denoLockRoot ?? denoConfigRoot)
      : null;
  const tscRoot =
    tscNodeRoot !== null &&
    !(denoLockRoot !== null && denoLockRoot.length >= tscNodeRoot.length) &&
    !(denoConfigRoot !== null && denoConfigRoot.length >= tscNodeRoot.length)
      ? tscNodeRoot
      : null;
  const routing: Record<string, { enabled?: boolean; workspaceFolders?: readonly string[] }> = {};
  if (Object.hasOwn(params.languageServers, "denols")) {
    routing.denols =
      denoRoot === null
        ? { enabled: tscRoot === null }
        : { enabled: true, workspaceFolders: [pathToFileURL(denoRoot).href] };
  }
  if (Object.hasOwn(params.languageServers, "tsc")) {
    routing.tsc =
      tscRoot === null
        ? { enabled: false }
        : { enabled: true, workspaceFolders: [pathToFileURL(tscRoot).href] };
  }
  return Object.keys(routing).length === 0 ? null : { routing };
}

export const handleKakehashiBridgeRouting: CustomRequestHandler = async (_context, params) => ({
  result: isRoutingParams(params) ? await routeTypeScript(params) : null,
});

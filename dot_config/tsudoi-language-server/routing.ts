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

const nodeLocks = [
  "package-lock.json",
  "yarn.lock",
  "pnpm-lock.yaml",
  "bun.lockb",
  "bun.lock",
];

async function findRoot(
  filePath: string,
  markers: readonly string[],
): Promise<string | null> {
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

export async function routeTypeScript(
  params: RoutingParams,
): Promise<RoutingResult | null> {
  const documentUri = params.textDocument.host?.uri ?? params.textDocument.uri;
  let filePath: string;
  try {
    filePath = fileURLToPath(documentUri);
  } catch {
    return null;
  }

  const [denolsNodeRoot, tsgoNodeRoot, denoLockRoot, denoConfigRoot] =
    await Promise.all([
      findRoot(filePath, nodeLocks),
      findRoot(filePath, [...nodeLocks, "package.json"]),
      findRoot(filePath, ["deno.lock"]),
      findRoot(filePath, ["deno.json", "deno.jsonc"]),
    ]);
  const denoRoot =
    denolsNodeRoot === null || isDeeper(denoLockRoot, denolsNodeRoot) ||
      isDeeper(denoConfigRoot, denolsNodeRoot)
      ? (denoLockRoot ?? denoConfigRoot)
      : null;
  const tsgoRoot = tsgoNodeRoot !== null &&
      !isDeeper(denoLockRoot, tsgoNodeRoot) &&
      !(denoConfigRoot !== null && denoConfigRoot.length >= tsgoNodeRoot.length)
    ? tsgoNodeRoot
    : null;
  const routing: Record<
    string,
    { enabled?: boolean; workspaceFolders?: readonly string[] }
  > = {};
  if (Object.hasOwn(params.languageServers, "denols")) {
    routing.denols = denoRoot === null
      ? { enabled: false }
      : { enabled: true, workspaceFolders: [pathToFileURL(denoRoot).href] };
  }
  if (Object.hasOwn(params.languageServers, "tsgo")) {
    routing.tsgo = tsgoRoot === null
      ? { enabled: false }
      : { enabled: true, workspaceFolders: [pathToFileURL(tsgoRoot).href] };
  }
  return Object.keys(routing).length === 0 ? null : { routing };
}
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

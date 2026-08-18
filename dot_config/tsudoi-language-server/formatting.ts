import type { MethodHandler } from "@atusy/tsudoi-language-server/types";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

export type FormatFunc = (
  filePath: string,
  text: string,
  signal: AbortSignal,
) => Promise<string>;

export type FormatFuncResolver = (
  directoryPath: string,
) => Promise<FormatFunc | null>;

export async function findFormatFunc(
  filePath: string,
  resolvers: readonly FormatFuncResolver[],
): Promise<FormatFunc | null> {
  let directory = dirname(filePath);
  while (true) {
    for (const resolve of resolvers) {
      const format = await resolve(directory);
      if (format !== null) {
        return format;
      }
    }

    const parent = dirname(directory);
    if (parent === directory) {
      return null;
    }
    directory = parent;
  }
}

export const resolveTreefmtToml: FormatFuncResolver = async (directoryPath) => {
  const configPath = join(directoryPath, "treefmt.toml");
  try {
    if ((await Deno.stat(configPath)).isFile) {
      return (filePath, text, signal) =>
        formatWithTreefmt(filePath, configPath, text, signal);
    }
  } catch (error) {
    if (!(error instanceof Deno.errors.NotFound)) {
      throw error;
    }
  }
  return null;
};

export const resolveFlakeTreefmt: FormatFuncResolver = async (
  directoryPath,
) => {
  const flakePath = join(directoryPath, "flake.nix");
  try {
    if ((await Deno.stat(flakePath)).isFile) {
      const flake = await Deno.readTextFile(flakePath);
      if (flake.includes("treefmt")) {
        return (filePath, text, signal) =>
          formatWithFlakeTreefmt(
            directoryPath,
            filePath,
            text,
            signal,
          );
      }
    }
  } catch (error) {
    if (!(error instanceof Deno.errors.NotFound)) {
      throw error;
    }
  }
  return null;
};

const resolveDprint: FormatFuncResolver = async (directoryPath) => {
  const configPath = join(directoryPath, "dprint.json");
  try {
    if ((await Deno.stat(configPath)).isFile) {
      return (filePath, text, signal) =>
        formatWithDprint(filePath, configPath, text, signal);
    }
  } catch (error) {
    if (!(error instanceof Deno.errors.NotFound)) {
      throw error;
    }
  }
  return null;
};

async function formatWithTreefmt(
  filePath: string,
  configPath: string,
  text: string,
  signal: AbortSignal,
): Promise<string> {
  const child = new Deno.Command("treefmt", {
    args: [
      "--config-file",
      configPath,
      "--tree-root",
      dirname(configPath),
      "--stdin",
      filePath,
    ],
    stdin: "piped",
    stdout: "piped",
    stderr: "piped",
  }).spawn();
  const abort = () => child.kill("SIGTERM");
  signal.addEventListener("abort", abort, { once: true });

  try {
    const writer = child.stdin.getWriter();
    const write = writer.write(new TextEncoder().encode(text)).then(() =>
      writer.close()
    );
    const [output] = await Promise.all([child.output(), write]);
    if (!output.success) {
      throw new Error(new TextDecoder().decode(output.stderr).trim());
    }
    return new TextDecoder().decode(output.stdout);
  } finally {
    signal.removeEventListener("abort", abort);
  }
}

async function formatWithFlakeTreefmt(
  directoryPath: string,
  filePath: string,
  text: string,
  signal: AbortSignal,
): Promise<string> {
  const child = new Deno.Command("nix", {
    args: ["fmt", "--", "--stdin", filePath],
    cwd: directoryPath,
    stdin: "piped",
    stdout: "piped",
    stderr: "piped",
  }).spawn();
  const abort = () => child.kill("SIGTERM");
  signal.addEventListener("abort", abort, { once: true });

  try {
    const writer = child.stdin.getWriter();
    const write = writer.write(new TextEncoder().encode(text)).then(() =>
      writer.close()
    );
    const [output] = await Promise.all([child.output(), write]);
    if (!output.success) {
      throw new Error(new TextDecoder().decode(output.stderr).trim());
    }
    return new TextDecoder().decode(output.stdout);
  } finally {
    signal.removeEventListener("abort", abort);
  }
}

async function formatWithDprint(
  filePath: string,
  configPath: string,
  text: string,
  signal: AbortSignal,
): Promise<string> {
  const child = new Deno.Command("dprint", {
    args: ["fmt", "--config", configPath, "--stdin", filePath],
    stdin: "piped",
    stdout: "piped",
    stderr: "piped",
  }).spawn();
  const abort = () => child.kill("SIGTERM");
  signal.addEventListener("abort", abort, { once: true });

  try {
    const writer = child.stdin.getWriter();
    const write = writer.write(new TextEncoder().encode(text)).then(() =>
      writer.close()
    );
    const [output] = await Promise.all([child.output(), write]);
    if (!output.success) {
      throw new Error(new TextDecoder().decode(output.stderr).trim());
    }
    return new TextDecoder().decode(output.stdout);
  } finally {
    signal.removeEventListener("abort", abort);
  }
}

export const formatDocument: MethodHandler<"textDocument/formatting"> = async (
  context,
  params,
) => {
  const document = context.tsudoi.documents.get(params.textDocument.uri);
  if (document === undefined) {
    throw "RequestFailed"; // so that kakehashi can fallback to oxfmt
  }

  let filePath: string;
  try {
    filePath = fileURLToPath(document.uri);
  } catch {
    throw "RequestFailed"; // so that kakehashi can fallback to oxfmt
  }
  const format = await findFormatFunc(filePath, [
    resolveTreefmtToml,
    resolveFlakeTreefmt,
    resolveDprint,
  ]);
  if (format === null) {
    throw "RequestFailed"; // so that kakehashi can fallback to oxfmt
  }

  const text = document.getText();
  const formatted = await format(filePath, text, context.signal);

  if (formatted === text) {
    return [];
  }
  return [
    {
      range: {
        start: { line: 0, character: 0 },
        end: document.positionAt(text.length),
      },
      newText: formatted,
    },
  ];
};

import type { MethodHandler } from "@atusy/tsudoi-language-server/types";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

async function findDprintConfig(filePath: string): Promise<string | null> {
  let directory = dirname(filePath);
  while (true) {
    const configPath = join(directory, "dprint.json");
    try {
      if ((await Deno.stat(configPath)).isFile) {
        return configPath;
      }
    } catch (error) {
      if (!(error instanceof Deno.errors.NotFound)) {
        throw error;
      }
    }

    const parent = dirname(directory);
    if (parent === directory) {
      return null;
    }
    directory = parent;
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
    const write = writer.write(new TextEncoder().encode(text)).then(() => writer.close());
    const [output] = await Promise.all([child.output(), write]);
    if (!output.success) {
      throw new Error(new TextDecoder().decode(output.stderr).trim());
    }
    return new TextDecoder().decode(output.stdout);
  } finally {
    signal.removeEventListener("abort", abort);
  }
}

export const formatDocument: MethodHandler<"textDocument/formatting"> = async (context, params) => {
  const document = context.tsudoi.documents.get(params.textDocument.uri);
  if (document === undefined) {
    return null;
  }

  let filePath: string;
  try {
    filePath = fileURLToPath(document.uri);
  } catch {
    return null;
  }
  const configPath = await findDprintConfig(filePath);
  if (configPath === null) {
    return null;
  }

  const text = document.getText();
  const formatted = await formatWithDprint(filePath, configPath, text, context.signal);

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

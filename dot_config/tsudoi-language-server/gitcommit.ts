import type { CompletionParams } from "@atusy/tsudoi-language-server/deps/protocol";
import type { CompletionItem } from "@atusy/tsudoi-language-server/deps/types";
import type { RequestContext } from "@atusy/tsudoi-language-server/types";
import { basename, dirname, isAbsolute, join } from "node:path";
import { fileURLToPath } from "node:url";

const emoji = /\p{Regional_Indicator}{2}|\p{Extended_Pictographic}/u;

const conventionalCommitTypes = [
  "build",
  "chore",
  "ci",
  "docs",
  "feat",
  "fix",
  "perf",
  "refactor",
  "style",
  "test",
] as const;

function gitRoot(uri: string): string {
  try {
    const directory = dirname(fileURLToPath(uri));
    return basename(directory) === ".git" ? dirname(directory) : Deno.cwd();
  } catch {
    return Deno.cwd();
  }
}

async function configuredTemplate(root: string): Promise<string> {
  try {
    const output = await new Deno.Command("git", {
      args: ["config", "commit.template"],
      cwd: root,
      stdout: "piped",
      stderr: "null",
    }).output();
    return output.success ? new TextDecoder().decode(output.stdout).trim() : "";
  } catch {
    return "";
  }
}

async function readLines(path: string): Promise<string[] | undefined> {
  try {
    return (await Deno.readTextFile(path)).split(/\r?\n/);
  } catch (error) {
    if (error instanceof Deno.errors.NotFound) {
      return undefined;
    }
    throw error;
  }
}

async function commitTemplate(root: string): Promise<string[]> {
  const configured = await configuredTemplate(root);
  if (configured === "" || isAbsolute(configured)) {
    const local = await readLines(join(root, ".gitmessage"));
    if (local !== undefined) {
      return local;
    }
  }
  if (configured === "") {
    return [];
  }
  return await readLines(
    isAbsolute(configured) ? configured : join(root, configured),
  ) ?? [];
}

export async function* completeGitCommit(
  context: RequestContext,
  params: CompletionParams,
): AsyncGenerator<CompletionItem[], void, void> {
  if (params.position.line !== 0) {
    return;
  }
  const document = context.tsudoi.documents.get(params.textDocument.uri);
  if (document === undefined) {
    return;
  }
  const templateItems = (await commitTemplate(gitRoot(document.uri))).filter(
    (line) => emoji.test(line),
  );
  if (templateItems.length > 0) {
    yield templateItems.map((label) => ({ label }));
    return;
  }
  yield conventionalCommitTypes.map((label) => ({ label }));
}

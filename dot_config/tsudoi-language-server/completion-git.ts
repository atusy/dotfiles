import type { CompletionParams } from "@atusy/tsudoi-language-server/deps/protocol";
import type { CompletionItem } from "@atusy/tsudoi-language-server/deps/types";
import type { RequestContext } from "@atusy/tsudoi-language-server/types";
import { basename, dirname, isAbsolute, join } from "node:path";
import { fileURLToPath } from "node:url";

const templateMarker =
  /[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}\u2500-\u2BEF\u2702-\u27B0\u{1F926}-\u{1F937}\u{10000}-\u{10FFFF}\u2640-\u2642\u2600-\u2B55\u200D\u23CF\u23E9\u231A\uFE0F\u3030]/u;

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

async function gitRoot(uri: string): Promise<string> {
  let directory: string;
  try {
    directory = dirname(fileURLToPath(uri));
  } catch {
    return Deno.cwd();
  }
  if (basename(directory) === ".git") {
    return dirname(directory);
  }
  try {
    const output = await new Deno.Command("git", {
      args: ["rev-parse", "--show-toplevel"],
      cwd: directory,
      stdout: "piped",
      stderr: "null",
    }).output();
    if (output.success) {
      return new TextDecoder().decode(output.stdout).trim();
    }
  } catch {
    // Fall through to the document directory.
  }
  return directory;
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

async function recentSubjects(root: string): Promise<string[]> {
  try {
    const output = await new Deno.Command("git", {
      args: ["log", "-n", "100", "--format=%s"],
      cwd: root,
      stdout: "piped",
      stderr: "null",
    }).output();
    return output.success
      ? new TextDecoder().decode(output.stdout).split(/\r?\n/).filter(Boolean)
      : [];
  } catch {
    return [];
  }
}

function matchingSubjects(
  logs: readonly string[],
  subject: string,
): CompletionItem[] {
  const currentWord = subject.match(/[\p{L}\p{N}_]+$/u)?.[0] ?? "";
  const prefix = subject.slice(0, subject.length - currentWord.length);
  return logs
    .filter((log) => log.startsWith(subject))
    .map((log) => ({ label: log.slice(prefix.length) }));
}

function scopesFrom(logs: readonly string[]): CompletionItem[] {
  return Array.from(
    new Set(logs.flatMap((log) => log.match(/^\S+\((\S+)\)!?:/u)?.[1] ?? [])),
    (label) => ({ label }),
  );
}

function prefixesFrom(logs: readonly string[]): CompletionItem[] {
  return Array.from(
    new Set(logs.flatMap((log) => log.match(/^\S+\(\S+\)!?:/u)?.[0] ?? [])),
    (label) => ({ label }),
  );
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
  const line = document.getText().split(/\r?\n/)[params.position.line];
  if (line === undefined) {
    return;
  }
  const subject = line.slice(0, params.position.character);
  const root = await gitRoot(document.uri);
  const [template, logs] = await Promise.all([
    commitTemplate(root),
    recentSubjects(root),
  ]);
  const templateItems = template.filter(
    (line) => templateMarker.test(line),
  );
  const semantic = templateItems.length === 0;
  if (!subject.match(/\s/u) && !(semantic && subject.includes(":"))) {
    const baseItems = semantic
      ? subject.includes("(") ? scopesFrom(logs) : [
        ...conventionalCommitTypes.map((label) => ({ label })),
        ...prefixesFrom(logs),
      ]
      : templateItems.map((label) => ({ label }));
    if (baseItems.length > 0) {
      yield baseItems;
    }
  }
  const logItems = matchingSubjects(logs, subject);
  if (logItems.length > 0) {
    yield logItems;
  }
}

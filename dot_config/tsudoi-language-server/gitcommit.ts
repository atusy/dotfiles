import type { CompletionParams } from "@atusy/tsudoi-language-server/deps/protocol";
import type { CompletionItem } from "@atusy/tsudoi-language-server/deps/types";
import type { RequestContext } from "@atusy/tsudoi-language-server/types";

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

export async function* completeGitCommit(
  _context: RequestContext,
  params: CompletionParams,
): AsyncGenerator<CompletionItem[], void, void> {
  if (params.position.line !== 0) {
    return;
  }
  yield conventionalCommitTypes.map((label) => ({ label }));
}

import { useShellCompletion } from "@atusy/tsudoi-completion-shell";
import type { CompletionParams } from "@atusy/tsudoi-language-server/deps/protocol";
import type { CompletionItem } from "@atusy/tsudoi-language-server/deps/types";
import type { RequestContext } from "@atusy/tsudoi-language-server/types";

const zshFpath = await (async () => {
  const cmd = new Deno.Command("zsh", {
    args: ["-c", 'echo -n "$FPATH"'],
  });
  const output = await cmd.output();
  return new TextDecoder().decode(output.stdout);
})();

export function useMyShellCompletion(): (
  context: RequestContext,
  params: CompletionParams,
) => AsyncGenerator<CompletionItem[], void, void> {
  const completeFish = useShellCompletion("fish", {
    env: { COLUMNS: "200", DDCVIM: "1" },
  });
  const completeZsh = useShellCompletion("zsh", {
    env: { COLUMNS: "200", FPATH: zshFpath },
  });
  const completeXonsh = useShellCompletion("xonsh", {
    env: { COLUMNS: "200" },
  });
  const shellCompletions = {
    bash: completeZsh,
    fish: completeFish,
    sh: completeZsh,
    xonsh: completeXonsh,
    zsh: completeZsh,
  } as const;

  return async function* (context, params) {
    const languageId = context.tsudoi.documents.get(
      params.textDocument.uri,
    )?.languageId;
    if (languageId === undefined) {
      return;
    }
    const completeShell =
      shellCompletions[languageId as keyof typeof shellCompletions];
    if (completeShell !== undefined) {
      yield* completeShell(context, params);
    }
  };
}

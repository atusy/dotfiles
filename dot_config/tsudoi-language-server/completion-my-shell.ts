import {
  type ShellCompletion,
  useShellCompletion,
} from "@atusy/tsudoi-completion-shell";

const zshFpath = await (async () => {
  const cmd = new Deno.Command("zsh", {
    args: ["-c", 'echo -n "$FPATH"'],
  });
  const output = await cmd.output();
  return new TextDecoder().decode(output.stdout);
})();

export function useMyShellCompletion(): ShellCompletion {
  const completeFish = useShellCompletion("fish", {
    env: { COLUMNS: "200", NVIM_EX_COMPLETION: "1" },
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

  return async function* (context, params, options) {
    const languageId = context.tsudoi.documents.get(params.textDocument.uri)
      ?.languageId;
    if (languageId === undefined) {
      return;
    }
    const completeShell =
      shellCompletions[languageId as keyof typeof shellCompletions];
    if (completeShell !== undefined) {
      return yield* completeShell(context, params, options);
    }
  };
}

// A thin local entry point. Passing the raw GitHub URL straight to `deno run`
// makes deno fail to resolve "vscode-languageserver-protocol/node" from
// methods.ts via this same import map (measured on deno 2.9.4) -- importing
// the remote cli.ts from a local file instead resolves it correctly.
import "https://raw.githubusercontent.com/atusy/tsudoi-language-server/8470311/packages/tsudoi-language-server/src/cli.ts";

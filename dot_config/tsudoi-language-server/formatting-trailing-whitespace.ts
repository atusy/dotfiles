/**
 * Trailing-whitespace removal for a config author's own
 * `textDocument/formatting` handler.
 *
 * THE OTHER HALF OF A PAIR, AND THE IMPORT BELOW IS THE PAIRING. This removes
 * exactly what `examples/diagnostic-trailing-whitespace.ts` reports, because it
 * asks that module for the runs rather than scanning again. A reader runs the
 * demo, sees the warnings, formats, and watches them clear -- and that loop is
 * true only because ONE analysis feeds both answers. Two independent scans
 * would drift the first time either was edited, and nothing in an editor would
 * say so: the warnings would simply stop clearing.
 *
 * WHY THE SCAN LIVES IN THE DIAGNOSTIC MODULE AND NOT IN A THIRD FILE, since a
 * third would keep these two independent of each other: a module exporting an
 * ALGORITHM AND NO HANDLER teaches the reader nothing about tsudoi, and the
 * example set's whole subject is the shape of a handler. The cost is real and
 * is named rather than waved past -- this file cannot be copied without the
 * other, which is why `exampleSources()` carries every module and the README
 * tells a reader to take the set.
 */
import type { MethodHandler } from "@atusy/tsudoi-language-server/types";
import { trailingRuns } from "./diagnostic-trailing-whitespace.ts";

/**
 * A `textDocument/formatting` handler that deletes trailing whitespace.
 *
 * ONE EDIT PER RUN, NOT ONE EDIT FOR THE DOCUMENT, and that is the half worth
 * copying. Replacing the whole buffer is legal, is what a first attempt reaches
 * for, and is THE `FULL SYNC` OF FORMATTING: it makes `TextEdit[]` an array of
 * one forever, it destroys the client's ability to show what changed, and it
 * loses every mark and fold the editor was holding on the untouched lines.
 *
 * `newText: ""` IS WHAT MAKES A DELETION, and it is the whole trick: the range
 * covers the run and the replacement is nothing. There is no `delete` in this
 * protocol.
 *
 * THE EDITS DO NOT OVERLAP AND ARE IN DOCUMENT ORDER, which the protocol
 * requires of a `TextEdit[]` -- and it holds here BY CONSTRUCTION rather than by
 * a sort, because at most one run exists per line and `trailingRuns` walks the
 * lines in order.
 *
 * `null` WHEN THE DOCUMENT IS NOT IN THE STORE, which this result type declares
 * and the diagnostic one does not. An empty array would be a different claim --
 * `this file is already formatted` -- about a file that was never read.
 */
export const removeTrailingWhitespace: MethodHandler<"textDocument/formatting"> = (
  context,
  params,
) => {
  const document = context.tsudoi.documents.get(params.textDocument.uri);
  if (document === undefined) {
    return Promise.resolve(null);
  }
  return Promise.resolve(
    trailingRuns(document.getText()).map((run) => ({
      range: {
        start: document.positionAt(run.start),
        end: document.positionAt(run.end),
      },
      newText: "",
    })),
  );
};

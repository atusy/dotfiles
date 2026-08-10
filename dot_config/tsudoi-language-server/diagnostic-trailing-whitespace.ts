/**
 * Trailing-whitespace diagnostics for a config author's own
 * `textDocument/diagnostic` handler.
 *
 * WHAT THIS IS AND WHAT IT IS NOT: an EXAMPLE, in examples/, and not a line of
 * it lives in tsudoi. It is here to show the shape of a handler that COMPUTES
 * ITS ANSWER FROM THE DOCUMENT IT WAS GIVEN -- no dictionary, no filesystem, no
 * subprocess -- which is the commoner shape for a real language server, because
 * a parser does not go anywhere else for its answer either.
 *
 * IT IS HALF OF A PAIR. `examples/formatting-trailing-whitespace.ts` removes
 * exactly what this reports, and it does so by importing `trailingRuns` from
 * here rather than by scanning again. That import IS the pairing: a reader runs
 * the demo, sees the warnings, formats, and watches them clear -- and the loop
 * closes only because one analysis feeds both answers.
 */

import { DiagnosticSeverity } from "@atusy/tsudoi-language-server/deps/types";
import type { MethodHandler } from "@atusy/tsudoi-language-server/types";

/** What the warning says. Exported so a test can assert it without copying it. */
export const warning = "trailing whitespace";

/** One run of trailing whitespace, as OFFSETS into the whole buffer. */
export interface TrailingRun {
  /** Where the run begins -- the first whitespace character of the run. */
  readonly start: number;
  /** Where the line's content ends. Never includes the line terminator. */
  readonly end: number;
}

/**
 * Every run of trailing whitespace in `text`, in document order.
 *
 * OFFSETS AND NOTHING ELSE, which is the point of this function being separate
 * from the handler below. A real analysis -- a parser, a linter's own lexer --
 * knows offsets into a buffer, and the protocol wants Positions; keeping the
 * scan offset-only makes `positionAt` the VISIBLE step in both handlers rather
 * than something that happened somewhere on the way.
 *
 * TRAILING NEWLINES ARE OUT OF SCOPE AND THAT IS A CHOICE, not an oversight. A
 * run stops at the end of a line's CONTENT, so the line terminators themselves
 * are never part of one and a file ending in blank lines is left alone. The
 * whole-file tail edit is a different feature with a different range shape, and
 * mixing it in here would give the pair a case where the diagnostic and the
 * formatter disagree about what a `line` is.
 *
 * SPACE AND TAB ONLY. Every other Unicode space -- U+00A0 above all -- is
 * INVISIBLE IN AN EDITOR AND MEANINGFUL IN SOME LANGUAGES, so removing it is a
 * decision only the config author can make; a general `\s` sweep would also
 * swallow `\r`, which belongs to the line terminator rather than to the line.
 *
 * `\r` IS STRIPPED BEFORE MEASURING for exactly that reason, so a CRLF document
 * does not report every single line as ending in whitespace.
 *
 * A LINE THAT IS ENTIRELY WHITESPACE IS REPORTED WHOLE, which follows from the
 * rule rather than being a case bolted onto it: its content ends at column 0.
 * That is the intended answer -- a line that looks blank and is not is the
 * thing this check exists to surface.
 *
 * Offsets count UTF-16 code units, as LSP does and as `positionAt` expects.
 */
export function trailingRuns(text: string): TrailingRun[] {
  const runs: TrailingRun[] = [];
  let lineStart = 0;
  for (const line of text.split("\n")) {
    const content = line.endsWith("\r") ? line.slice(0, -1) : line;
    let end = content.length;
    while (end > 0 && (content[end - 1] === " " || content[end - 1] === "\t")) {
      end -= 1;
    }
    if (end < content.length) {
      runs.push({ start: lineStart + end, end: lineStart + content.length });
    }
    // The separator `split` consumed is one unit wide; a stripped `\r` is
    // already inside `line.length`.
    lineStart += line.length + 1;
  }
  return runs;
}

/**
 * A `textDocument/diagnostic` handler that warns about trailing whitespace.
 *
 * A FULL REPORT WITH NO ITEMS, NEVER `null`, when the document is not in the
 * store: this result declares no null arm, and an empty full report is a REPORT
 * SAYING THE FILE IS CLEAN -- which is what makes a client clear the
 * diagnostics it is already showing.
 *
 * ONE ITEM PER RUN, and that is the half a reader is meant to copy. A single
 * finding spanning the document would be legal and would teach the wrong thing:
 * `Diagnostic[]` is an array because a real analysis has several complaints in
 * several places.
 */
export const trailingWhitespaceDiagnostics: MethodHandler<"textDocument/diagnostic"> = (
  context,
  params,
) => {
  const document = context.tsudoi.documents.get(params.textDocument.uri);
  if (document === undefined) {
    return Promise.resolve({ kind: "full", items: [] });
  }
  return Promise.resolve({
    kind: "full",
    items: trailingRuns(document.getText()).map((run) => ({
      range: {
        start: document.positionAt(run.start),
        end: document.positionAt(run.end),
      },
      // A WARNING RATHER THAN AN ERROR: nothing here stops the file being read,
      // and an example that shouts is an example whose severity a reader
      // changes before they have understood what it is for.
      severity: DiagnosticSeverity.Warning,
      message: warning,
    })),
  });
};

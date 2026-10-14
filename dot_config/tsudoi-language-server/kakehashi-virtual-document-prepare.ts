// `kakehashi/virtualDocument/prepare` for Nix hosts (experimental; needs
// KAKEHASHI_EXPERIMENTAL=true and `languages.nix.bridge._.prepare = "tsudoi"`).
//
// Language servers bridged into a Nix string see what Nix would produce:
// - the string's common indentation removed, as Nix does for `'' … ''`;
// - each `${…}` interpolation replaced with a placeholder their language
//   parses, so `"port": ${toString cfg.port}` reads as `"port": 0`;
// - strings commented with the same language, which kakehashi combines into
//   one document, joined: the Nix between them (`'';` … `''`) disappears.
// kakehashi maps every position and edit back, and refuses edits that would
// touch an interpolation.

import type { InitializeResult } from "@atusy/tsudoi-language-server/deps/protocol";
import type { CustomRequestHandler, DeepReadonly } from "@atusy/tsudoi-language-server/types";

export interface Segment {
  readonly type: "content" | "gap";
  /**
   * Content: the injected text. Gap: the original host text — an
   * interpolation (`${…}`), or the Nix between two combined strings.
   */
  readonly content: string;
}

export interface PrepareParams {
  readonly textDocument: { readonly uri: string; readonly languageId: string; readonly version: number };
  readonly hostTextDocument: { readonly uri: string; readonly languageId: string };
  readonly segments: readonly Segment[];
}

interface TextEdit {
  range: { start: { line: number; character: number }; end: { line: number; character: number } };
  newText: string;
}

type SegmentResult =
  | { type: "content"; changes?: TextEdit[] }
  | { type: "gap"; content?: string };

export interface PrepareResult {
  segments: SegmentResult[];
}

/**
 * A stand-in for an interpolation, valid both as a value and inside a string
 * literal of the language. Languages without one keep the interpolation
 * masked as whitespace.
 */
const placeholders: Readonly<Record<string, string>> = {
  bash: "__nix__",
  sh: "__nix__",
  zsh: "__nix__",
  fish: "__nix__",
  python: "None",
  json: "0",
  jsonc: "0",
  toml: "0",
  yaml: "__nix__",
  lua: "nil",
  javascript: "undefined",
  typescript: "undefined",
};

interface LineStart {
  /** Line within its segment. */
  readonly line: number;
  readonly spaces: number;
  readonly blank: boolean;
}

/** Whether a gap is an interpolation, rather than the Nix between strings. */
function isInterpolation(segment: Segment | undefined): boolean {
  return segment?.type === "gap" && segment.content.startsWith("${");
}

/** The lines of each content segment that start a line of the document. */
function lineStarts(segments: readonly Segment[]): LineStart[][] {
  return segments.map((segment, index) => {
    if (segment.type !== "content") {
      return [];
    }
    // A segment continues the line before it unless it opens the document
    // or the gap before it ended one.
    const startsLine = index === 0 || segments[index - 1].content.endsWith("\n");
    const lines = segment.content.split("\n");
    return lines.flatMap((text, line) => {
      if (line === 0 && !startsLine) {
        return [];
      }
      // Nix counts spaces only. A line whose rest is an interpolation is
      // not blank, though its own text here is only indentation; one that
      // ends a string (the indentation before its closing quotes) is.
      const continues = line === lines.length - 1 && isInterpolation(segments[index + 1]);
      const spaces = text.length - text.replace(/^ +/, "").length;
      return [{ line, spaces, blank: text.trim() === "" && !continues }];
    });
  });
}

/**
 * The common indentation of each segment's string: Nix dedents every `''`
 * string on its own, so joined strings may lose different amounts.
 */
function stringIndents(segments: readonly Segment[], starts: readonly LineStart[][]): number[] {
  const strings: number[] = [];
  let string = 0;
  segments.forEach((segment, index) => {
    if (segment.type === "gap" && !isInterpolation(segment)) {
      string += 1;
    }
    strings[index] = string;
  });
  const indents = new Map<number, number>();
  starts.forEach((lines, index) => {
    for (const { spaces, blank } of lines) {
      if (!blank) {
        indents.set(strings[index], Math.min(indents.get(strings[index]) ?? spaces, spaces));
      }
    }
  });
  return strings.map((string) => indents.get(string) ?? 0);
}

export function prepareVirtualDocument(params: PrepareParams): PrepareResult | null {
  if (params.hostTextDocument.languageId !== "nix") {
    return null;
  }
  const starts = lineStarts(params.segments);
  const indents = stringIndents(params.segments, starts);
  const placeholder = placeholders[params.textDocument.languageId];
  const gaps = params.segments.filter((segment) => segment.type === "gap");
  const changesGaps =
    gaps.some((gap) => !isInterpolation(gap)) ||
    (placeholder !== undefined && gaps.length > 0);
  if (indents.every((indent) => indent === 0) && !changesGaps) {
    return null;
  }
  return {
    segments: params.segments.map((segment, index): SegmentResult => {
      if (segment.type === "gap") {
        if (!isInterpolation(segment)) {
          return { type: "gap", content: "" };
        }
        return placeholder === undefined ? { type: "gap" } : { type: "gap", content: placeholder };
      }
      // Whitespace-only lines keep theirs: removing less from them than from
      // the rest (the indentation before the closing quotes, say) would
      // leave kakehashi no uniform indentation to give lines a formatter
      // creates, and it would refuse the formatting.
      const changes = starts[index]
        .filter(({ blank }) => !blank)
        .map(({ line }) => ({ line, width: indents[index] }))
        .filter(({ width }) => width > 0)
        .map(({ line, width }) => ({
          range: { start: { line, character: 0 }, end: { line, character: width } },
          newText: "",
        }));
      return changes.length === 0 ? { type: "content" } : { type: "content", changes };
    }),
  };
}

function isPrepareParams(value: unknown): value is PrepareParams {
  if (typeof value !== "object" || value === null) {
    return false;
  }
  const { textDocument, hostTextDocument, segments } = value as Record<string, unknown>;
  return (
    typeof (textDocument as { languageId?: unknown } | null)?.languageId === "string" &&
    typeof (hostTextDocument as { languageId?: unknown } | null)?.languageId === "string" &&
    Array.isArray(segments) &&
    segments.every(
      (segment) =>
        (segment?.type === "content" || segment?.type === "gap") &&
        typeof segment.content === "string",
    )
  );
}

/** Advertise the request, so kakehashi uses this server as a prepare peer. */
export function initializeKakehashiVirtualDocumentPrepare(
  preparedResult: DeepReadonly<InitializeResult>,
): DeepReadonly<InitializeResult> {
  const experimental = (preparedResult.capabilities.experimental ?? {}) as Record<string, unknown>;
  const kakehashi = (experimental.kakehashi ?? {}) as Record<string, unknown>;
  return {
    ...preparedResult,
    capabilities: {
      ...preparedResult.capabilities,
      experimental: {
        ...experimental,
        kakehashi: { ...kakehashi, virtualDocumentPrepare: true },
      },
    },
  };
}

// An answer kakehashi cannot use (or an error) means the document is not
// bridged at all; `null` keeps it as it is, so malformed params answer that.
export const handleKakehashiVirtualDocumentPrepare: CustomRequestHandler = (_context, params) =>
  Promise.resolve({ result: isPrepareParams(params) ? prepareVirtualDocument(params) : null });

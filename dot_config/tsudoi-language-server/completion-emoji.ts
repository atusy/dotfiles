import { gemoji } from "gemoji";
import type {
  CompletionList,
  CompletionParams,
} from "@atusy/tsudoi-language-server/deps/protocol";
import type { CompletionItem } from "@atusy/tsudoi-language-server/deps/types";
import type { RequestContext } from "@atusy/tsudoi-language-server/types";

/**
 * A colon opens a shortcode only where a word does not already end.
 *
 * WHAT THE LOOKBEHIND BUYS: `fix:tada` and `http://` keep their colons to
 * themselves, so a conventional commit prefix and a URL never turn the popup
 * into an emoji list. A bare `:` is refused too -- 1913 names are a dump, not a
 * suggestion -- which leaves the first typed character as the trigger.
 */
const shortcodePattern = /(?<![\p{L}\p{N}_:]):([a-zA-Z0-9_+-]+)$/u;

/** A colon that the next name character turns into a shortcode query. */
const openingColonPattern = /(?<![\p{L}\p{N}_:]):$/u;

/** One completable spelling: gemoji lists `+1` and `thumbsup` as separate names for 👍. */
type Shortcode = {
  readonly name: string;
  readonly emoji: string;
  readonly description: string;
  readonly tags: readonly string[];
};

// Flattened once per process: the table is static, and every request scans it.
const shortcodes: readonly Shortcode[] = gemoji.flatMap((entry) =>
  entry.names.map((name) => ({
    name,
    emoji: entry.emoji,
    description: entry.description,
    tags: entry.tags,
  })),
);

/** Where the shortcode being typed starts, and what has been typed of it. */
export function shortcodeQuery(
  line: string,
  character: number,
): { query: string; start: number } | undefined {
  const match = shortcodePattern.exec(line.slice(0, character));
  if (match === null) {
    return undefined;
  }
  return { query: match[1], start: character - match[0].length };
}

/**
 * Names first, then what the name does not say.
 *
 * A name prefix is what the user typed if they know the shortcode; tags and the
 * Unicode description are what answers them when they do not -- `:party` finds
 * 🎉 because gemoji tags it "party", which is exactly the knowledge a
 * hand-written list would have had to invent.
 */
export function matchShortcodes(query: string, maxItems: number): Shortcode[] {
  const needle = query.toLowerCase();
  const named: Shortcode[] = [];
  const described: Shortcode[] = [];
  for (const shortcode of shortcodes) {
    if (shortcode.name.startsWith(needle)) {
      named.push(shortcode);
    } else if (
      shortcode.name.includes(needle) ||
      shortcode.tags.some((tag) => tag.startsWith(needle)) ||
      shortcode.description.split(/\s+/u).some((word) => word.startsWith(needle))
    ) {
      described.push(shortcode);
    }
  }
  return [...named, ...described].slice(0, maxItems);
}

/**
 * Keep the shortcode and emoji visible even when the menu omits detail.
 * Match on the shortcode and insert the emoji through textEdit so clients
 * do not filter the candidate using the emoji instead of the typed name.
 */
function itemFor(shortcode: Shortcode, params: CompletionParams, start: number): CompletionItem {
  return {
    label: `:${shortcode.name}:${shortcode.emoji}`,
    filterText: `:${shortcode.name}:`,
    detail: shortcode.description,
    kind: 1,
    textEdit: {
      range: {
        start: { line: params.position.line, character: start },
        end: params.position,
      },
      newText: shortcode.emoji,
    },
  };
}

export async function* completeEmoji(
  context: RequestContext,
  params: CompletionParams,
  options: { maxItems?: number } = {},
): AsyncGenerator<CompletionItem[], CompletionList, void> {
  // Without the document, nothing rules out a shortcode being typed.
  const unknown = { isIncomplete: true, items: [] };
  const document = context.tsudoi.documents.get(params.textDocument.uri);
  if (document === undefined) {
    return unknown;
  }
  const line = document.getText().split(/\r?\n/)[params.position.line];
  if (line === undefined) {
    return unknown;
  }
  const found = shortcodeQuery(line, params.position.character);
  if (found === undefined) {
    // Only a newly typed colon can open a query, and `:` is a completion
    // trigger character, so the client asks again when one arrives. A colon
    // already opening one waits for its first name character instead.
    const beforeCursor = line.slice(0, params.position.character);
    return { isIncomplete: openingColonPattern.test(beforeCursor), items: [] };
  }
  const maxItems = options.maxItems ?? 200;
  // One match past the bound tells truncation apart from an exact fit.
  const matches = matchShortcodes(found.query, maxItems + 1);
  const items = matches.slice(0, maxItems).map((shortcode) =>
    itemFor(shortcode, params, found.start),
  );
  if (items.length > 0) {
    yield items;
  }
  // COMPLETENESS RULING: every matcher only narrows as the query grows, so an
  // untruncated answer already holds every answer to what is typed next.
  return { isIncomplete: matches.length > maxItems, items: [] };
}

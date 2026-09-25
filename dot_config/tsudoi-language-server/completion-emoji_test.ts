import { assertEquals } from "@std/assert";
import { pathToFileURL } from "node:url";
import type { CompletionList } from "@atusy/tsudoi-language-server/deps/protocol";
import type { CompletionItem } from "@atusy/tsudoi-language-server/deps/types";
import { completeEmoji, shortcodeQuery } from "./completion-emoji.ts";

const uri = pathToFileURL("/tmp/note.md").href;

async function completion(
  text: string,
  options?: { maxItems?: number },
): Promise<{ items: CompletionItem[]; result: CompletionList | void }> {
  const document = {
    uri,
    languageId: "markdown",
    version: 1,
    lineCount: 1,
    getText: () => text,
    positionAt: () => ({ line: 0, character: 0 }),
    offsetAt: () => 0,
  };
  const items: CompletionItem[] = [];
  const iterator = completeEmoji(
    {
      signal: new AbortController().signal,
      tsudoi: {
        documents: {
          get: (documentUri: string) => (documentUri === uri ? document : undefined),
          values: () => [document],
        },
        workspaceFolders: { get: () => [], values: () => [] },
        rootUri: null,
        rootPath: null,
        clientCapabilities: {},
        notify: () => Promise.resolve(),
      },
    } as never,
    {
      textDocument: { uri },
      position: { line: 0, character: text.length },
    },
    options,
  );
  while (true) {
    const next = await iterator.next();
    if (next.done) return { items, result: next.value };
    items.push(...next.value);
  }
}

async function completionItems(text: string): Promise<CompletionItem[]> {
  return (await completion(text)).items;
}

Deno.test("a shortcode query starts at a colon that opens a word", () => {
  assertEquals(shortcodeQuery(":tada", 5), { query: "tada", start: 0 });
  assertEquals(shortcodeQuery("Yay :tada", 9), { query: "tada", start: 4 });
  assertEquals(shortcodeQuery(":+1", 3), { query: "+1", start: 0 });
});

Deno.test("a colon that continues a word or stands alone is not a query", () => {
  assertEquals(shortcodeQuery("fix:tada", 8), undefined); // conventional commit prefix
  assertEquals(shortcodeQuery("http://x", 8), undefined);
  assertEquals(shortcodeQuery(":", 1), undefined); // the whole set is not a suggestion
  assertEquals(shortcodeQuery(":tada: done", 11), undefined);
});

Deno.test("a query is read at the cursor, not at the end of the line", () => {
  assertEquals(shortcodeQuery(":tada and more", 5), {
    query: "tada",
    start: 0,
  });
});

Deno.test("completing a name replaces the typed shortcode with the emoji", async () => {
  const items = await completionItems("Yay :tada");
  const tada = items.find((item) => item.label === ":tada:🎉"); // the popup shows what it inserts

  assertEquals(tada?.filterText, ":tada:");
  assertEquals(tada?.textEdit, {
    range: { start: { line: 0, character: 4 }, end: { line: 0, character: 9 } },
    newText: "🎉",
  });
});

Deno.test("an alias is completable under its own spelling", async () => {
  const items = await completionItems(":+1");
  const thumbsup = items.find((item) => item.label === ":+1:👍");

  assertEquals(thumbsup?.textEdit, {
    range: { start: { line: 0, character: 0 }, end: { line: 0, character: 3 } },
    newText: "👍",
  });
});

Deno.test("names matching the query come before tags matching it", async () => {
  const labels = (await completionItems(":party")).map((item) => item.label);

  assertEquals(labels[0], ":partying_face:🥳");
  assertEquals(labels.includes(":tada:🎉"), true); // tagged "party"
});

Deno.test("a query nothing answers completes nothing", async () => {
  assertEquals(await completionItems(":zzzzzzz"), []);
});

Deno.test("completion is skipped outside a shortcode", async () => {
  assertEquals(await completionItems("no colon here"), []);
});

Deno.test("a query answered in full is complete, so narrowing it stays client-side", async () => {
  assertEquals((await completion(":tad")).result, { isIncomplete: false, items: [] });
  assertEquals((await completion(":zzzzzzz")).result, { isIncomplete: false, items: [] });
});

Deno.test("a truncated answer is incomplete, so narrowing it asks again", async () => {
  assertEquals((await completion(":a")).result, { isIncomplete: true, items: [] });
  // `:tad` has exactly two answers: the bound distinguishes truncation from an exact fit
  assertEquals((await completion(":tad", { maxItems: 1 })).result, {
    isIncomplete: true,
    items: [],
  });
  assertEquals((await completion(":tad", { maxItems: 2 })).result, {
    isIncomplete: false,
    items: [],
  });
});

Deno.test("a colon that may still open a shortcode is incomplete", async () => {
  assertEquals((await completion(":")).result, { isIncomplete: true, items: [] });
  assertEquals((await completion("Yay :")).result, { isIncomplete: true, items: [] });
});

Deno.test("text only a new colon can turn into a query is complete", async () => {
  // Typing that colon is what asks again: `:` is a completion trigger character.
  for (const text of ["", "no colon here", "fix:", "http:", ":tada: done"]) {
    assertEquals((await completion(text)).result, { isIncomplete: false, items: [] }, text);
  }
});

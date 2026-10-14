import { assertEquals } from "@std/assert";
import {
  type PrepareParams,
  prepareVirtualDocument,
  type Segment,
} from "./kakehashi-virtual-document-prepare.ts";

function params(
  languageId: string,
  segments: Segment[],
  hostLanguageId = "nix",
): PrepareParams {
  return {
    textDocument: { uri: "file:///tmp/virtual", languageId, version: 1 },
    hostTextDocument: { uri: "file:///tmp/host.nix", languageId: hostLanguageId },
    segments,
  };
}

function deleteIndent(line: number, character: number) {
  return {
    range: { start: { line, character: 0 }, end: { line, character } },
    newText: "",
  };
}

Deno.test("an indented Nix string is dedented by its common indentation", () => {
  // # bash
  // ''
  //   if test -n "$HOME"; then
  //     echo "$HOME"
  //   fi
  // ''
  const content = '\n  if test -n "$HOME"; then\n    echo "$HOME"\n  fi\n';
  assertEquals(prepareVirtualDocument(params("bash", [{ type: "content", content }])), {
    segments: [
      {
        type: "content",
        changes: [deleteIndent(1, 2), deleteIndent(2, 2), deleteIndent(3, 2)],
      },
    ],
  });
});

Deno.test("blank lines neither constrain nor lose indentation", () => {
  // Removing less from a whitespace-only line than from the others would
  // leave kakehashi no uniform indentation to give lines a formatter
  // creates, and it would refuse the formatting.
  const content = "\n    a\n\n      b\n  \n";
  assertEquals(prepareVirtualDocument(params("bash", [{ type: "content", content }])), {
    segments: [
      {
        type: "content",
        changes: [deleteIndent(1, 4), deleteIndent(3, 4)],
      },
    ],
  });
});

Deno.test("the indentation before the closing quotes is left alone", () => {
  // # bash
  // ''
  //   echo
  // '' (indented less than the script)
  const content = "\n        echo\n      ";
  assertEquals(prepareVirtualDocument(params("bash", [{ type: "content", content }])), {
    segments: [{ type: "content", changes: [deleteIndent(1, 8)] }],
  });
});

Deno.test("an interpolation in JSON becomes a number placeholder", () => {
  // # json
  // ''
  //   {
  //     "port": ${toString cfg.port}
  //   }
  // ''
  const segments: Segment[] = [
    { type: "content", content: '\n  {\n    "port": ' },
    { type: "gap", content: "${toString cfg.port}" },
    { type: "content", content: "\n  }\n" },
  ];
  assertEquals(prepareVirtualDocument(params("json", segments)), {
    segments: [
      { type: "content", changes: [deleteIndent(1, 2), deleteIndent(2, 2)] },
      { type: "gap", content: "0" },
      { type: "content", changes: [deleteIndent(1, 2)] },
    ],
  });
});

Deno.test("an interpolation in Python becomes None", () => {
  const segments: Segment[] = [
    { type: "content", content: "\n  result = " },
    { type: "gap", content: "${someNixExpression}" },
    { type: "content", content: "\n  print(result)\n" },
  ];
  assertEquals(prepareVirtualDocument(params("python", segments)), {
    segments: [
      { type: "content", changes: [deleteIndent(1, 2)] },
      { type: "gap", content: "None" },
      { type: "content", changes: [deleteIndent(1, 2)] },
    ],
  });
});

Deno.test("a line starting with an interpolation counts as indented content", () => {
  // Its indentation is the whole last line of the segment before the gap,
  // which must not read as a blank line.
  const segments: Segment[] = [
    { type: "content", content: "\n    a\n  " },
    { type: "gap", content: "${b}" },
    { type: "content", content: "\n" },
  ];
  assertEquals(prepareVirtualDocument(params("bash", segments)), {
    segments: [
      { type: "content", changes: [deleteIndent(1, 2), deleteIndent(2, 2)] },
      { type: "gap", content: "__nix__" },
      { type: "content" },
    ],
  });
});

Deno.test("strings commented with the same language join into one document", () => {
  // a =
  //   # json
  //   ''
  //     {
  //       "name": "${cfg.name}",
  //   '';
  // b =
  //   # json
  //   ''
  //       "port": ${toString cfg.port}
  //     }'';
  // kakehashi combines both strings; the Nix between them is a gap that
  // disappears, while each interpolation becomes a placeholder.
  const segments: Segment[] = [
    { type: "content", content: '\n      {\n        "name": "' },
    { type: "gap", content: "${cfg.name}" },
    { type: "content", content: '",\n    ' },
    { type: "gap", content: "'';\n  b =\n    # json\n    ''" },
    { type: "content", content: '\n        "port": ' },
    { type: "gap", content: "${toString cfg.port}" },
    { type: "content", content: "\n      }" },
  ];
  assertEquals(prepareVirtualDocument(params("json", segments)), {
    segments: [
      { type: "content", changes: [deleteIndent(1, 6), deleteIndent(2, 6)] },
      { type: "gap", content: "0" },
      // The indentation before the closing quotes is blank: it does not
      // lower the common indentation, and keeps its own.
      { type: "content" },
      { type: "gap", content: "" },
      { type: "content", changes: [deleteIndent(1, 6)] },
      { type: "gap", content: "0" },
      { type: "content", changes: [deleteIndent(1, 6)] },
    ],
  });
});

Deno.test("each joined string loses its own common indentation", () => {
  // a =
  //   # json
  //   ''
  //     {
  //       "name": "x",
  //   '';
  // nested.b =
  //       # json
  //       ''
  //           "port": 1
  //         }'';
  // Nix dedents each string on its own, so the deeper string loses more.
  const segments: Segment[] = [
    { type: "content", content: '\n      {\n        "name": "x",\n    ' },
    { type: "gap", content: "'';\n  nested.b =\n        # json\n        ''" },
    { type: "content", content: '\n            "port": 1\n          }' },
  ];
  assertEquals(prepareVirtualDocument(params("json", segments)), {
    segments: [
      { type: "content", changes: [deleteIndent(1, 6), deleteIndent(2, 6)] },
      { type: "gap", content: "" },
      { type: "content", changes: [deleteIndent(1, 10), deleteIndent(2, 10)] },
    ],
  });
});

Deno.test("strings join even in a language without a placeholder", () => {
  const segments: Segment[] = [
    { type: "content", content: "a " },
    { type: "gap", content: "${b}" },
    { type: "content", content: " c" },
    { type: "gap", content: "'';\n  d = ''" },
    { type: "content", content: "e" },
  ];
  assertEquals(prepareVirtualDocument(params("regex", segments)), {
    segments: [
      { type: "content" },
      { type: "gap" },
      { type: "content" },
      { type: "gap", content: "" },
      { type: "content" },
    ],
  });
});

Deno.test("a language without a placeholder keeps its gaps masked", () => {
  const segments: Segment[] = [
    { type: "content", content: "a " },
    { type: "gap", content: "${b}" },
    { type: "content", content: " c" },
  ];
  assertEquals(prepareVirtualDocument(params("regex", segments)), null);
});

Deno.test("documents in other hosts are left as they are", () => {
  const content = "\n  a\n";
  assertEquals(
    prepareVirtualDocument(params("bash", [{ type: "content", content }], "markdown")),
    null,
  );
});

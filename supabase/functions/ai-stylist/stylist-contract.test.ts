// F26 -- pure unit tests for stylist-contract.ts (A19-A27 plus the parse rules
// that the handler tests in index.test.ts also exercise end to end).
import { assertEquals } from "jsr:@std/assert@1";
import {
  buildPrompt,
  parseStylistRequest,
  type StylistRequest,
  validateOutfits,
} from "./stylist-contract.ts";
import { validRequestBody } from "../_shared/test-support.ts";

function item(id: string, extra: Record<string, string> = {}) {
  return {
    id,
    name: `name-${id}`,
    category: "Shirts",
    color: "Blue",
    occasion: "Office",
    season: "All season",
    ...extra,
  };
}

function request(overrides: Partial<StylistRequest> = {}): StylistRequest {
  const ids = overrides.items?.map((i) => i.id) ?? ["a", "b", "c", "d", "e", "f", "g", "h"];
  return {
    occasion: "Office",
    styleDirection: "Smart casual",
    weather: "Mild",
    includeAccessories: true,
    mode: "auto",
    lockedIds: [],
    selectedIds: [],
    items: ids.map((id) => item(id)),
    ...overrides,
  };
}

function outfits(...sets: string[][]): string {
  return JSON.stringify({
    outfits: sets.map((itemIds, i) => ({ name: `Look ${i}`, why: `Because ${i}.`, itemIds })),
  });
}

Deno.test("F26_A19 validateOutfits drops unknown ids per id (case-sensitive, non-strings removed)", () => {
  const req = request({ items: ["a", "b", "c"].map((id) => item(id)) });
  const raw = JSON.stringify({
    outfits: [{ name: "N", why: "W", itemIds: ["a", "ghost", "b", "A", 1, null, {}] }],
  });
  assertEquals(validateOutfits(raw, req)[0].itemIds, ["a", "b"]);
});

Deno.test("F26_A20 validateOutfits dedupes within an outfit keeping first-occurrence order", () => {
  assertEquals(validateOutfits(outfits(["a", "b", "a", "c", "b"]), request())[0].itemIds, [
    "a",
    "b",
    "c",
  ]);
});

Deno.test("F26_A21 validateOutfits enforces 2..6 ids after filtering (7 is dropped, not truncated)", () => {
  const req = request();
  assertEquals(validateOutfits(outfits(["a"]), req), []);
  assertEquals(validateOutfits(outfits(["a", "b"]), req).length, 1);
  assertEquals(validateOutfits(outfits(["a", "b", "c", "d", "e", "f"]), req).length, 1);
  assertEquals(validateOutfits(outfits(["a", "b", "c", "d", "e", "f", "g"]), req), []);
  // Unknown ids are removed first: 1 valid + ghosts is still too few.
  assertEquals(validateOutfits(outfits(["a", "ghost-1", "ghost-2"]), req), []);
});

Deno.test("F26_A22 match mode: locked ids are required; includeAccessories false allows only selected ids", () => {
  const items = ["a", "b", "c"].map((id) => item(id));
  const match = (locked: string[], accessories: boolean) =>
    request({
      items,
      mode: "match",
      lockedIds: locked,
      selectedIds: ["a", "b"],
      includeAccessories: accessories,
    });

  // includeAccessories true, locked [a]
  let req = match(["a"], true);
  assertEquals(validateOutfits(outfits(["b", "c"]), req), []);
  assertEquals(validateOutfits(outfits(["a", "c"]), req).length, 1);
  // locked [a, b]
  req = match(["a", "b"], true);
  assertEquals(validateOutfits(outfits(["a", "c"]), req), []);
  assertEquals(validateOutfits(outfits(["a", "b", "c"]), req).length, 1);
  // includeAccessories false, locked [a]: only selected ids
  req = match(["a"], false);
  assertEquals(validateOutfits(outfits(["a", "b"]), req).length, 1);
  assertEquals(validateOutfits(outfits(["a", "c"]), req), []);
  // the same outfits in auto mode are all kept
  const auto = request({ items });
  assertEquals(validateOutfits(outfits(["b", "c"], ["a", "c"], ["a", "b"]), auto).length, 3);
});

Deno.test("F26_A23 validateOutfits normalises whitespace and truncates on code points", () => {
  const req = request();
  const one = (name: unknown, why: unknown) =>
    validateOutfits(JSON.stringify({ outfits: [{ name, why, itemIds: ["a", "b"] }] }), req);

  assertEquals(one("  City\n\tDay  ", "ok")[0].name, "City Day");
  assertEquals(one("x".repeat(45), "ok")[0].name, "x".repeat(40));
  assertEquals(one("n", "y".repeat(200))[0].why, "y".repeat(160));
  assertEquals(one("👗".repeat(41), "ok")[0].name, "👗".repeat(40));
  // truncation then trimEnd: a space at the cut is removed
  assertEquals(one("a".repeat(39) + " bcd", "ok")[0].name, "a".repeat(39));
  for (const bad of [undefined, 5, "", "   "]) {
    assertEquals(one(bad, "ok"), []);
    assertEquals(one("ok", bad), []);
  }
});

Deno.test("F26_A24 validateOutfits keeps at most 3 outfits in model order", () => {
  const result = validateOutfits(
    outfits(["a", "b"], ["c", "d"], ["e", "f"], ["g", "h"], ["a", "c"]),
    request(),
  );
  assertEquals(result.map((o) => o.itemIds), [["a", "b"], ["c", "d"], ["e", "f"]]);
});

Deno.test("F26_A25 validateOutfits drops a repeated item set without counting it toward 3", () => {
  const result = validateOutfits(
    outfits(["a", "b"], ["b", "a"], ["c", "d"], ["e", "f"]),
    request(),
  );
  assertEquals(result.map((o) => o.itemIds), [["a", "b"], ["c", "d"], ["e", "f"]]);
});

Deno.test("F26_A26 validateOutfits drops malformed elements and strips extra keys", () => {
  const raw = JSON.stringify({
    outfits: [
      "not an object",
      { name: "A", why: "B", itemIds: "a,b" },
      { name: "Good", why: "Fine.", itemIds: ["a", "b"], score: 98, extra: "x" },
    ],
  });
  const result = validateOutfits(raw, request());
  assertEquals(result.length, 1);
  assertEquals(Object.keys(result[0]).sort(), ["itemIds", "name", "why"]);
  assertEquals(result[0], { name: "Good", why: "Fine.", itemIds: ["a", "b"] });
});

Deno.test("F26_A15 (contract module) validateOutfits returns [] for unparseable or wrongly shaped output", () => {
  const req = request();
  for (const raw of ["", "not json", "[]", "{}", '{"outfits":"x"}', '{"outfits":[]}']) {
    assertEquals(validateOutfits(raw, req), [], raw);
  }
  // deno-lint-ignore no-explicit-any
  assertEquals(validateOutfits(42 as any, req), []);
});

Deno.test("F26_A27 buildPrompt contains the binding sentences and nothing conditional by accident", () => {
  const items = ["white-shirt", "black-watch", "navy-chinos"].map((id) => item(id));
  const base = (over: Partial<StylistRequest>) =>
    request({ items, occasion: "Dinner", styleDirection: "Edgy", weather: "Cold", ...over });

  const always = [
    "Use only item ids from the ITEMS list. Never invent an item.",
    "Return between 1 and 3 outfits, each with 2 to 6 item ids.",
  ];
  const lockedSentence =
    "Every outfit must include all of these locked item ids: white-shirt, black-watch.";
  const preferSentence =
    "Prefer these selected item ids: white-shirt, black-watch, navy-chinos. You may complete outfits with other items from the ITEMS list.";
  const onlySentence =
    "Use only these selected item ids: white-shirt, black-watch, navy-chinos. Do not add any other item.";
  const noAccessories = "Do not add items whose category is Accessories.";

  const matchTrue = buildPrompt(base({
    mode: "match",
    lockedIds: ["white-shirt", "black-watch"],
    selectedIds: ["white-shirt", "black-watch", "navy-chinos"],
    includeAccessories: true,
  }));
  for (const s of [...always, lockedSentence, preferSentence]) assertEquals(matchTrue.includes(s), true, s);
  assertEquals(matchTrue.includes(onlySentence), false);

  const matchFalse = buildPrompt(base({
    mode: "match",
    lockedIds: ["white-shirt", "black-watch"],
    selectedIds: ["white-shirt", "black-watch", "navy-chinos"],
    includeAccessories: false,
  }));
  assertEquals(matchFalse.includes(onlySentence), true);
  assertEquals(matchFalse.includes(preferSentence), false);

  const noLocked = buildPrompt(base({
    mode: "match",
    lockedIds: [],
    selectedIds: ["white-shirt", "black-watch", "navy-chinos"],
  }));
  assertEquals(noLocked.includes("locked item ids"), false);

  const autoTrue = buildPrompt(base({ includeAccessories: true }));
  const autoFalse = buildPrompt(base({ includeAccessories: false }));
  for (const p of [autoTrue, autoFalse]) {
    for (const s of always) assertEquals(p.includes(s), true, s);
    assertEquals(p.includes("locked item ids"), false);
    assertEquals(p.includes("selected item ids"), false);
  }
  assertEquals(autoTrue.includes(noAccessories), false);
  assertEquals(autoFalse.includes(noAccessories), true);

  // occasion, direction, weather and every item field value are present.
  for (const v of ["Dinner", "Edgy", "Cold"]) assertEquals(autoTrue.includes(v), true, v);
  for (const it of items) {
    for (const value of Object.values(it)) assertEquals(autoTrue.includes(value), true, value);
  }
});

Deno.test("F26_A09 (contract module) parseStylistRequest rebuilds the request from known keys only", () => {
  const body = validRequestBody({ uid: "u", email: "e", extra: 1 });
  (body.items as Record<string, unknown>[])[0].imageUrl = "http://x";
  const parsed = parseStylistRequest(body);
  if (!parsed.ok) throw new Error("expected ok");
  assertEquals(Object.keys(parsed.request).sort(), [
    "includeAccessories",
    "items",
    "lockedIds",
    "mode",
    "occasion",
    "selectedIds",
    "styleDirection",
    "weather",
  ]);
  assertEquals(Object.keys(parsed.request.items[0]).sort(), [
    "category",
    "color",
    "id",
    "name",
    "occasion",
    "season",
  ]);
  // styling strings are trimmed, items keep their ids exactly
  const padded = parseStylistRequest(validRequestBody({ occasion: "  Office  " }));
  if (!padded.ok) throw new Error("expected ok");
  assertEquals(padded.request.occasion, "Office");
});
